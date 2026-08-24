package com.fulbii.fulbii_app

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    private var requestedLaunchPermissions = false

    override fun onPostResume() {
        super.onPostResume()
        if (!requestedLaunchPermissions) {
            requestedLaunchPermissions = true
            requestNextLaunchPermission()
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == notificationPermissionRequestCode) {
            // Android only presents one runtime permission dialog at a time.
            // Ask for location after the notification choice is completed.
            Handler(Looper.getMainLooper()).post { requestNextLaunchPermission() }
        }
    }

    private fun requestNextLaunchPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                notificationPermissionRequestCode,
            )
            return
        }

        val hasFineLocation =
            checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        val hasCoarseLocation =
            checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
        if (!hasFineLocation && !hasCoarseLocation) {
            requestPermissions(
                arrayOf(
                    Manifest.permission.ACCESS_FINE_LOCATION,
                    Manifest.permission.ACCESS_COARSE_LOCATION,
                ),
                locationPermissionRequestCode,
            )
        }
    }

    private companion object {
        const val notificationPermissionRequestCode = 1001
        const val locationPermissionRequestCode = 1002
    }
}
