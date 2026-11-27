package com.abdulrahmanalsaeed.madaralhuda

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.job.JobInfo
import android.app.job.JobParameters
import android.app.job.JobScheduler
import android.app.job.JobService
import android.content.ComponentName
import android.content.Context
import android.os.Build
import com.google.firebase.FirebaseApp
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URI
import java.util.concurrent.Executors
import java.util.concurrent.Future

internal object ContentNews {
    private const val JOB = 31_021
    private const val CHANNEL = "madar.content.news"
    private const val WEEK_SECONDS = 604_800L

    private fun store(context: Context) = context.getSharedPreferences("madar_content_news", Context.MODE_PRIVATE)
    private fun manager(context: Context) = context.getSystemService(NotificationManager::class.java)
    private fun jobs(context: Context) = context.getSystemService(JobScheduler::class.java)
    private fun now() = System.currentTimeMillis() / 1000
    private fun audience(context: Context) = if (
        context.packageName.endsWith(".dev") || context.packageName.endsWith(".preview") ||
        (context.applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0
    ) "dev" else "live"

    private fun openAvailable(context: Context) = store(context).getBoolean("enabled", false) &&
        manager(context).areNotificationsEnabled()

    fun configure(context: Context, enabled: Boolean, locale: String) {
        val prefs = store(context)
        val allowed = enabled && manager(context).areNotificationsEnabled()
        val wasEnabled = prefs.getBoolean("enabled", false)
        val update = prefs.edit().putBoolean("enabled", allowed).putBoolean("requested", enabled).putString("locale", locale)
        if (allowed && (!wasEnabled || !prefs.contains("since"))) {
            update.putLong("since", now())
        }
        update.apply()
        if (Build.VERSION.SDK_INT >= 26 && allowed) {
            manager(context).createNotificationChannel(NotificationChannel(CHANNEL,
                "Content news · أخبار المحتوى", NotificationManager.IMPORTANCE_DEFAULT))
        }

        if (allowed) schedule(context) else jobs(context).cancel(JOB)
        if (FirebaseApp.getApps(context).isEmpty()) return
        val messaging = FirebaseMessaging.getInstance()
        messaging.isAutoInitEnabled = allowed
        val topic = "madar-content-" + audience(context)
        if (allowed) {
            messaging.subscribeToTopic(topic).addOnSuccessListener {
                if (openAvailable(context)) jobs(context).cancel(JOB)
            }
        } else if (wasEnabled) {
            messaging.unsubscribeFromTopic(topic)
        }
    }

    fun refreshPermission(context: Context) {
        val prefs = store(context)
        configure(context, prefs.getBoolean("requested", true), prefs.getString("locale", "ar") ?: "ar")
    }

    private fun schedule(context: Context) {
        if (jobs(context).getPendingJob(JOB) != null) return
        jobs(context).schedule(JobInfo.Builder(JOB, ComponentName(context, ContentNewsJob::class.java))
            .setRequiredNetworkType(JobInfo.NETWORK_TYPE_ANY)
            .setPeriodic(30 * 60_000L)
            .setPersisted(true)
            .build())
    }

    private fun validRoute(route: String): Boolean {
        if (route.length > 210 || route.any { it <= ' ' || it == '\\' }) return false
        val uri = runCatching { URI(route) }.getOrNull() ?: return false
        return uri.scheme == null && uri.rawAuthority == null && uri.fragment == null &&
            (uri.path in setOf("/home", "/quran", "/worship/adhkar", "/worship/adhkar/listen",
                "/worship/prayer-times", "/worship/ramadan", "/library", "/library/hadith",
                "/library/articles", "/library/fiqh", "/learning/lessons", "/learning/prophet-stories",
                "/settings/reminders", "/settings/downloads") ||
                (uri.path.matches(Regex("/library/s/[a-z0-9][a-z0-9-]{0,63}")) &&
                    (uri.rawQuery == null || uri.rawQuery.matches(Regex("season=[a-z0-9][a-z0-9-]{0,63}(&episode=[1-9][0-9]{0,5})?")))))
    }

    @Synchronized
    fun show(context: Context, news: JSONObject) {
        if (!openAvailable(context) || news.optString("channel") != audience(context)) return
        val prefs = store(context)
        val id = news.optLong("id", -1)
        val title = news.optString("title")
        val text = news.optString("body")
        val route = news.optString("route")
        val created = news.optLong("created_at", 0)
        val time = now()
        if (id < 1 || title.isBlank() || title.length > 160 || text.isBlank() || text.length > 440 ||
            !validRoute(route) || created < maxOf(prefs.getLong("since", time), time - WEEK_SECONDS) ||
            created > time + 300) return
        val seen = prefs.getStringSet("seen", emptySet()).orEmpty()
        if (seen.any { it.substringBefore(':') == id.toString() }) return
        val ar = prefs.getString("locale", "ar") == "ar"
        val request = (id % Int.MAX_VALUE).toInt()
        val action = WorshipAlarms.open(context, route, request)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, CHANNEL)
            else Notification.Builder(context)
        manager(context).notify("madar-content-$id", 0,
            builder.setSmallIcon(R.drawable.madar_notification_mark)
                .setContentTitle(title).setContentText(text)
                .setStyle(Notification.BigTextStyle().bigText(text))
                .setContentIntent(action)
                .setAutoCancel(true)
                .addAction(Notification.Action.Builder(null, if (ar) "افتح" else "Open", action).build())
                .build())
        val recent = seen.filter { (it.substringAfter(':').toLongOrNull() ?: 0) >= time - WEEK_SECONDS }.toMutableSet()
        recent.add("$id:$created")
        prefs.edit().putStringSet("seen", recent).apply()
    }

    fun poll(context: Context) {
        if (!openAvailable(context)) return
        val url = URI("https://quran.abdulrahmanalsaeed.com/admin/?feed=content-news&channel=" +
            audience(context)).toURL()
        val connection = url.openConnection() as HttpURLConnection
        try {
            connection.instanceFollowRedirects = false
            connection.connectTimeout = 6000
            connection.readTimeout = 6000
            if (connection.responseCode != 200) return
            val body = connection.inputStream.bufferedReader().use { reader ->
                val buffer = CharArray(32768)
                val result = StringBuilder()
                do {
                    val count = reader.read(buffer)
                    if (count < 0) break
                    result.append(buffer, 0, count)
                    if (result.length > 65536) return
                } while (true)
                result.toString()
            }
            val items = JSONObject(body).optJSONArray("items") ?: return
            for (index in items.length() - 1 downTo 0) {
                items.optJSONObject(index)?.let { show(context, it) }
            }
        } finally {
            connection.disconnect()
        }
    }
}

class ContentNewsJob : JobService() {
    private val executor = Executors.newSingleThreadExecutor()
    private var job: Future<*>? = null

    override fun onStartJob(params: JobParameters): Boolean {
        job = executor.submit {
            try { ContentNews.poll(this) } catch (_: Exception) {
                // A constrained device can try again on the next scheduled run.
            } finally { jobFinished(params, false) }
        }
        return true
    }

    override fun onStopJob(params: JobParameters): Boolean {
        job?.cancel(true)
        return true
    }

    override fun onDestroy() {
        executor.shutdownNow()
        super.onDestroy()
    }
}

class MadarContentMessagingService : FirebaseMessagingService() {
    override fun onMessageReceived(message: RemoteMessage) {
        ContentNews.show(this, JSONObject(message.data))
    }
}
