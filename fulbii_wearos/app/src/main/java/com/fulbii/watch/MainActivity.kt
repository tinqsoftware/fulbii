package com.fulbii.watch

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.fulbii.watch.ui.LiveMatchScreen
import com.fulbii.watch.ui.PreMatchScreen
import com.fulbii.watch.ui.SettingsDebugScreen
import com.fulbii.watch.ui.SummaryScreen
import com.fulbii.watch.vm.MatchViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            val navController = rememberNavController()
            val vm: MatchViewModel = viewModel(factory = MatchViewModel.Factory(this))

            NavHost(navController = navController, startDestination = "pre") {
                composable("pre") {
                    PreMatchScreen(
                        vm = vm,
                        onStart = {
                            vm.startMatch()
                            navController.navigate("live")
                        },
                        onSimulate = {
                            vm.simulateTenMinutes()
                            navController.navigate("summary")
                        },
                        onSettings = { navController.navigate("settings") }
                    )
                }
                composable("live") {
                    LiveMatchScreen(
                        vm = vm,
                        onFinish = {
                            vm.finishMatch(false)
                            navController.navigate("summary")
                        }
                    )
                }
                composable("summary") {
                    SummaryScreen(vm = vm, onBack = { navController.navigate("pre") })
                }
                composable("settings") {
                    SettingsDebugScreen(vm = vm, onBack = { navController.popBackStack() })
                }
            }
        }
    }
}
