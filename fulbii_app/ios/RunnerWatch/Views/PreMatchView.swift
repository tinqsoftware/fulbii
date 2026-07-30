import SwiftUI

struct PreMatchView: View {
    @ObservedObject var vm: MatchSessionManager
    @State private var openSettings = false
    @State private var pendingToConfirm: UpcomingMatchState?
    private let todayTitleColor = Color(red: 0.42, green: 0.95, blue: 0.58)
    private let regularTitleColor = Color(red: 0.03, green: 0.49, blue: 0.18)

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(headerText)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color.green)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let syncMessage = vm.homeSyncMessage {
                Text(syncMessage)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            TabView(selection: $vm.selectedHomeTab) {
                matchesSlide(
                    title: "Confirmados",
                    items: vm.confirmedMatches,
                    isPending: false
                ).tag(0)
                matchesSlide(
                    title: "Pendientes",
                    items: vm.pendingMatches,
                    isPending: true
                ).tag(1)
                finishedSlide(
                    title: "Terminados",
                    items: vm.finishedMatches
                ).tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))

            #if DEBUG
            Button("Debug / QA") {
                openSettings = true
            }
            .buttonStyle(.plain)
            .font(.footnote)
            .padding(.top, 2)
            #endif
        }
        .padding(.top, 0)
        .padding(.horizontal, 0)
        .sheet(isPresented: $openSettings) {
            SettingsDebugView(vm: vm)
        }
        .sheet(item: $pendingToConfirm) { match in
            confirmTeamSheet(match: match)
        }
    }

    private var headerText: String {
        let label = vm.linkedUserLabel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return label.isEmpty ? "Fulbii" : "Fulbii (\(label))"
    }

    @ViewBuilder
    private func matchesSlide(title: String, items: [UpcomingMatchState], isPending: Bool) -> some View {
        let sortedItems = items.sorted { $0.startAt < $1.startAt }
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if sortedItems.isEmpty {
                    Text(isPending ? "No tienes pichangas pendientes en los próximos 7 días." : "Sin partidos confirmados en los próximos 7 días.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(sortedItems) { match in
                        card(for: match, isPending: isPending)
                    }
                }
            }
            .padding(.horizontal, 0)
            .padding(.top, 0)
        }
    }

    @ViewBuilder
    private func finishedSlide(title: String, items: [FinishedMatchState]) -> some View {
        let sortedItems = items.sorted { $0.startAt > $1.startAt }
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if sortedItems.isEmpty {
                    Text("Aún no tienes partidos terminados.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(sortedItems) { finished in
                        finishedCard(for: finished)
                    }
                }
            }
            .padding(.horizontal, 0)
            .padding(.top, 0)
        }
    }

    @ViewBuilder
    private func card(for match: UpcomingMatchState, isPending: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            headerLine(for: match)
            Text("\(match.centerName) (Cancha \(match.fieldName))")
                .font(.caption2)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isPending {
                Button("✅ Confirmar") {
                    pendingToConfirm = match
                }
                .buttonStyle(.bordered)
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Button("Iniciar partido") {
                    vm.startMatch(match: match)
                }
                .buttonStyle(.borderedProminent)
                .font(.footnote)
                .disabled(!vm.canStart(match: match) || vm.activeSession != nil)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(4)
        .background(Color(white: 0.12).opacity(0.06))
        .cornerRadius(10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func finishedCard(for finished: FinishedMatchState) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            if Calendar.current.isDateInToday(finished.startAt) {
                Text("Hoy \(DateFormatter.watchTimeShort.string(from: finished.startAt)) (\(finished.durationMinutes) min)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(todayTitleColor)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("\(formattedDayMonthEs(finished.startAt)) \(DateFormatter.watchTimeShort.string(from: finished.startAt)) (\(finished.durationMinutes) min)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(regularTitleColor)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Text("\(finished.centerName) (Cancha \(finished.fieldName))")
                .font(.caption2)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Resumen") {
                vm.openSummary(for: finished)
            }
            .buttonStyle(.bordered)
            .font(.footnote)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(4)
        .background(Color(white: 0.12).opacity(0.06))
        .cornerRadius(10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func confirmTeamSheet(match: UpcomingMatchState) -> some View {
        let codes = normalizedTeamCodes(for: match)
        return VStack(spacing: 10) {
            Text("Elegir equipo")
                .font(.headline)
            headerLine(for: match)
            Text("\(match.centerName) (Cancha \(match.fieldName))")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            VStack(spacing: 6) {
                ForEach(codes, id: \.self) { code in
                    Button("Equipo \(code)") {
                        pendingToConfirm = nil
                        Task { await vm.confirmPendingMatch(match, teamCode: code) }
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.footnote)
                    .frame(maxWidth: .infinity)
                }
            }

            Button("Cancelar") {
                pendingToConfirm = nil
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    @ViewBuilder
    private func headerLine(for match: UpcomingMatchState) -> some View {
        if Calendar.current.isDateInToday(match.startAt) {
            Text("Hoy \(DateFormatter.watchTimeShort.string(from: match.startAt)) (\(match.durationMinutes) min)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(todayTitleColor)
                .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text("\(formattedDayMonthEs(match.startAt)) \(DateFormatter.watchTimeShort.string(from: match.startAt)) (\(match.durationMinutes) min)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(regularTitleColor)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func normalizedTeamCodes(for match: UpcomingMatchState) -> [String] {
        let codes = match.teamCodes
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
            .filter { !$0.isEmpty }
        return codes.isEmpty ? ["A", "B"] : codes
    }

    private func formattedDayMonthEs(_ date: Date) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        return "\(day)\(DateFormatter.shortMonthEs(month: month))"
    }
}

private extension DateFormatter {
    static let watchTimeShort: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static func shortMonthEs(month: Int) -> String {
        let months = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"]
        guard month >= 1, month <= 12 else { return "Ene" }
        return months[month - 1]
    }
}
