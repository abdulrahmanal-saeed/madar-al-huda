package com.abdulrahmanalsaeed.madaralhuda

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.job.JobInfo
import android.app.job.JobParameters
import android.app.job.JobScheduler
import android.app.job.JobService
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import java.io.ByteArrayOutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors
import java.util.concurrent.Future
import java.util.concurrent.TimeUnit
import org.json.JSONObject

internal object UpdateNotifications {
    private const val JOB_ID = 4410
    private const val PREFERENCES = "madar_update_notifications"
    private const val ROOT = "https://quran.abdulrahmanalsaeed.com/admin/"

    fun channel(context: Context): String? = when {
        context.packageName.endsWith(".dev") -> "dev"
        context.packageName.endsWith(".preview") -> "preview"
        else -> null
    }

    @Suppress("DEPRECATION")
    fun version(context: Context): Long {
        val info = context.packageManager.getPackageInfo(context.packageName, 0)
        return if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()
    }

    fun settings(context: Context) = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

    fun enabled(context: Context): Boolean =
        settings(context).getBoolean("enabled", false) &&
            context.getSystemService(NotificationManager::class.java).areNotificationsEnabled()

    fun setEnabled(context: Context, requested: Boolean): Boolean {
        val scheduler = context.getSystemService(JobScheduler::class.java)
        val allowed = requested && channel(context) != null &&
            context.getSystemService(NotificationManager::class.java).areNotificationsEnabled()
        val scheduled = if (allowed) {
            val task = JobInfo.Builder(JOB_ID, ComponentName(context, UpdateCheckJob::class.java))
                .setRequiredNetworkType(JobInfo.NETWORK_TYPE_ANY)
                .setPeriodic(TimeUnit.MINUTES.toMillis(30))
                .setPersisted(true)
                .build()
            scheduler.schedule(task) == JobScheduler.RESULT_SUCCESS
        } else {
            scheduler.cancel(JOB_ID)
            false
        }
        settings(context).edit().putBoolean("enabled", scheduled).apply()
        return scheduled
    }

    fun publishedRelease(channel: String): JSONObject? {
        val connection = URL("$ROOT?feed=updates&channel=$channel").openConnection() as HttpURLConnection
        connection.connectTimeout = 7000
        connection.readTimeout = 7000
        connection.instanceFollowRedirects = false
        connection.setRequestProperty("Accept", "application/json")
        try {
            if (connection.responseCode == 404) return null
            check(connection.responseCode == 200 && connection.contentType?.startsWith("application/json") == true)
            return connection.inputStream.use { input ->
                val output = ByteArrayOutputStream()
                val chunk = ByteArray(4096)
                while (true) {
                    val count = input.read(chunk)
                    if (count == -1) break
                    check(output.size() + count <= 65536)
                    output.write(chunk, 0, count)
                }
                val document = JSONObject(output.toByteArray().toString(Charsets.UTF_8))
                check(document.optInt("version") == 1)
                document.optJSONObject("release")
            }
        } finally {
            connection.disconnect()
        }
    }

    @Suppress("DEPRECATION")
    fun show(context: Context, channel: String, code: Long, name: String) {
        val manager = context.getSystemService(NotificationManager::class.java)
        val topic = "madar_release_updates"
        val channelName = context.getString(R.string.update_notifications_channel)
        val builder = if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(NotificationChannel(topic, channelName, NotificationManager.IMPORTANCE_DEFAULT))
            Notification.Builder(context, topic)
        } else {
            Notification.Builder(context)
        }
        val page = Intent(Intent.ACTION_VIEW, Uri.parse("$ROOT?updates=$channel"))
        val open = PendingIntent.getActivity(
            context, JOB_ID, page, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val notice = builder.setSmallIcon(android.R.drawable.stat_sys_download_done)
            .setContentTitle(context.getString(R.string.update_notification_title))
            .setContentText(context.getString(R.string.update_notification_body, name))
            .setContentIntent(open)
            .setAutoCancel(true)
            .build()
        manager.notify(JOB_ID, notice)
        settings(context).edit().putLong("notified_code", code).apply()
    }
}

class UpdateCheckJob : JobService() {
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var task: Future<*>? = null
    private var run = 0

    override fun onStartJob(params: JobParameters): Boolean {
        val channel = UpdateNotifications.channel(this) ?: return false
        if (!UpdateNotifications.enabled(this)) return false
        val id = ++run
        task = worker.submit {
            val response = runCatching { UpdateNotifications.publishedRelease(channel) }
            main.post {
                if (id == run) {
                    val release = response.getOrNull()
                    if (release != null && UpdateNotifications.enabled(this)) {
                        val code = release.optLong("code")
                        val name = release.optString("name")
                        val last = UpdateNotifications.settings(this).getLong("notified_code", 0)
                        if (release.optBoolean("notify") && code in 1L..2100000000L &&
                            code > maxOf(last, UpdateNotifications.version(this)) && name.length in 1..80) {
                            // Permission can change between the final check and delivery.
                            runCatching { UpdateNotifications.show(this, channel, code, name) }
                        }
                    }
                    task = null
                    jobFinished(params, response.isFailure)
                }
            }
        }
        return true
    }

    override fun onStopJob(params: JobParameters): Boolean {
        run++
        task?.cancel(true)
        task = null
        return true
    }

    override fun onDestroy() {
        run++
        worker.shutdownNow()
        super.onDestroy()
    }
}
