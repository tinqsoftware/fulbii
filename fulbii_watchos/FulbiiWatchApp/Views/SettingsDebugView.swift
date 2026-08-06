import SwiftUI

struct SettingsDebugView: View {
    @ObservedObject var vm: MatchSessionManager

    var body: some View {
        Form {
            Toggle("Asistencia habilitada", isOn: $vm.assistanceEnabled)
            Toggle("Simulación debug", isOn: $vm.debugSimulationEnabled)
            Button("Simular partido de 30 min") {
                vm.simulateThirtyMinutes()
            }
            .disabled(!vm.debugSimulationEnabled)
        }
    }
}
