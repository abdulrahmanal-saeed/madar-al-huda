package com.abdulrahmanalsaeed.madaralhuda

import android.Manifest
import android.app.Activity
import java.io.ByteArrayOutputStream
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.GeomagneticField
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.Surface
import java.io.File
import androidx.core.content.FileProvider
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val compass by lazy { CompassStream() }
    private var notificationRequest: MethodChannel.Result? = null
    private var feedbackImageRequest: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, "madar/updates").setMethodCallHandler { call, result ->
            when (call.method) {
                "installed" -> result.success(mapOf(
                    "channel" to UpdateNotifications.channel(this),
                    "code" to UpdateNotifications.version(this),
                    "notifications" to UpdateNotifications.enabled(this),
                ))
                "notifications" -> {
                    val enabled = call.arguments == true
                    if (enabled && Build.VERSION.SDK_INT >= 33 &&
                        checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                        if (notificationRequest != null) {
                            result.success(false)
                        } else {
                            notificationRequest = result
                            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 4411)
                        }
                    } else {
                        result.success(UpdateNotifications.setEnabled(this, enabled))
                    }
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(messenger, "madar/feedback-image").setMethodCallHandler { call, result ->
            if (call.method != "pick") {
                result.notImplemented()
            } else if (feedbackImageRequest != null) {
                result.error("busy", "Image selection already open", null)
            } else {
                feedbackImageRequest = result
                try {
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        type = "image/*"
                        addCategory(Intent.CATEGORY_OPENABLE)
                        putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("image/png", "image/jpeg"))
                    }
                    startActivityForResult(intent, 4412)
                } catch (error: Exception) {
                    feedbackImageRequest = null
                    result.error("picker", "Cannot open image picker", null)
                }
            }
        }
        EventChannel(messenger, "madar/compass").setStreamHandler(compass)
        MethodChannel(messenger, "madar/share").setMethodCallHandler { call, result ->
            when (call.method) {
                "shareText" -> {
                    val text = call.arguments as? String
                    if (text.isNullOrBlank()) {
                        result.error("empty_text", "No text to share", null)
                    } else {
                        val send = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TEXT, text)
                        }
                        startActivity(Intent.createChooser(send, null))
                        result.success(null)
                    }
                }
                "shareImage" -> {
                    // Only PNGs the app wrote to cache/shared/ can be shared.
                    val shared = File(cacheDir, "shared").canonicalFile
                    val file = call.argument<String>("path")?.let { File(it).canonicalFile }
                    if (file == null || file.parentFile != shared ||
                        !file.isFile || !file.name.endsWith(".png")) {
                        result.error("image", "Invalid image", null)
                    } else {
                        val uri = FileProvider.getUriForFile(this, "$packageName.share", file)
                        val send = Intent(Intent.ACTION_SEND).apply {
                            type = "image/png"
                            putExtra(Intent.EXTRA_STREAM, uri)
                            call.argument<String>("text")?.let { putExtra(Intent.EXTRA_TEXT, it) }
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        startActivity(Intent.createChooser(send, null))
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(messenger, "madar/geomagnetic").setMethodCallHandler { call, result ->
            if (call.method != "declination") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val latitude = call.argument<Double>("latitude")
            val longitude = call.argument<Double>("longitude")
            if (latitude == null || latitude !in -90.0..90.0 ||
                longitude == null || longitude !in -180.0..180.0) {
                result.error("coordinates", "Invalid coordinates", null)
                return@setMethodCallHandler
            }
            val field = GeomagneticField(
                latitude.toFloat(), longitude.toFloat(), 0f, System.currentTimeMillis()
            )
            result.success(field.declination.toDouble())
        }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 4412) return
        val result = feedbackImageRequest ?: return
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            feedbackImageRequest = null
            result.success(null)
            return
        }
        Thread {
            val bytes = try {
                val max = 2 * 1024 * 1024
                contentResolver.openInputStream(uri)?.use { input ->
                    val output = ByteArrayOutputStream()
                    val buffer = ByteArray(8192)
                    while (true) {
                        val size = input.read(buffer)
                        if (size == -1) break
                        if (output.size() + size > max) throw IllegalArgumentException("Image too large")
                        output.write(buffer, 0, size)
                    }
                    output.toByteArray().also {
                        val png = it.size >= 8 && it.take(8).map { b -> b.toInt() and 255 } ==
                            listOf(137, 80, 78, 71, 13, 10, 26, 10)
                        val jpeg = it.size >= 3 && (it[0].toInt() and 255) == 255 &&
                            (it[1].toInt() and 255) == 216 && (it[2].toInt() and 255) == 255
                        if (!png && !jpeg) throw IllegalArgumentException("Invalid image")
                    }
                }
            } catch (error: Exception) {
                null
            }
            runOnUiThread {
                if (feedbackImageRequest === result) {
                    feedbackImageRequest = null
                    if (bytes == null) result.error("image", "Invalid or oversized image", null)
                    else result.success(bytes)
                }
            }
        }.start()
    }

    override fun onResume() {
        super.onResume()
        compass.resume()
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 4411) {
            val allowed = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
            notificationRequest?.success(UpdateNotifications.setEnabled(this, allowed))
            notificationRequest = null
        }
    }

    override fun onPause() {
        compass.pause()
        super.onPause()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        compass.onCancel(null)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        EventChannel(messenger, "madar/compass").setStreamHandler(null)
        MethodChannel(messenger, "madar/geomagnetic").setMethodCallHandler(null)
        MethodChannel(messenger, "madar/share").setMethodCallHandler(null)
        MethodChannel(messenger, "madar/updates").setMethodCallHandler(null)
        MethodChannel(messenger, "madar/feedback-image").setMethodCallHandler(null)
        feedbackImageRequest?.success(null)
        feedbackImageRequest = null
        notificationRequest?.success(false)
        notificationRequest = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    @Suppress("DEPRECATION")
    private fun screenRotation(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            display?.rotation ?: Surface.ROTATION_0
        } else {
            windowManager.defaultDisplay.rotation
        }

    private inner class CompassStream : EventChannel.StreamHandler, SensorEventListener {
        private val manager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        private val sources = listOf(
            listOf(Sensor.TYPE_ROTATION_VECTOR),
            listOf(Sensor.TYPE_GEOMAGNETIC_ROTATION_VECTOR),
            listOf(Sensor.TYPE_ACCELEROMETER, Sensor.TYPE_MAGNETIC_FIELD),
        )
        private val handler = Handler(Looper.getMainLooper())
        private val matrix = FloatArray(9)
        private val remapped = FloatArray(9)
        private val angles = FloatArray(3)
        private val gravity = FloatArray(3)
        private val magnetic = FloatArray(3)
        private var gravityTime = 0L
        private var magneticTime = 0L
        private var magneticAccuracy = SensorManager.SENSOR_STATUS_UNRELIABLE
        private var sink: EventChannel.EventSink? = null
        private var lastSample = 0L
        private var source = -1
        private var resumed = false

        // Some devices advertise a rotation vector but never deliver a sample.
        private val tryNextSource = Runnable { startAt(source + 1) }

        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
            stop()
            sink = events
            if (resumed) startAt(0)
        }

        override fun onCancel(arguments: Any?) {
            stop()
            sink = null
        }

        fun resume() {
            resumed = true
            if (sink != null) startAt(0)
        }

        fun pause() {
            resumed = false
            stop()
        }

        private fun startAt(index: Int) {
            stop()
            if (!resumed || sink == null) return
            for (candidate in index until sources.size) {
                val sensors = sources[candidate].map { manager.getDefaultSensor(it) }
                if (sensors.any { it == null }) continue
                if (sensors.filterNotNull().all {
                    manager.registerListener(this, it, SensorManager.SENSOR_DELAY_UI)
                }) {
                    source = candidate
                    handler.postDelayed(tryNextSource, 2500L)
                    return
                }
                manager.unregisterListener(this)
            }
            sink?.error("unsupported", "No North-referenced heading is available", null)
        }

        private fun stop() {
            handler.removeCallbacks(tryNextSource)
            manager.unregisterListener(this)
            source = -1
            lastSample = 0L
            gravityTime = 0L
            magneticTime = 0L
        }

        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

        override fun onSensorChanged(event: SensorEvent) {
            if (source < 0 || event.sensor.type !in sources[source]) return
            val values = event.values
            if (values.size < 3 || (0..2).any { !values[it].isFinite() }) return
            val reliable = when (event.sensor.type) {
                Sensor.TYPE_ACCELEROMETER, Sensor.TYPE_MAGNETIC_FIELD -> {
                    if (event.sensor.type == Sensor.TYPE_ACCELEROMETER) {
                        values.copyInto(gravity, endIndex = 3)
                        gravityTime = event.timestamp
                    } else {
                        values.copyInto(magnetic, endIndex = 3)
                        magneticTime = event.timestamp
                        magneticAccuracy = event.accuracy
                    }
                    if (gravityTime == 0L || magneticTime == 0L ||
                        kotlin.math.abs(gravityTime - magneticTime) > 350_000_000L ||
                        !SensorManager.getRotationMatrix(matrix, null, gravity, magnetic)
                    ) return
                    magneticAccuracy >= SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM
                }
                else -> {
                    SensorManager.getRotationMatrixFromVector(matrix, values)
                    val estimated = values.getOrNull(4)?.toDouble()
                    if (estimated != null && estimated.isFinite() && estimated >= 0) {
                        Math.toDegrees(estimated) <= 25
                    } else {
                        event.accuracy >= SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM
                    }
                }
            }
            if (lastSample != 0L && event.timestamp - lastSample < 80_000_000L) return
            val axes = when (screenRotation()) {
                Surface.ROTATION_90 -> SensorManager.AXIS_Y to SensorManager.AXIS_MINUS_X
                Surface.ROTATION_180 -> SensorManager.AXIS_MINUS_X to SensorManager.AXIS_MINUS_Y
                Surface.ROTATION_270 -> SensorManager.AXIS_MINUS_Y to SensorManager.AXIS_X
                else -> SensorManager.AXIS_X to SensorManager.AXIS_Y
            }
            if (!SensorManager.remapCoordinateSystem(matrix, axes.first, axes.second, remapped)) return
            SensorManager.getOrientation(remapped, angles)
            val azimuth = Math.toDegrees(angles[0].toDouble())
            if (!azimuth.isFinite()) return
            lastSample = event.timestamp
            handler.removeCallbacks(tryNextSource)
            sink?.success(mapOf("degrees" to (azimuth + 360) % 360, "reliable" to reliable))
        }
    }
}
