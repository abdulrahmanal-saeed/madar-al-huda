package com.abdulrahmanalsaeed.madaralhuda

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget with the next prayer and a live countdown.
 *
 * The app writes the coming prayers (name, formatted time, epoch millis) and
 * asks for an update at each prayer time, so the widget moves on by itself
 * even when the app is closed. The countdown is a Chronometer, so it ticks
 * without waking the app.
 */
class NextPrayerWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val now = System.currentTimeMillis()
        val count = widgetData.getString("prayer_count", "0")?.toIntOrNull() ?: 0
        var next: Triple<String, String, Long>? = null
        for (index in 0 until count) {
            val at = widgetData.getString("prayer_at_$index", null)?.toLongOrNull() ?: continue
            if (at > now) {
                next = Triple(
                    widgetData.getString("prayer_name_$index", "") ?: "",
                    widgetData.getString("prayer_time_$index", "") ?: "",
                    at,
                )
                break
            }
        }
        val place = widgetData.getString("prayer_place", "") ?: ""
        val open = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val tap = open?.let {
            PendingIntent.getActivity(
                context, 0, it,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
        }
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.next_prayer_widget)
            if (tap != null) views.setOnClickPendingIntent(R.id.widget_root, tap)
            if (next == null) {
                views.setTextViewText(R.id.widget_prayer, context.getString(R.string.widget_open_app))
                views.setViewVisibility(R.id.widget_time, View.GONE)
                views.setViewVisibility(R.id.widget_countdown, View.GONE)
            } else {
                views.setTextViewText(R.id.widget_prayer, next.first)
                views.setTextViewText(R.id.widget_time, next.second)
                views.setViewVisibility(R.id.widget_time, View.VISIBLE)
                val base = SystemClock.elapsedRealtime() + (next.third - now)
                views.setChronometer(R.id.widget_countdown, base, null, true)
                views.setChronometerCountDown(R.id.widget_countdown, true)
                views.setViewVisibility(R.id.widget_countdown, View.VISIBLE)
            }
            views.setTextViewText(R.id.widget_place, place)
            views.setViewVisibility(R.id.widget_place, if (place.isEmpty()) View.GONE else View.VISIBLE)
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
