package com.fulbii.fulbii_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject

class FulbiiWeeklyWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val payload = parsePayload(widgetData.getString(PAYLOAD_KEY, null))

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.fulbii_weekly_widget).apply {
                setTextViewText(
                    R.id.widget_monthly_count,
                    "${payload.monthlyPlayedCount} pichangas jugadas este mes"
                )
                setTextViewText(
                    R.id.widget_title,
                    payload.headerTitle.ifBlank { DEFAULT_HEADER_TITLE }
                )
                setTextViewText(
                    R.id.widget_subtitle,
                    payload.headerSubtitle.ifBlank { DEFAULT_HEADER_SUBTITLE }
                )

                if (payload.isLoggedIn) {
                    setViewVisibility(R.id.widget_login_message, View.GONE)
                    setViewVisibility(R.id.days_row, View.VISIBLE)
                    for (index in DAY_COLUMN_IDS.indices) {
                        bindDay(context, this, index, payload.days.getOrNull(index))
                    }
                } else {
                    setViewVisibility(R.id.days_row, View.GONE)
                    setViewVisibility(R.id.widget_login_message, View.VISIBLE)
                    setTextViewText(
                        R.id.widget_login_message,
                        payload.loginMessage.ifBlank { DEFAULT_LOGIN_MESSAGE }
                    )
                }

                val homePendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("fulbii://pichangas")
                )
                setOnClickPendingIntent(R.id.widget_root, homePendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun bindDay(
        context: Context,
        views: RemoteViews,
        index: Int,
        day: WidgetDay?
    ) {
        val circleViewId = DAY_CIRCLE_IDS[index]
        val dayNumberViewId = DAY_NUMBER_IDS[index]
        val timeViewId = DAY_TIME_IDS[index]
        val columnViewId = DAY_COLUMN_IDS[index]

        val dayNumber = day?.dayNumber?.ifBlank { null } ?: DEFAULT_DAY_NUMBERS[index]
        val time = day?.time?.takeIf { it.isNotBlank() } ?: ""

        views.setTextViewText(dayNumberViewId, dayNumber)
        views.setTextViewText(timeViewId, time)
        views.setInt(circleViewId, "setColorFilter", statusColor(context, day?.status))

        val deepLink = Uri.parse("fulbii://pichangas")
        val pendingIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            deepLink
        )
        views.setOnClickPendingIntent(columnViewId, pendingIntent)
    }

    private fun parsePayload(payload: String?): WidgetPayload {
        if (payload.isNullOrBlank()) {
            return WidgetPayload.default()
        }

        return try {
            val root = JSONObject(payload)
            WidgetPayload(
                days = parseDays(root.optJSONArray("days") ?: JSONArray()),
                monthlyPlayedCount = root.optInt("monthly_played_count", 0),
                headerTitle = root.optString("header_title", DEFAULT_HEADER_TITLE),
                headerSubtitle = root.optString("header_subtitle", DEFAULT_HEADER_SUBTITLE),
                isLoggedIn = parseBoolean(root, "is_logged_in", true),
                loginMessage = root.optString("login_message", DEFAULT_LOGIN_MESSAGE)
            )
        } catch (_: Throwable) {
            WidgetPayload.default()
        }
    }

    private fun parseDays(days: JSONArray): List<WidgetDay> {
        return buildList {
            for (i in 0 until days.length()) {
                val row = days.optJSONObject(i) ?: continue
                val pichangaId = if (row.has("pichanga_id") && !row.isNull("pichanga_id")) {
                    row.optInt("pichanga_id")
                } else {
                    null
                }
                val time = if (row.has("time") && !row.isNull("time")) {
                    row.optString("time", "")
                } else {
                    ""
                }
                add(
                    WidgetDay(
                        dayNumber = row.optString("day_number", ""),
                        status = row.optString("status", "neutral"),
                        time = time,
                        pichangaId = pichangaId
                    )
                )
            }
        }
    }

    private fun parseBoolean(root: JSONObject, key: String, default: Boolean): Boolean {
        if (!root.has(key) || root.isNull(key)) {
            return default
        }

        return when (val value = root.opt(key)) {
            is Boolean -> value
            is Number -> value.toInt() != 0
            is String -> value.equals("true", ignoreCase = true) || value == "1"
            else -> default
        }
    }

    private fun statusColor(context: Context, status: String?): Int {
        return when (status?.lowercase()) {
            "green" -> ContextCompat.getColor(context, R.color.widget_status_green)
            "yellow" -> ContextCompat.getColor(context, R.color.widget_status_yellow)
            else -> ContextCompat.getColor(context, R.color.widget_status_neutral)
        }
    }

    data class WidgetDay(
        val dayNumber: String,
        val status: String,
        val time: String,
        val pichangaId: Int?
    )

    data class WidgetPayload(
        val days: List<WidgetDay>,
        val monthlyPlayedCount: Int,
        val headerTitle: String,
        val headerSubtitle: String,
        val isLoggedIn: Boolean,
        val loginMessage: String
    ) {
        companion object {
            fun default(): WidgetPayload {
                return WidgetPayload(
                    days = emptyList(),
                    monthlyPlayedCount = 0,
                    headerTitle = DEFAULT_HEADER_TITLE,
                    headerSubtitle = DEFAULT_HEADER_SUBTITLE,
                    isLoggedIn = true,
                    loginMessage = DEFAULT_LOGIN_MESSAGE
                )
            }
        }
    }

    companion object {
        private const val PAYLOAD_KEY = "fulbii_weekly_payload"
        private const val DEFAULT_HEADER_TITLE = "Pichangas de la semana"
        private const val DEFAULT_HEADER_SUBTITLE = "Hoy + 6 días"
        private const val DEFAULT_LOGIN_MESSAGE = "Inicia sesión"

        private val DAY_COLUMN_IDS = intArrayOf(
            R.id.day0_col,
            R.id.day1_col,
            R.id.day2_col,
            R.id.day3_col,
            R.id.day4_col,
            R.id.day5_col,
            R.id.day6_col,
        )
        private val DAY_CIRCLE_IDS = intArrayOf(
            R.id.day0_circle,
            R.id.day1_circle,
            R.id.day2_circle,
            R.id.day3_circle,
            R.id.day4_circle,
            R.id.day5_circle,
            R.id.day6_circle,
        )
        private val DAY_NUMBER_IDS = intArrayOf(
            R.id.day0_number,
            R.id.day1_number,
            R.id.day2_number,
            R.id.day3_number,
            R.id.day4_number,
            R.id.day5_number,
            R.id.day6_number,
        )
        private val DAY_TIME_IDS = intArrayOf(
            R.id.day0_time,
            R.id.day1_time,
            R.id.day2_time,
            R.id.day3_time,
            R.id.day4_time,
            R.id.day5_time,
            R.id.day6_time,
        )
        private val DEFAULT_DAY_NUMBERS = arrayOf("1", "2", "3", "4", "5", "6", "7")
    }
}
