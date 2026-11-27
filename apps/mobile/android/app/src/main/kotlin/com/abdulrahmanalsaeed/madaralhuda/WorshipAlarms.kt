package com.abdulrahmanalsaeed.madaralhuda

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

internal object WorshipAlarms {
    private const val STORE = "madar_worship_alarms"
    private const val RECEIVE = "madar.worship.alarm"
    private const val SHORT = "madar.worship.alarm.sound.v1"
    private const val PLAYING = "madar.worship.alarm.recording.v1"
    private const val UPCOMING = "madar.worship.prayer.status.v1"
    private const val STATUS_ID = 31_017
    private const val DELAY_LIMIT = 180_000L
    private val attributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_ALARM)
        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
        .build()

    private fun store(context: Context) = context.getSharedPreferences(STORE, Context.MODE_PRIVATE)
    private fun alarms(context: Context) = context.getSystemService(AlarmManager::class.java)
    private fun manager(context: Context) = context.getSystemService(NotificationManager::class.java)
    private fun alarmIntent(context: Context) = PendingIntent.getBroadcast(
        context, 0, Intent(context, WorshipAlarmReceiver::class.java).setAction(RECEIVE),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private fun array(raw: String?): List<JSONObject> {
        if (raw.isNullOrEmpty()) return emptyList()
        val values = JSONArray(raw)
        return (0 until values.length()).mapNotNull(values::optJSONObject)
    }

    fun replace(context: Context, items: List<Map<String, Any?>>) {
        store(context).edit().putString("events", JSONArray(items.map(::JSONObject)).toString()).apply()
        schedule(context)
    }

    fun replaceStatus(context: Context, data: Map<String, Any?>) {
        store(context).edit().putString("status", JSONObject(data).toString()).apply()
        updateStatus(context)
        schedule(context)
    }

    private fun events(context: Context) = array(store(context).getString("events", null))
    private fun status(context: Context) = JSONObject(store(context).getString("status", "{}")!!)

    private fun schedule(context: Context) {
        val alarm = alarms(context)
        val operation = alarmIntent(context)
        alarm.cancel(operation)
        val now = System.currentTimeMillis()
        val data = status(context)
        val statusBoundary = if (data.optBoolean("enabled")) {
            array(data.optJSONArray("prayers")?.toString())
                .map { it.optLong("at") }.filter { it > now }.minOrNull()
        } else null
        val next = (events(context).map { it.optLong("at") }.filter { it > now } +
            listOfNotNull(statusBoundary)).minOrNull() ?: return
        try {
            if (Build.VERSION.SDK_INT < 31 || alarm.canScheduleExactAlarms()) {
                alarm.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, operation)
            } else {
                alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, operation)
            }
        } catch (_: SecurityException) {
            alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, operation)
        }
    }

    private fun shortSound(context: Context) =
        Uri.parse("android.resource://${context.packageName}/${R.raw.worship_tone}")

    private fun channels(context: Context) {
        if (Build.VERSION.SDK_INT < 26) return
        manager(context).createNotificationChannels(listOf(
            NotificationChannel(SHORT, "Worship reminders · تذكيرات العبادة", NotificationManager.IMPORTANCE_HIGH).apply {
                setSound(shortSound(context), attributes)
            },
            NotificationChannel(PLAYING, "Worship audio · صوت التذكيرات", NotificationManager.IMPORTANCE_DEFAULT).apply {
                setSound(null, null)
            },
            NotificationChannel(UPCOMING, "Prayer countdown · عداد الصلاة", NotificationManager.IMPORTANCE_LOW).apply {
                setSound(null, null)
            },
        ))
    }

    private fun builder(context: Context, channel: String): Notification.Builder {
        channels(context)
        val b = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(context, channel)
        else Notification.Builder(context)
        return b.setSmallIcon(R.drawable.madar_notification_mark)
    }

    internal fun open(context: Context, route: String, request: Int): PendingIntent {
        val uri = Uri.parse("https://quran.abdulrahmanalsaeed.com/app" + route)
        return PendingIntent.getActivity(context, request,
            Intent(Intent.ACTION_VIEW, uri, context, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    private fun showShort(context: Context, reminder: JSONObject, audible: Boolean = true) {
        val id = reminder.optInt("id") + 110_000
        val text = reminder.optString("body")
        val b = builder(context, if (audible) SHORT else PLAYING)
            .setContentTitle(reminder.optString("title"))
            .setContentText(text)
            .setStyle(Notification.BigTextStyle().bigText(text))
            .setCategory(Notification.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setContentIntent(open(context, reminder.optString("route"), id))
        if (audible && Build.VERSION.SDK_INT < 26) {
            b.setSound(shortSound(context), attributes)
        }
        manager(context).notify(id, b.build())
    }

    private fun rawId(sound: String): Int = when (sound) {
        "adhan_alternate" -> R.raw.adhan_alternate
        "adhan_makkah" -> R.raw.adhan_makkah
        "adhan_fajr" -> R.raw.adhan_fajr
        else -> 0
    }

    private fun file(context: Context, sound: String): File? {
        if (!sound.matches(Regex("Library-[a-f0-9]{32}[.]mp3"))) return null
        return File(context.filesDir, "devotional/$sound").takeIf { it.isFile }
    }

    fun source(context: Context, player: MediaPlayer, sound: String) {
        val raw = rawId(sound)
        if (raw != 0) {
            context.resources.openRawResourceFd(raw).use {
                player.setDataSource(it.fileDescriptor, it.startOffset, it.length)
            }
        } else {
            player.setDataSource(requireNotNull(file(context, sound)).absolutePath)
        }
    }

    fun due(context: Context, onAlarm: Boolean) {
        val now = System.currentTimeMillis()
        if (onAlarm) {
            val list = events(context)
            val pending = list.filter { it.optLong("at") > now }
            store(context).edit().putString("events", JSONArray(pending).toString()).apply()
            if (manager(context).areNotificationsEnabled()) {
                val due = list.filter { it.optLong("at") in (now - DELAY_LIMIT)..now }
                    .sortedByDescending { it.optString("kind") == "adhan" }
                var audioStarted = false
                for (event in due) {
                    val sound = event.optString("sound")
                    val audioAllowed = !audioStarted && (rawId(sound) != 0 || file(context, sound) != null) &&
                        (Build.VERSION.SDK_INT < 31 || alarms(context).canScheduleExactAlarms())
                    if (audioAllowed) {
                        val intent = Intent(context, WorshipAudioService::class.java).putExtra("event", event.toString())
                        audioStarted = runCatching {
                            if (Build.VERSION.SDK_INT >= 26) context.startForegroundService(intent)
                            else context.startService(intent)
                        }.isSuccess
                        if (!audioStarted) showShort(context, event)
                    } else {
                        showShort(context, event, audible = !audioStarted)
                    }
                }
            }
        }
        updateStatus(context)
        schedule(context)
    }

    fun playbackNotice(context: Context, event: JSONObject): Notification {
        val stop = PendingIntent.getBroadcast(context, 1,
            Intent(context, WorshipAlarmReceiver::class.java).setAction("madar.worship.stop"),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val text = event.optString("body")
        return builder(context, PLAYING)
            .setContentTitle(event.optString("title"))
            .setContentText(text)
            .setStyle(Notification.BigTextStyle().bigText(text))
            .setContentIntent(open(context, event.optString("route"), 1))
            .addAction(Notification.Action.Builder(null, event.optString("stop", "Stop"), stop).build())
            .setOngoing(true)
            .build()
    }

    private fun updateStatus(context: Context) {
        val prefs = status(context)
        if (!prefs.optBoolean("enabled") || !manager(context).areNotificationsEnabled()) {
            manager(context).cancel(STATUS_ID)
            return
        }
        val now = System.currentTimeMillis()
        val prayers = array(prefs.optJSONArray("prayers")?.toString())
        val next = prayers.firstOrNull { it.optLong("at") > now }
        val last = prayers.lastOrNull { it.optLong("at") <= now }
        val place = prefs.optString("place")
        val title = prefs.optString("title")
        val b = builder(context, UPCOMING).setContentTitle(title)
            .setOnlyAlertOnce(true).setOngoing(true)
            .setContentIntent(open(context, prefs.optString("route"), STATUS_ID))
        if (next == null) {
            b.setContentText(prefs.optString("unknown"))
        } else {
            val label = prefs.optString("next") + " " + next.optString("label")
            b.setContentText("$place · $label")
                .setWhen(next.optLong("at")).setShowWhen(true)
                .setUsesChronometer(true).setChronometerCountDown(true)
            if (last != null && Build.VERSION.SDK_INT >= 24) {
                val clock = SystemClock.elapsedRealtime()
                val expanded = RemoteViews(context.packageName, R.layout.prayer_notification_expanded).apply {
                    setTextViewText(R.id.prayer_status_place, place)
                    setTextViewText(R.id.prayer_status_next, label)
                    setTextViewText(R.id.prayer_status_last, prefs.optString("last") + " " + last.optString("label"))
                    setChronometer(R.id.prayer_status_countdown, clock + next.optLong("at") - now, null, true)
                    setChronometerCountDown(R.id.prayer_status_countdown, true)
                    setChronometer(R.id.prayer_status_elapsed, clock + last.optLong("at") - now, null, true)
                }
                b.setStyle(Notification.DecoratedCustomViewStyle()).setCustomBigContentView(expanded)
            }
        }
        manager(context).notify(STATUS_ID, b.build())
    }
}

class WorshipAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "madar.worship.stop") {
            context.stopService(Intent(context, WorshipAudioService::class.java))
            return
        }
        WorshipAlarms.due(context, intent.action == "madar.worship.alarm")
    }
}

class WorshipAudioService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var player: MediaPlayer? = null
    private var focus: AudioFocusRequest? = null
    private var activeAdhan = false
    private val audio by lazy { getSystemService(AudioManager::class.java) }
    private val focusListener = AudioManager.OnAudioFocusChangeListener {
        if (it < 0) stopSelf()
    }

    companion object {
        private var current: WorshipAudioService? = null

        fun stopAdhanFromVolumeKey() {
            current?.takeIf { it.activeAdhan }?.stopSelf()
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val event = intent?.getStringExtra("event")?.let(::JSONObject) ?: run {
            stopSelf()
            return START_NOT_STICKY
        }
        if (activeAdhan && event.optString("kind") != "adhan") return START_NOT_STICKY
        player?.release()
        player = null
        handler.removeCallbacksAndMessages(null)
        focus?.let { if (Build.VERSION.SDK_INT >= 26) audio.abandonAudioFocusRequest(it) }
        focus = null
        current = this
        activeAdhan = event.optString("kind") == "adhan"
        startForeground(31_018, WorshipAlarms.playbackNotice(this, event))
        if (audio.getStreamVolume(AudioManager.STREAM_ALARM) == 0) {
            stopSelf()
            return START_NOT_STICKY
        }
        val attrs = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build()
        val granted = if (Build.VERSION.SDK_INT >= 26) {
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(attrs).setOnAudioFocusChangeListener(focusListener).build()
            focus = request
            audio.requestAudioFocus(request)
        } else {
            audio.requestAudioFocus(focusListener, AudioManager.STREAM_ALARM, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
        }
        if (granted != AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
            stopSelf()
            return START_NOT_STICKY
        }
        runCatching {
            val media = MediaPlayer()
            player = media
            media.setAudioAttributes(attrs)
            WorshipAlarms.source(this, media, event.getString("sound"))
            media.setOnPreparedListener { if (player === it) it.start() }
            media.setOnCompletionListener { stopSelf() }
            media.setOnErrorListener { _, _, _ -> stopSelf(); true }
            media.prepareAsync()
            if (activeAdhan) watchVolume()
            handler.postDelayed({ stopSelf() }, 10 * 60_000L)
        }.onFailure { stopSelf() }
        return START_NOT_STICKY
    }

    private fun watchVolume() {
        val streams = listOf(AudioManager.STREAM_ALARM, AudioManager.STREAM_MUSIC, AudioManager.STREAM_RING)
        val initial = streams.map(audio::getStreamVolume)
        val check = object : Runnable {
            override fun run() {
                if (streams.map(audio::getStreamVolume) != initial) stopSelf()
                else handler.postDelayed(this, 200)
            }
        }
        handler.postDelayed(check, 200)
    }

    override fun onDestroy() {
        if (current === this) current = null
        handler.removeCallbacksAndMessages(null)
        player?.release()
        if (Build.VERSION.SDK_INT >= 26) focus?.let(audio::abandonAudioFocusRequest)
        else audio.abandonAudioFocus(focusListener)
        super.onDestroy()
    }
}
