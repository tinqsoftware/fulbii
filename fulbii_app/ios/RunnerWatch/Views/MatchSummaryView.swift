import SwiftUI

struct MatchSummaryView: View {
    @ObservedObject var vm: MatchSessionManager

    private let projector = HeatmapProjector()

    var body: some View {
        guard let summary = vm.latestSummary else {
            return AnyView(Text("Sin resumen disponible").font(.footnote))
        }

        let points = projector.projectedPoints(
            samples: summary.samples,
            field: vm.selectedField,
            geometry: vm.selectedGeometry
        )

        return AnyView(
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Resumen")
                        .font(.headline)
                    Text("Min jugados: \(summary.minutesPlayed)")
                    Text(String(format: "Distancia: %.0f m", summary.distanceMeters))
                    Text("Goles: \(summary.goals.count)")
                    if !summary.goals.isEmpty {
                        ForEach(summary.goals) { goal in
                            Text("⚽ min \(goal.minute) (\(goal.clockTime))")
                                .font(.caption)
                        }
                    }
                    Text("Asistencias: \(summary.assists.count)")
                    if !summary.assists.isEmpty {
                        ForEach(summary.assists) { assist in
                            Text("🅰️ min \(assist.minute) (\(assist.clockTime))")
                                .font(.caption)
                        }
                    }
                    Text("Recorrido")
                        .font(.caption)
                    RouteMiniMapView(points: points)
                    if let sync = vm.syncStatusText, !sync.isEmpty {
                        Text("Sync: \(sync)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Button("Volver") {
                        vm.dismissSummaryToFinished()
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.footnote)
                }
                .font(.footnote)
                .padding()
            }
        )
    }
}
