package com.fulbii.fulbii_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject

class FulbiiConfirmedWidgetProvider : HomeWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        if (intent.action != ACTION_SELECT_PICHANGA) {
            return
        }

        val pichangaId = intent.getIntExtra(EXTRA_PICHANGA_ID, 0)
        if (pichangaId <= 0) {
            return
        }

        val prefs = HomeWidgetPlugin.getData(context)
        val raw = prefs.getString(PAYLOAD_KEY, null) ?: return
        val updated = applySelection(raw, pichangaId) ?: return
        prefs.edit().putString(PAYLOAD_KEY, updated).apply()

        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(
            ComponentName(context, FulbiiConfirmedWidgetProvider::class.java)
        )
        onUpdate(context, manager, ids, prefs)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val payload = parsePayload(widgetData.getString(PAYLOAD_KEY, null))

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.fulbii_confirmed_widget)
            var selectedItem: WidgetItem? = null

            if (!payload.isLoggedIn) {
                views.setViewVisibility(R.id.confirmed_content, View.GONE)
                views.setViewVisibility(R.id.confirmed_empty_message, View.GONE)
                views.setViewVisibility(R.id.confirmed_login_message, View.VISIBLE)
                views.setTextViewText(
                    R.id.confirmed_login_message,
                    payload.loginMessage.ifBlank { DEFAULT_LOGIN_MESSAGE }
                )
            } else {
                views.setViewVisibility(R.id.confirmed_login_message, View.GONE)
                views.setViewVisibility(R.id.confirmed_content, View.VISIBLE)
                if (payload.items.isEmpty()) {
                    views.setViewVisibility(R.id.confirmed_empty_message, View.VISIBLE)
                    views.setTextViewText(R.id.confirmed_empty_message, DEFAULT_EMPTY_MESSAGE)
                    bindTeams(views, emptyList())
                    views.setViewVisibility(R.id.button_row, View.GONE)
                } else {
                    views.setViewVisibility(R.id.confirmed_empty_message, View.GONE)
                    selectedItem = resolveSelectedItem(payload.items, payload.selectedPichangaId)
                    bindChips(context, views, widgetId, payload.items, selectedItem?.id)
                    bindTeams(views, selectedItem?.teams ?: emptyList())
                    bindShareButtons(context, views, selectedItem?.id)
                }
            }

            val rootUri = selectedItem?.id?.let { id ->
                Uri.parse("fulbii://pichanga/$id")
            } ?: Uri.parse("fulbii://home")
            val rootIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                rootUri
            )
            views.setOnClickPendingIntent(R.id.confirmed_root, rootIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun bindChips(
        context: Context,
        views: RemoteViews,
        widgetId: Int,
        items: List<WidgetItem>,
        selectedPichangaId: Int?
    ) {
        for (index in CHIP_IDS.indices) {
            val chipId = CHIP_IDS[index]
            val item = items.getOrNull(index)
            if (item == null) {
                views.setViewVisibility(chipId, View.INVISIBLE)
                continue
            }

            views.setViewVisibility(chipId, View.VISIBLE)
            val selected = selectedPichangaId == item.id
            views.setTextViewText(
                chipId,
                "${item.startsLabel}\n${item.formatLabel}"
            )
            views.setInt(
                chipId,
                "setBackgroundResource",
                if (selected) R.drawable.widget_chip_selected else R.drawable.widget_chip_default
            )
            views.setTextColor(
                chipId,
                ContextCompat.getColor(
                    context,
                    if (selected) R.color.widget_chip_selected_text else R.color.widget_chip_default_text
                )
            )

            val clickIntent = Intent(context, FulbiiConfirmedWidgetProvider::class.java).apply {
                action = ACTION_SELECT_PICHANGA
                putExtra(EXTRA_PICHANGA_ID, item.id)
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                widgetId * 10 + index,
                clickIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(chipId, pendingIntent)
        }
    }

    private fun bindTeams(views: RemoteViews, teams: List<WidgetTeam>) {
        for (index in TEAM_COL_IDS.indices) {
            val columnId = TEAM_COL_IDS[index]
            val titleId = TEAM_TITLE_IDS[index]
            val playersId = TEAM_PLAYERS_IDS[index]
            val team = teams.getOrNull(index)

            if (team == null) {
                views.setViewVisibility(columnId, View.GONE)
                continue
            }

            views.setViewVisibility(columnId, View.VISIBLE)
            views.setTextViewText(titleId, team.title)
            views.setTextViewText(playersId, team.playersText)
        }
    }

    private fun bindShareButtons(context: Context, views: RemoteViews, selectedId: Int?) {
        if (selectedId == null) {
            views.setViewVisibility(R.id.button_row, View.GONE)
            return
        }

        views.setViewVisibility(R.id.button_row, View.VISIBLE)
        val shareLinkIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("fulbii://widget/confirmed/share-link?id=$selectedId")
        )
        val shareLineupIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("fulbii://widget/confirmed/share-lineup?id=$selectedId")
        )
        views.setOnClickPendingIntent(R.id.share_button, shareLinkIntent)
        views.setOnClickPendingIntent(R.id.lineup_button, shareLineupIntent)
    }

    private fun parsePayload(raw: String?): WidgetPayload {
        if (raw.isNullOrBlank()) {
            return WidgetPayload.default()
        }

        return try {
            val root = JSONObject(raw)
            val items = parseItems(root.optJSONArray("items") ?: JSONArray())
            val selectedPichangaId = if (root.has("selected_pichanga_id") && !root.isNull("selected_pichanga_id")) {
                root.optInt("selected_pichanga_id")
            } else {
                null
            }

            WidgetPayload(
                isLoggedIn = parseBoolean(root, "is_logged_in", true),
                loginMessage = root.optString("login_message", DEFAULT_LOGIN_MESSAGE),
                selectedPichangaId = selectedPichangaId,
                items = items
            )
        } catch (_: Throwable) {
            WidgetPayload.default()
        }
    }

    private fun parseItems(items: JSONArray): List<WidgetItem> {
        return buildList {
            for (i in 0 until items.length()) {
                val item = items.optJSONObject(i) ?: continue
                val id = item.optInt("id", 0)
                if (id <= 0) {
                    continue
                }
                val teams = parseTeams(item.optJSONArray("teams") ?: JSONArray())
                add(
                    WidgetItem(
                        id = id,
                        startsLabel = item.optString("starts_label", "-"),
                        formatLabel = item.optString("format_label", "-"),
                        teams = teams
                    )
                )
            }
        }
    }

    private fun parseTeams(teams: JSONArray): List<WidgetTeam> {
        return buildList {
            for (i in 0 until teams.length()) {
                val team = teams.optJSONObject(i) ?: continue
                val code = team.optString("code", "").ifBlank { "-" }
                val avgRaw = team.opt("avg_rating")
                val avg = when (avgRaw) {
                    is Number -> String.format("%.1f", avgRaw.toDouble())
                    is String -> avgRaw.ifBlank { "-" }
                    else -> "-"
                }
                val players = parseTeamPlayers(team.optJSONArray("slots") ?: JSONArray())

                add(
                    WidgetTeam(
                        title = "$code (★$avg)",
                        playersText = if (players.isEmpty()) {
                            "- Sin confirmados"
                        } else {
                            players.mapIndexed { index, name -> "${index + 1}. $name" }.joinToString("\n")
                        }
                    )
                )
            }
        }
    }

    private fun parseTeamPlayers(slots: JSONArray): List<String> {
        return buildList {
            for (i in 0 until slots.length()) {
                val slot = slots.optJSONObject(i) ?: continue
                val displayName = slot.optString("display_name", "").trim()
                if (displayName.isNotEmpty()) {
                    add(displayName)
                    continue
                }
                val user = slot.optJSONObject("user") ?: continue
                val nick = user.optString("nick", "").trim()
                val name = user.optString("name", "").trim()
                val finalName = if (nick.isNotEmpty()) nick else name
                if (finalName.isNotEmpty()) {
                    add(finalName)
                }
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

    private fun resolveSelectedItem(items: List<WidgetItem>, selectedPichangaId: Int?): WidgetItem? {
        if (items.isEmpty()) {
            return null
        }
        return items.firstOrNull { it.id == selectedPichangaId } ?: items.first()
    }

    private fun applySelection(raw: String, pichangaId: Int): String? {
        return try {
            val root = JSONObject(raw)
            val items = root.optJSONArray("items") ?: JSONArray()
            var exists = false
            for (i in 0 until items.length()) {
                val item = items.optJSONObject(i) ?: continue
                if (item.optInt("id", -1) == pichangaId) {
                    exists = true
                    break
                }
            }
            if (!exists) {
                return null
            }
            root.put("selected_pichanga_id", pichangaId)
            root.toString()
        } catch (_: Throwable) {
            null
        }
    }

    data class WidgetItem(
        val id: Int,
        val startsLabel: String,
        val formatLabel: String,
        val teams: List<WidgetTeam>
    )

    data class WidgetTeam(
        val title: String,
        val playersText: String
    )

    data class WidgetPayload(
        val isLoggedIn: Boolean,
        val loginMessage: String,
        val selectedPichangaId: Int?,
        val items: List<WidgetItem>
    ) {
        companion object {
            fun default(): WidgetPayload {
                return WidgetPayload(
                    isLoggedIn = true,
                    loginMessage = DEFAULT_LOGIN_MESSAGE,
                    selectedPichangaId = null,
                    items = emptyList()
                )
            }
        }
    }

    companion object {
        private const val PAYLOAD_KEY = "fulbii_confirmed_widget_payload"
        private const val ACTION_SELECT_PICHANGA = "com.fulbii.fulbii_app.ACTION_SELECT_PICHANGA"
        private const val EXTRA_PICHANGA_ID = "extra_pichanga_id"
        private const val DEFAULT_LOGIN_MESSAGE = "Inicia sesión"
        private const val DEFAULT_EMPTY_MESSAGE = "Sin pichangas confirmadas"

        private val CHIP_IDS = intArrayOf(
            R.id.chip0,
            R.id.chip1,
            R.id.chip2
        )

        private val TEAM_COL_IDS = intArrayOf(
            R.id.team0_col,
            R.id.team1_col,
            R.id.team2_col,
            R.id.team3_col
        )

        private val TEAM_TITLE_IDS = intArrayOf(
            R.id.team0_title,
            R.id.team1_title,
            R.id.team2_title,
            R.id.team3_title
        )

        private val TEAM_PLAYERS_IDS = intArrayOf(
            R.id.team0_players,
            R.id.team1_players,
            R.id.team2_players,
            R.id.team3_players
        )
    }
}
