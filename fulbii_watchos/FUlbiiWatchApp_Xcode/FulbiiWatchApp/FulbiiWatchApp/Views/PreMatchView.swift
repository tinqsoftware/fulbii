import SwiftUI

struct PreMatchView: View {
    @ObservedObject var vm: MatchSessionManager
    @State private var openSettings = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Fulbii Watch")
                    .font(.headline)
                    .fontWeight(.bold)
                VStack(alignment: .leading, spacing: 4) {
                    if let match = vm.activeOrUpcomingMatch {
                        Text("Centro: \(match.centerName)")
                        Text("Cancha: \(match.fieldName)")
                        Text("Hora: \(match.startAt, formatter: DateFormatter.watchTimeShort)")
                        Text("Duración: \(match.durationMinutes) min")
                    } else {
                        Text("Centro: No definido")
                        Text("Cancha: \(vm.selectedField.name)")
                        Text("Sin partido programado hoy")
                    }
                }
                .font(.footnote)

                Text(vm.preMatchStatusText)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if vm.canStartMatch {
                    Button("Iniciar partido") {
                        vm.startMatch()
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.headline)
                }

                Button("Simular partido de 30 min") {
                    vm.simulateThirtyMinutes()
                }
                .buttonStyle(.bordered)
                .font(.headline)

                Button("Debug / Settings") {
                    openSettings = true
                }
                .buttonStyle(.plain)
                .font(.footnote)
            }
            .padding()
        }
        .sheet(isPresented: $openSettings) {
            SettingsDebugView(vm: vm)
        }
    }
}

private extension DateFormatter {
    static let watchTimeShort: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
