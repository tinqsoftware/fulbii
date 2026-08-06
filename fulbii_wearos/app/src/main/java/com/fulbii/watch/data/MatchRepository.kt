package com.fulbii.watch.data

import com.fulbii.watch.model.MatchEventEntity
import com.fulbii.watch.model.MatchSessionEntity
import com.fulbii.watch.model.PositionSampleEntity

class MatchRepository(private val dao: MatchDao) {
    suspend fun upsertSession(session: MatchSessionEntity) = dao.upsertSession(session)
    suspend fun insertSamples(samples: List<PositionSampleEntity>) = dao.insertSamples(samples)
    suspend fun insertEvents(events: List<MatchEventEntity>) = dao.insertEvents(events)
    suspend fun eventsBySession(sessionId: String) = dao.eventsBySession(sessionId)
    suspend fun samplesBySession(sessionId: String) = dao.samplesBySession(sessionId)
}
