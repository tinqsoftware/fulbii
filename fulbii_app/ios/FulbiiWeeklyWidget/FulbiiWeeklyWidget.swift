import SwiftUI
import WidgetKit
#if canImport(AppIntents)
import AppIntents
#endif

private let appGroupId = "group.com.fulbii.shared"
private let weeklyPayloadKey = "fulbii_weekly_payload"
private let confirmedPayloadKey = "fulbii_confirmed_widget_payload"

private let weeklyWindowDays = 7
private let weeklyDefaultHeaderTitle = "Pichangas de la semana"
private let weeklyDefaultHeaderSubtitle = "Hoy + 6 dias"
private let defaultLoginMessage = "Inicia sesion"

private let weeklyWidgetKind = "FulbiiWeeklyWidget"
private let confirmedWidgetKind = "FulbiiConfirmedWidget"

// MARK: Weekly Widget

struct FulbiiWeeklyEntry: TimelineEntry {
    let date: Date
    let days: [FulbiiDay]
    let monthlyPlayedCount: Int
    let headerTitle: String
    let headerSubtitle: String
    let isLoggedIn: Bool
    let loginMessage: String
}

struct FulbiiDay: Codable, Hashable {
    let weekdayShort: String?
    let dayNumber: String?
    let status: String?
    let time: String?
    let pichangaId: Int?

    enum CodingKeys: String, CodingKey {
        case weekdayShort = "weekday_short"
        case dayNumber = "day_number"
        case status
        case time
        case pichangaId = "pichanga_id"
    }
}

private struct FulbiiWeeklyPayload: Codable {
    let days: [FulbiiDay]?
    let monthlyPlayedCount: Int?
    let headerTitle: String?
    let headerSubtitle: String?
    let isLoggedIn: Bool?
    let loginMessage: String?

    enum CodingKeys: String, CodingKey {
        case days
        case monthlyPlayedCount = "monthly_played_count"
        case headerTitle = "header_title"
        case headerSubtitle = "header_subtitle"
        case isLoggedIn = "is_logged_in"
        case loginMessage = "login_message"
    }
}

struct FulbiiWeeklyProvider: TimelineProvider {
    func placeholder(in context: Context) -> FulbiiWeeklyEntry {
        fallbackEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (FulbiiWeeklyEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FulbiiWeeklyEntry>) -> Void) {
        let entry = loadEntry()
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func loadEntry() -> FulbiiWeeklyEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        guard
            let raw = defaults?.string(forKey: weeklyPayloadKey),
            let data = raw.data(using: .utf8),
            let payload = try? JSONDecoder().decode(FulbiiWeeklyPayload.self, from: data)
        else {
            return fallbackEntry()
        }

        let days = sanitize(days: payload.days ?? [])
        return FulbiiWeeklyEntry(
            date: Date(),
            days: days,
            monthlyPlayedCount: max(0, payload.monthlyPlayedCount ?? 0),
            headerTitle: payload.headerTitle?.nonEmpty ?? weeklyDefaultHeaderTitle,
            headerSubtitle: payload.headerSubtitle?.nonEmpty ?? weeklyDefaultHeaderSubtitle,
            isLoggedIn: payload.isLoggedIn ?? true,
            loginMessage: payload.loginMessage?.nonEmpty ?? defaultLoginMessage
        )
    }

    private func fallbackEntry() -> FulbiiWeeklyEntry {
        FulbiiWeeklyEntry(
            date: Date(),
            days: placeholderDays,
            monthlyPlayedCount: 0,
            headerTitle: weeklyDefaultHeaderTitle,
            headerSubtitle: weeklyDefaultHeaderSubtitle,
            isLoggedIn: true,
            loginMessage: defaultLoginMessage
        )
    }

    private func sanitize(days: [FulbiiDay]) -> [FulbiiDay] {
        if days.count >= weeklyWindowDays {
            return Array(days.prefix(weeklyWindowDays))
        }

        if days.isEmpty {
            return placeholderDays
        }

        var copy = days
        while copy.count < weeklyWindowDays {
            copy.append(placeholderDays[copy.count])
        }
        return copy
    }

    private var placeholderDays: [FulbiiDay] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        return (0..<weeklyWindowDays).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: start) ?? start
            let day = calendar.component(.day, from: date)
            return FulbiiDay(
                weekdayShort: nil,
                dayNumber: String(day),
                status: "neutral",
                time: nil,
                pichangaId: nil
            )
        }
    }
}

struct FulbiiWeeklyWidgetEntryView: View {
    var entry: FulbiiWeeklyProvider.Entry

    private let rootURL = URL(string: "fulbii://pichangas")

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Text("\(entry.monthlyPlayedCount) pichangas jugadas este mes")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                Spacer(minLength: 0)
                Image("WidgetLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)
            }

            Text(entry.headerTitle)
                .font(.subheadline)
                .fontWeight(.bold)

            Text(entry.headerSubtitle)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.75))

            if entry.isLoggedIn {
                HStack(spacing: 4) {
                    ForEach(Array(entry.days.enumerated()), id: \.offset) { index, day in
                        weeklyDayItem(day: day, index: index)
                    }
                }
            } else {
                Text(entry.loginMessage)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .padding(.top, 6)
            }
        }
        .padding(12)
        .widgetURL(rootURL)
        .modifier(FulbiiWidgetBackgroundModifier())
        .foregroundColor(.white)
    }

    @ViewBuilder
    private func weeklyDayItem(day: FulbiiDay, index: Int) -> some View {
        let finalDay = (day.dayNumber?.isEmpty == false) ? day.dayNumber! : String(index + 1)
        let finalTime = (day.time?.isEmpty == false) ? day.time! : ""

        let content = VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(statusColor(day.status))
                    .frame(width: 24, height: 24)
                Text(finalDay)
                    .font(.caption2)
                    .fontWeight(.bold)
            }
            Text(finalTime)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.9))
                .frame(height: 10)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)

        content
    }

    private func statusColor(_ status: String?) -> Color {
        switch status?.lowercased() {
        case "green":
            return Color(red: 0.13, green: 0.77, blue: 0.37)
        case "yellow":
            return Color(red: 0.98, green: 0.80, blue: 0.08)
        default:
            return Color(red: 0.31, green: 0.37, blue: 0.33)
        }
    }
}

struct FulbiiWeeklyWidget: Widget {
    let kind: String = weeklyWidgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FulbiiWeeklyProvider()) { entry in
            FulbiiWeeklyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Pichangas de la semana")
        .description("Widget mediano con 7 dias y su hora pendiente.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: Confirmed Widget

struct FulbiiConfirmedEntry: TimelineEntry {
    let date: Date
    let isLoggedIn: Bool
    let loginMessage: String
    let items: [FulbiiConfirmedItem]
    let selectedPichangaId: Int?
}

struct FulbiiConfirmedItem: Codable, Hashable, Identifiable {
    let id: Int
    let title: String?
    let dateLabel: String?
    let timeLabel: String?
    let startsLabel: String?
    let formatLabel: String?
    let teamCount: Int?
    let teams: [FulbiiConfirmedTeam]?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case dateLabel = "date_label"
        case timeLabel = "time_label"
        case startsLabel = "starts_label"
        case formatLabel = "format_label"
        case teamCount = "team_count"
        case teams
    }
}

struct FulbiiConfirmedTeam: Codable, Hashable {
    let code: String?
    let avgRating: Double?
    let slots: [FulbiiConfirmedSlot]?

    enum CodingKeys: String, CodingKey {
        case code
        case avgRating = "avg_rating"
        case slots
    }
}

struct FulbiiConfirmedSlot: Codable, Hashable {
    let slot: Int?
    let displayName: String?
    let user: FulbiiConfirmedUser?

    enum CodingKeys: String, CodingKey {
        case slot
        case displayName = "display_name"
        case user
    }
}

struct FulbiiConfirmedUser: Codable, Hashable {
    let name: String?
    let nick: String?
    let isMe: Bool?

    enum CodingKeys: String, CodingKey {
        case name
        case nick
        case isMe = "is_me"
    }
}

private struct FulbiiConfirmedPayload: Codable {
    let isLoggedIn: Bool?
    let loginMessage: String?
    let selectedPichangaId: Int?
    let items: [FulbiiConfirmedItem]?

    enum CodingKeys: String, CodingKey {
        case isLoggedIn = "is_logged_in"
        case loginMessage = "login_message"
        case selectedPichangaId = "selected_pichanga_id"
        case items
    }
}

struct FulbiiConfirmedProvider: TimelineProvider {
    func placeholder(in context: Context) -> FulbiiConfirmedEntry {
        fallbackEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (FulbiiConfirmedEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FulbiiConfirmedEntry>) -> Void) {
        let entry = loadEntry()
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func loadEntry() -> FulbiiConfirmedEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        guard
            let raw = defaults?.string(forKey: confirmedPayloadKey),
            let data = raw.data(using: .utf8),
            let payload = try? JSONDecoder().decode(FulbiiConfirmedPayload.self, from: data)
        else {
            return fallbackEntry()
        }

        let items = Array((payload.items ?? []).prefix(3))
        let selected = resolveSelectedId(items: items, selectedId: payload.selectedPichangaId)
        return FulbiiConfirmedEntry(
            date: Date(),
            isLoggedIn: payload.isLoggedIn ?? true,
            loginMessage: payload.loginMessage?.nonEmpty ?? defaultLoginMessage,
            items: items,
            selectedPichangaId: selected
        )
    }

    private func fallbackEntry() -> FulbiiConfirmedEntry {
        FulbiiConfirmedEntry(
            date: Date(),
            isLoggedIn: true,
            loginMessage: defaultLoginMessage,
            items: [],
            selectedPichangaId: nil
        )
    }

    private func resolveSelectedId(items: [FulbiiConfirmedItem], selectedId: Int?) -> Int? {
        if let selectedId, items.contains(where: { $0.id == selectedId }) {
            return selectedId
        }
        return items.first?.id
    }
}

struct FulbiiConfirmedWidgetEntryView: View {
    var entry: FulbiiConfirmedProvider.Entry

    private var selectedItem: FulbiiConfirmedItem? {
        guard !entry.items.isEmpty else {
            return nil
        }
        if let selectedId = entry.selectedPichangaId {
            return entry.items.first(where: { $0.id == selectedId }) ?? entry.items.first
        }
        return entry.items.first
    }

    private var rootURL: URL? {
        if let selectedId = selectedItem?.id {
            return URL(string: "fulbii://pichanga/\(selectedId)")
        }
        return URL(string: "fulbii://home")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pichangas")
                .font(.title3)
                .fontWeight(.bold)

            if entry.isLoggedIn {
                if entry.items.isEmpty {
                    Text("Sin pichangas confirmadas")
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.85))
                } else {
                    confirmedChipsRow

                    Text("Confirmados")
                        .font(.headline)
                        .fontWeight(.bold)

                    confirmedTeamsRow

                    Spacer(minLength: 0)

                    if let selected = selectedItem {
                        HStack(spacing: 8) {
                            Spacer()
                            Link(destination: URL(string: "fulbii://widget/confirmed/share-lineup?id=\(selected.id)")!) {
                                buttonPill(text: "Canchita")
                            }
                            Link(destination: URL(string: "fulbii://widget/confirmed/share-link?id=\(selected.id)")!) {
                                buttonPill(text: "Compartir")
                            }
                        }
                    }
                }
            } else {
                Spacer(minLength: 0)
                Text(entry.loginMessage)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer(minLength: 0)
            }
        }
        .padding(10)
        .widgetURL(rootURL)
        .foregroundColor(.white)
        .modifier(FulbiiWidgetBackgroundModifier())
    }

    private var confirmedChipsRow: some View {
        HStack(spacing: 5) {
            ForEach(entry.items, id: \.id) { item in
                confirmedChip(item: item)
            }
        }
    }

    @ViewBuilder
    private func confirmedChip(item: FulbiiConfirmedItem) -> some View {
        let selected = item.id == entry.selectedPichangaId
        let chipContent = VStack(alignment: .leading, spacing: 2) {
            Text(item.dateLabel?.nonEmpty ?? item.startsLabel?.nonEmpty ?? "-")
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)
            Text(item.timeLabel?.nonEmpty ?? "--:--")
                .font(.caption)
                .fontWeight(.bold)
                .lineLimit(1)
            Text(item.formatLabel?.nonEmpty ?? "-")
                .font(.caption2)
                .lineLimit(1)
        }
        .foregroundColor(selected ? .white : Color(red: 0.90, green: 0.95, blue: 0.92))
        .padding(.horizontal, 6)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(selected ? Color(red: 0.13, green: 0.55, blue: 0.29) : Color(red: 0.12, green: 0.14, blue: 0.13))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(red: 0.16, green: 0.23, blue: 0.20), lineWidth: selected ? 0 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))

        if #available(iOSApplicationExtension 17.0, *) {
            Button(intent: SelectConfirmedPichangaIntent(pichangaId: item.id)) {
                chipContent
            }
            .buttonStyle(.plain)
        } else {
            Link(destination: URL(string: "fulbii://widget/confirmed/select?id=\(item.id)")!) {
                chipContent
            }
            .buttonStyle(.plain)
        }
    }

    private var confirmedTeamsRow: some View {
        let teams = Array((selectedItem?.teams ?? []).prefix(4))

        return HStack(alignment: .top, spacing: 8) {
            ForEach(Array(teams.enumerated()), id: \.offset) { _, team in
                VStack(alignment: .leading, spacing: 3) {
                    Text(teamTitle(team))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    let names = playerNames(team)
                    if names.isEmpty {
                        Text("- Sin confirmados")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.82))
                    } else {
                        ForEach(Array(names.enumerated()), id: \.offset) { index, name in
                            Text("\(index + 1). \(name)")
                                .font(.caption2)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func buttonPill(text: String) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.35))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.75), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func teamTitle(_ team: FulbiiConfirmedTeam) -> String {
        let code = team.code?.nonEmpty ?? "-"
        let rating = team.avgRating.map { String(format: "%.1f", $0) } ?? "-"
        return "\(code) (★\(rating))"
    }

    private func playerNames(_ team: FulbiiConfirmedTeam) -> [String] {
        (team.slots ?? []).compactMap { slot in
            let direct = slot.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !direct.isEmpty {
                return direct
            }

            let nick = slot.user?.nick?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !nick.isEmpty {
                return nick
            }

            let name = slot.user?.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return name.isEmpty ? nil : name
        }
    }
}

struct FulbiiConfirmedWidget: Widget {
    let kind: String = confirmedWidgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FulbiiConfirmedProvider()) { entry in
            FulbiiConfirmedWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Pichangas confirmadas")
        .description("Muestra 3 proximas pichangas confirmadas con equipos y compartir.")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: Shared helpers

private struct FulbiiWidgetBackgroundModifier: ViewModifier {
    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.07, blue: 0.07),
                    Color(red: 0.05, green: 0.09, blue: 0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(red: 0.16, green: 0.62, blue: 0.34).opacity(0.25))
                .frame(width: 140, height: 140)
                .offset(x: 108, y: -68)

            Circle()
                .fill(Color(red: 0.12, green: 0.45, blue: 0.25).opacity(0.22))
                .frame(width: 120, height: 120)
                .offset(x: -95, y: 70)
        }
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            content.containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            content.background(backgroundView)
        }
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}

#if canImport(AppIntents)
@available(iOSApplicationExtension 17.0, *)
struct SelectConfirmedPichangaIntent: AppIntent {
    static var title: LocalizedStringResource = "Seleccionar pichanga"

    @Parameter(title: "Pichanga ID")
    var pichangaId: Int

    init() {
        self.pichangaId = 0
    }

    init(pichangaId: Int) {
        self.pichangaId = pichangaId
    }

    func perform() async throws -> some IntentResult {
        persistConfirmedSelection(pichangaId)
        WidgetCenter.shared.reloadTimelines(ofKind: confirmedWidgetKind)
        return .result()
    }
}

private func persistConfirmedSelection(_ pichangaId: Int) {
    guard pichangaId > 0 else {
        return
    }
    guard let defaults = UserDefaults(suiteName: appGroupId) else {
        return
    }
    guard let raw = defaults.string(forKey: confirmedPayloadKey), let data = raw.data(using: .utf8) else {
        return
    }
    guard
        var json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
        let items = json["items"] as? [[String: Any]]
    else {
        return
    }

    let exists = items.contains { item in
        (item["id"] as? Int) == pichangaId
    }
    guard exists else {
        return
    }

    json["selected_pichanga_id"] = pichangaId

    guard let updatedData = try? JSONSerialization.data(withJSONObject: json),
          let updatedRaw = String(data: updatedData, encoding: .utf8)
    else {
        return
    }

    defaults.set(updatedRaw, forKey: confirmedPayloadKey)
}
#endif

@main
struct FulbiiWidgetsBundle: WidgetBundle {
    var body: some Widget {
        FulbiiWeeklyWidget()
        FulbiiConfirmedWidget()
    }
}
