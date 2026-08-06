package com.fulbii.watch.data

import android.content.Context
import androidx.room.Dao
import androidx.room.Database
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Room
import androidx.room.RoomDatabase
import com.fulbii.watch.model.FieldEntity
import com.fulbii.watch.model.FieldGeometryEntity
import com.fulbii.watch.model.MatchEventEntity
import com.fulbii.watch.model.MatchSessionEntity
import com.fulbii.watch.model.PositionSampleEntity

@Dao
interface MatchDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertSession(session: MatchSessionEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertSamples(samples: List<PositionSampleEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertEvents(events: List<MatchEventEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertField(field: FieldEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertGeometry(geometry: FieldGeometryEntity)

    @Query("SELECT * FROM watch_match_events WHERE sessionId = :sessionId ORDER BY timestamp ASC")
    suspend fun eventsBySession(sessionId: String): List<MatchEventEntity>

    @Query("SELECT * FROM watch_position_samples WHERE sessionId = :sessionId ORDER BY timestamp ASC")
    suspend fun samplesBySession(sessionId: String): List<PositionSampleEntity>
}

@Database(
    entities = [
        MatchSessionEntity::class,
        PositionSampleEntity::class,
        MatchEventEntity::class,
        FieldEntity::class,
        FieldGeometryEntity::class
    ],
    version = 1
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun matchDao(): MatchDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun get(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "fulbii_watch.db"
                ).build().also { INSTANCE = it }
            }
        }
    }
}
