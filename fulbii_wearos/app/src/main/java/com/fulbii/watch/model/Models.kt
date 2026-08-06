package com.fulbii.watch.model

import androidx.room.Entity
import androidx.room.PrimaryKey

enum class MatchStatus { IDLE, LIVE, PAUSED, FINISHED, AUTO_FINISHED }
enum class MatchEventType { GOAL, ASSIST, PAUSE, RESUME, SIDE_CHANGE }

@Entity(tableName = "watch_match_sessions")
data class MatchSessionEntity(
    @PrimaryKey val id: String,
    val userId: Long,
    val fieldId: Long,
    val startTime: Long,
    val endTime: Long?,
    val status: MatchStatus,
    val distanceMeters: Double
)

@Entity(tableName = "watch_position_samples")
data class PositionSampleEntity(
    @PrimaryKey val id: String,
    val sessionId: String,
    val timestamp: Long,
    val lat: Double,
    val lng: Double,
    val horizontalAccuracy: Double,
    val speed: Double
)

@Entity(tableName = "watch_match_events")
data class MatchEventEntity(
    @PrimaryKey val id: String,
    val sessionId: String,
    val type: MatchEventType,
    val timestamp: Long,
    val minute: Int,
    val clockTime: String
)

@Entity(tableName = "fields")
data class FieldEntity(
    @PrimaryKey val id: Long,
    val name: String,
    val centerLat: Double,
    val centerLng: Double
)

@Entity(tableName = "field_geometries")
data class FieldGeometryEntity(
    @PrimaryKey val fieldId: Long,
    val widthMeters: Double,
    val lengthMeters: Double,
    val rotationDegrees: Double
)
