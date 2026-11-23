package com.abdulrahmanalsaeed.madaralhuda

import android.content.Context
import android.content.Intent
import android.hardware.GeomagneticField
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.view.Surface
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val compass by lazy { CompassStream() }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        EventChannel(messenger, "madar/compass").setStreamHandler(compass)
        MethodChannel(messenger, "madar/share").setMethodCallHandler { call, result ->
            val text = call.arguments as? String
            if (call.method != "shareText") {
                result.notImplemented()
            } else if (text.isNullOrBlank()) {
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

    override fun onResume() {
        super.onResume()
        compass.start()
    }

    override fun onPause() {
        compass.stop()
        super.onPause()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        compass.onCancel(null)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        EventChannel(messenger, "madar/compass").setStreamHandler(null)
        MethodChannel(messenger, "madar/geomagnetic").setMethodCallHandler(null)
        MethodChannel(messenger, "madar/share").setMethodCallHandler(null)
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
        private val sensor = manager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
        private val matrix = FloatArray(9)
        private val remapped = FloatArray(9)
        private val angles = FloatArray(3)
        private var sink: EventChannel.EventSink? = null
        private var lastSample = 0L
        private var registered = false

        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
            sink = events
            start()
        }

        override fun onCancel(arguments: Any?) {
            stop()
            sink = null
        }

        fun start() {
            if (sink == null || registered) return
            registered = sensor != null &&
                manager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_UI)
            if (!registered) {
                sink?.error("unsupported", "Compass sensor unavailable", null)
            }
        }

        fun stop() {
            manager.unregisterListener(this)
            registered = false
            lastSample = 0
        }

        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

        override fun onSensorChanged(event: SensorEvent) {
            if (lastSample != 0L && event.timestamp - lastSample < 80_000_000L) return
            lastSample = event.timestamp
            SensorManager.getRotationMatrixFromVector(matrix, event.values)
            val axes = when (screenRotation()) {
                Surface.ROTATION_90 -> SensorManager.AXIS_Y to SensorManager.AXIS_MINUS_X
                Surface.ROTATION_180 -> SensorManager.AXIS_MINUS_X to SensorManager.AXIS_MINUS_Y
                Surface.ROTATION_270 -> SensorManager.AXIS_MINUS_Y to SensorManager.AXIS_X
                else -> SensorManager.AXIS_X to SensorManager.AXIS_Y
            }
            if (!SensorManager.remapCoordinateSystem(matrix, axes.first, axes.second, remapped)) return
            SensorManager.getOrientation(remapped, angles)
            val degrees = (Math.toDegrees(angles[0].toDouble()) + 360) % 360
            val estimatedError = event.values.getOrNull(4)?.toDouble()?.let(Math::toDegrees)
            val reliable = event.accuracy >= SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM &&
                (estimatedError == null || estimatedError < 0 || estimatedError <= 25)
            sink?.success(mapOf("degrees" to degrees, "reliable" to reliable))
        }
    }
}
