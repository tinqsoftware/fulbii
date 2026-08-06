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
import androidx.wear.compose.material.Scaffold
import androidx.wear.compose.material.Switch
import androidx.wear.compose.material.Text
import com.fulbii.watch.vm.MatchViewModel

@Composable
fun SettingsDebugScreen(vm: MatchViewModel, onBack: () -> Unit) {
    val state by vm.state.collectAsState()
    Scaffold {
        Column(
            modifier = Modifier.fillMaxSize().padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text("Debug")
            RowToggle("Simulación", state.debugEnabled) { vm.setDebugEnabled(it) }
            RowToggle("Asistencia", state.assistanceEnabled) { vm.setAssistanceEnabled(it) }
            Button(onClick = { vm.simulateTenMinutes() }) { Text("Simular 10 min") }
            Button(onClick = onBack) { Text("Volver") }
        }
    }
}

@Composable
private fun RowToggle(label: String, checked: Boolean, onChange: (Boolean) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text(label)
        Switch(checked = checked, onCheckedChange = onChange)
    }
}
