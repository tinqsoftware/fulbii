import SwiftUI

struct SettingsDebugView: View {
    @ObservedObject var vm: MatchSessionManager

    var body: some View {
        Form {
            Section("Sesión iPhone") {
                Text("Usuario: \(vm.linkedUserLabel ?? "No vinculado")")
            }

            #if DEBUG
            Section("Debug") {
                Text("User ID: \(vm.linkedUserId.map(String.init) ?? "No")")
                Text("Token: \(vm.linkedAuthTokenAvailable ? "Sí" : "No")")
            }
            Toggle("Asistencia habilitada", isOn: $vm.assistanceEnabled)
            Button("Simular partido de 30 min") {
                vm.simulateThirtyMinutes()
            }
            #endif
        }
    }
}
