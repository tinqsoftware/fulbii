package com.fulbii.watch.services

import android.util.Log

class SyncManager {
    fun syncStub(sessionId: String, eventsCount: Int, samplesCount: Int) {
        Log.i(
            "FulbiiWatchSync",
            "Stub sync -> session=$sessionId events=$eventsCount samples=$samplesCount"
        )
    }
}
