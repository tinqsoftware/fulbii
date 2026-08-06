package com.fulbii.watch.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material.Button
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Scaffold
import androidx.wear.compose.material.Text
import com.fulbii.watch.vm.MatchViewModel

@Composable
fun LiveMatchScreen(vm: MatchViewModel, onFinish: () -> Unit) {
    val state by vm.state.collectAsState()
    val min = state.elapsedSeconds / 60
    val sec = state.elapsedSeconds % 60

    Scaffold {
        Column(
            modifier = Modifier.fillMaxSize().padding(10.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Text(String.format("%02d:%02d", min, sec), style = MaterialTheme.typography.title2)
            Text(String.format("Distancia %.0f m", state.distanceMeters))
            Text("GPS ${state.gpsStatus}")
            Button(onClick = { vm.addGoal() }) { Text("Gol") }
            Button(onClick = { if (state.assistanceEnabled) vm.addAssist() }) { Text("Asistencia") }
            Button(onClick = { vm.togglePause() }) { Text(if (state.status.name == "PAUSED") "Reanudar" else "Pausa") }
            Button(onClick = onFinish) { Text("Finalizar") }
        }
    }
}
