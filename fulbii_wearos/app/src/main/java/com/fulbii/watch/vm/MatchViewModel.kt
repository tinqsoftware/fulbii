package com.fulbii.watch.vm

import android.content.Context
import android.os.VibrationEffect
import android.os.Vibrator
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.fulbii.watch.data.AppDatabase
import com.fulbii.watch.data.MatchRepository
import com.fulbii.watch.model.MatchEventEntity
import com.fulbii.watch.model.MatchEventType
import com.fulbii.watch.model.MatchSessionEntity
import com.fulbii.watch.model.MatchStatus
import com.fulbii.watch.model.PositionSampleEntity
import com.fulbii.watch.services.LocationTracker
import com.fulbii.watch.services.Sample
import com.fulbii.watch.services.SyncManager
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID
import kotlin.math.PI
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.floor
import kotlin.math.sin
import kotlin.math.sqrt

data class UiState(
    val isLive: Boolean = false,
    val status: MatchStatus = MatchStatus.IDLE,
    val elapsedSeconds: Int = 0,
    val distanceMeters: Double = 0.0,
    val gpsStatus: String = "debil",
    val goals: List<MatchEventEntity> = emptyList(),
    val assists: List<MatchEventEntity> = emptyList(),
    val samples: List<PositionSampleEntity> = emptyList(),
    val currentSessionId: String? = null,
    val toastMessage: String? = null,
    val debugEnabled: Boolean = true,
    val assistanceEnabled: Boolean = true
)

class MatchViewModel(
    private val context: Context,
    private val repository: MatchRepository,
    private val tracker: LocationTracker,
    private val syncManager: SyncManager
) : ViewModel() {
    private val _state = MutableStateFlow(UiState())
    val state: StateFlow<UiState> = _state

    private var startMs: Long = 0L
    private var endMs: Long? = null
    private var lastMovementMs: Long = 0L

    fun startMatch() {
        val sessionId = UUID.randomUUID().toString()
        startMs = System.currentTimeMillis()
        endMs = null
        lastMovementMs = startMs
        _state.value = UiState(isLive = true, status = MatchStatus.LIVE, currentSessionId = sessionId)

        viewModelScope.launch {
            repository.upsertSession(
                MatchSessionEntity(
                    id = sessionId,
                    userId = 1,
                    fieldId = 1,
                    startTime = startMs,
                    endTime = null,
                    status = MatchStatus.LIVE,
                    distanceMeters = 0.0
                )
            )
        }

        tracker.start(::onSample)
        vibrate()
    }

    fun togglePause() {
        val newStatus = if (_state.value.status == MatchStatus.PAUSED) MatchStatus.LIVE else MatchStatus.PAUSED
        _state.update { it.copy(status = newStatus) }
        addEvent(if (newStatus == MatchStatus.PAUSED) MatchEventType.PAUSE else MatchEventType.RESUME)
    }

    fun addGoal() = addEvent(MatchEventType.GOAL)
    fun addAssist() = addEvent(MatchEventType.ASSIST)

    fun finishMatch(auto: Boolean) {
        val sessionId = _state.value.currentSessionId ?: return
        val status = if (auto) MatchStatus.AUTO_FINISHED else MatchStatus.FINISHED
        endMs = System.currentTimeMillis()
        tracker.stop()

        _state.update {
            it.copy(
                isLive = false,
                status = status,
                elapsedSeconds = (((endMs ?: startMs) - startMs) / 1000).toInt().coerceAtLeast(0)
            )
        }

        viewModelScope.launch {
            repository.upsertSession(
                MatchSessionEntity(
                    id = sessionId,
                    userId = 1,
                    fieldId = 1,
                    startTime = startMs,
                    endTime = endMs,
                    status = status,
                    distanceMeters = _state.value.distanceMeters
                )
            )
            syncManager.syncStub(sessionId, _state.value.goals.size + _state.value.assists.size, _state.value.samples.size)
        }
        vibrate()
    }

    fun simulateTenMinutes() {
        val sessionId = UUID.randomUUID().toString()
        val now = System.currentTimeMillis()
        val start = now - 600_000
        startMs = start
        endMs = now

        val samples = buildList {
            for (idx in 0 until 60) {
                val ratio = idx / 59.0
                add(
                    PositionSampleEntity(
                        id = UUID.randomUUID().toString(),
                        sessionId = sessionId,
                        timestamp = start + idx * 10_000L,
                        lat = -12.0464 + (0.0002 * sin(ratio * 8)),
                        lng = -77.0428 + (0.0002 * cos(ratio * 8)),
                        horizontalAccuracy = 8.0,
                        speed = 1.5
                    )
                )
            }
        }
        val goals = listOf(
            fakeEvent(sessionId, MatchEventType.GOAL, start + 180_000L, 4),
            fakeEvent(sessionId, MatchEventType.GOAL, start + 520_000L, 9)
        )

        _state.update {
            it.copy(
                isLive = false,
                status = MatchStatus.FINISHED,
                elapsedSeconds = 600,
                distanceMeters = totalDistance(samples),
                goals = goals,
                assists = emptyList(),
                samples = samples,
                currentSessionId = sessionId
            )
        }

        viewModelScope.launch {
            repository.upsertSession(
                MatchSessionEntity(
                    id = sessionId,
                    userId = 1,
                    fieldId = 1,
                    startTime = start,
                    endTime = now,
                    status = MatchStatus.FINISHED,
                    distanceMeters = _state.value.distanceMeters
                )
            )
            repository.insertSamples(samples)
            repository.insertEvents(goals)
            syncManager.syncStub(sessionId, goals.size, samples.size)
        }
    }

    fun setDebugEnabled(enabled: Boolean) = _state.update { it.copy(debugEnabled = enabled) }
    fun setAssistanceEnabled(enabled: Boolean) = _state.update { it.copy(assistanceEnabled = enabled) }

    private fun onSample(sample: Sample) {
        val sessionId = _state.value.currentSessionId ?: return
        if (_state.value.status != MatchStatus.LIVE) return

        val mapped = PositionSampleEntity(
            id = UUID.randomUUID().toString(),
            sessionId = sessionId,
            timestamp = sample.timestamp,
            lat = sample.lat,
            lng = sample.lng,
            horizontalAccuracy = sample.horizontalAccuracy,
            speed = sample.speed
        )

        val prev = _state.value.samples.lastOrNull()
        val delta = if (prev == null) 0.0 else haversineMeters(prev.lat, prev.lng, mapped.lat, mapped.lng)
        if (delta >= 3 || mapped.speed >= 0.5) {
            lastMovementMs = sample.timestamp
        }
        val elapsed = ((sample.timestamp - startMs) / 1000).toInt().coerceAtLeast(0)

        _state.update {
            it.copy(
                elapsedSeconds = elapsed,
                distanceMeters = it.distanceMeters + delta,
                samples = it.samples + mapped,
                gpsStatus = if (mapped.horizontalAccuracy <= 20) "ok" else "debil"
            )
        }

        viewModelScope.launch { repository.insertSamples(listOf(mapped)) }
        if (sample.timestamp - lastMovementMs >= 30 * 60 * 1000L) {
            finishMatch(auto = true)
        }
    }

    private fun addEvent(type: MatchEventType) {
        val sessionId = _state.value.currentSessionId ?: return
        val now = System.currentTimeMillis()
        val minute = maxOf(1, floor((now - startMs) / 60_000.0).toInt() + 1)
        val event = fakeEvent(sessionId, type, now, minute)
        _state.update {
            when (type) {
                MatchEventType.GOAL -> it.copy(goals = it.goals + event, toastMessage = "Gol min $minute")
                MatchEventType.ASSIST -> it.copy(assists = it.assists + event, toastMessage = "Asistencia min $minute")
                else -> it.copy(toastMessage = type.name.lowercase(Locale.ROOT))
            }
        }
        viewModelScope.launch { repository.insertEvents(listOf(event)) }
        if (type == MatchEventType.GOAL) vibrate()
    }

    private fun fakeEvent(sessionId: String, type: MatchEventType, timestamp: Long, minute: Int): MatchEventEntity {
        val time = SimpleDateFormat("HH:mm", Locale.US).format(Date(timestamp))
        return MatchEventEntity(
            id = UUID.randomUUID().toString(),
            sessionId = sessionId,
            type = type,
            timestamp = timestamp,
            minute = minute,
            clockTime = time
        )
    }

    private fun totalDistance(samples: List<PositionSampleEntity>): Double {
        var sum = 0.0
        for (idx in 1 until samples.size) {
            sum += haversineMeters(
                samples[idx - 1].lat,
                samples[idx - 1].lng,
                samples[idx].lat,
                samples[idx].lng
            )
        }
        return sum
    }

    private fun haversineMeters(lat1: Double, lng1: Double, lat2: Double, lng2: Double): Double {
        val r = 6_371_000.0
        val dLat = (lat2 - lat1) * PI / 180.0
        val dLon = (lng2 - lng1) * PI / 180.0
        val a = sin(dLat / 2) * sin(dLat / 2) +
            cos(lat1 * PI / 180.0) * cos(lat2 * PI / 180.0) *
            sin(dLon / 2) * sin(dLon / 2)
        return r * (2 * atan2(sqrt(a), sqrt(1 - a)))
    }

    private fun vibrate() {
        val vibrator = context.getSystemService(Vibrator::class.java) ?: return
        vibrator.vibrate(VibrationEffect.createOneShot(120, VibrationEffect.DEFAULT_AMPLITUDE))
    }

    class Factory(private val context: Context) : ViewModelProvider.Factory {
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            val db = AppDatabase.get(context)
            val repo = MatchRepository(db.matchDao())
            val tracker = LocationTracker(context)
            val sync = SyncManager()
            @Suppress("UNCHECKED_CAST")
            return MatchViewModel(context, repo, tracker, sync) as T
        }
    }
}
