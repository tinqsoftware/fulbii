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
fun SummaryScreen(vm: MatchViewModel, onBack: () -> Unit) {
    val state by vm.state.collectAsState()
    Scaffold {
        Column(
            modifier = Modifier.fillMaxSize().padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Text("Resumen", style = MaterialTheme.typography.title3)
            Text("Min: ${state.elapsedSeconds / 60}")
            Text(String.format("Distancia %.0f m", state.distanceMeters))
            Text("Goles: ${state.goals.size}")
            state.goals.forEach { Text("⚽ min ${it.minute}", style = MaterialTheme.typography.caption3) }
            Button(onClick = onBack) { Text("Volver") }
        }
    }
}
