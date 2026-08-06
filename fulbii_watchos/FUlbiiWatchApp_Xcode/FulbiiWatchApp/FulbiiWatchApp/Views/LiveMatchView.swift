import SwiftUI

struct LiveMatchView: View {
    @ObservedObject var vm: MatchSessionManager

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text(vm.elapsedLabel)
                    .font(.title2)
                    .fontWeight(.bold)
                HStack {
                    Text(vm.distanceLabel).font(.caption)
                    Spacer()
                    Text("GPS \(vm.gpsStatus)").font(.caption)
                }

                Button("Gol") { vm.registerGoal() }
                    .buttonStyle(.borderedProminent)
                    .font(.headline)

                Button("Asistencia") { vm.registerAssist() }
                    .buttonStyle(.bordered)
                    .font(.headline)
                    .disabled(!vm.assistanceEnabled)

                Button(vm.activeSession?.status == .paused ? "Reanudar" : "Pausa") {
                    vm.pauseOrResume()
                }
                .buttonStyle(.bordered)
                .font(.headline)

                Button("Finalizar") { vm.finishMatch() }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .font(.headline)
            }
            .padding()
        }
    }
}
