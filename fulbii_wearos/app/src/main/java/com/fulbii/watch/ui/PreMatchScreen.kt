package com.fulbii.watch.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material.Button
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Scaffold
import androidx.wear.compose.material.Text
import com.fulbii.watch.vm.MatchViewModel

@Composable
fun PreMatchScreen(
    vm: MatchViewModel,
    onStart: () -> Unit,
    onSimulate: () -> Unit,
    onSettings: () -> Unit
) {
    Scaffold {
        Column(
            modifier = Modifier.fillMaxSize().padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text("Fulbii Watch", style = MaterialTheme.typography.title3)
            Text("Centro: Mock Centro")
            Text("Cancha: Mock A")
            Button(onClick = onStart) { Text("Iniciar partido") }
            Button(onClick = onSimulate) { Text("Simular 10 min") }
            Button(onClick = onSettings) { Text("Debug") }
        }
    }
}
