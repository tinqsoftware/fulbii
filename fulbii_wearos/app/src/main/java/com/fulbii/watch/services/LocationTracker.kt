package com.fulbii.watch.services

import android.annotation.SuppressLint
import android.content.Context
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority

data class Sample(
    val timestamp: Long,
    val lat: Double,
    val lng: Double,
    val horizontalAccuracy: Double,
    val speed: Double
)

class LocationTracker(context: Context) {
    private val fusedClient: FusedLocationProviderClient =
        LocationServices.getFusedLocationProviderClient(context)
    private var callback: LocationCallback? = null

    @SuppressLint("MissingPermission")
    fun start(onSample: (Sample) -> Unit) {
        val request = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY,
            5000L
        ).setMinUpdateDistanceMeters(5f).build()

        callback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                val location = result.lastLocation ?: return
                onSample(
                    Sample(
                        timestamp = System.currentTimeMillis(),
                        lat = location.latitude,
                        lng = location.longitude,
                        horizontalAccuracy = location.accuracy.toDouble(),
                        speed = location.speed.toDouble().coerceAtLeast(0.0)
                    )
                )
            }
        }

        fusedClient.requestLocationUpdates(request, callback ?: return, null)
    }

    fun stop() {
        callback?.let { fusedClient.removeLocationUpdates(it) }
        callback = null
    }
}
