import Foundation

#if canImport(WatchKit)
import WatchKit
#endif

@MainActor
final class MatchSessionManager: ObservableObject {
    @Published var selectedField: Field
    @Published var selectedGeometry: FieldGeometry?
    @Published var activeSession: MatchSession?
    @Published var latestSummary: MatchSummary?
    @Published var confirmationText: String?
    @Published var transientBannerText: String?
    @Published var assistanceEnabled = true
    @Published var confirmedMatches: [UpcomingMatchState] = []
    @Published var pendingMatches: [UpcomingMatchState] = []
    @Published var finishedMatches: [FinishedMatchState] = []
    @Published var linkedUserId: Int?
    @Published var linkedUserLabel: String?
    @Published var linkedAuthTokenAvailable = false
    @Published var homeSyncMessage: String?
    @Published var selectedHomeTab = 0
    @Published var syncStatusText: String?

    private let locationManager: LocationCaptureManager
    private let workoutManager: WorkoutManager
    private let syncManager: WatchSyncManager
    private let store: LocalStore
    private var timer: Timer?
    private var clockTimer: Timer?
    private var lastMovementAt: Date?
    private var now = Date()
    private var bannerTask: Task<Void, Never>?
    private var lastBannerKey: String?
    private var lastBannerAt: Date?
    private var linkedAuthToken = ""
    private var linkedApiBaseUrl = ""
    private var isRefreshingFeed = false
    private var lastFeedRefreshAt: Date?
    private var hasBridgeContextInCurrentVisibility = false
    private var syncTimeoutTask: Task<Void, Never>?
    private var lastFeedErrorKey: String?
    private var lastFeedErrorAt: Date?
    private var postContextRefreshTask: Task<Void, Never>?
    private var lastPostContextRefreshAt: Date?
    private var optimisticConfirmedIds: [Int: Date] = [:]
    private let optimisticTTLSeconds: TimeInterval = 90
    private var locallyFinishedPichangaIds: Set<Int> = []
    private var trackingEngine = TrackingEngine()
    private var isLinked: Bool {
        hasBridgeContextInCurrentVisibility || linkedAuthTokenAvailable || linkedUserId != nil
    }

    init() {
        let store = LocalStore()
        self.store = store
        self.locationManager = LocationCaptureManager()
        self.workoutManager = WorkoutManager()
        self.syncManager = WatchSyncManager(store: store)

        selectedField = Field(id: 1, name: "Cancha", centerLat: -12.0464, centerLng: -77.0428)
        selectedGeometry = FieldGeometry(fieldId: 1, widthMeters: 30, lengthMeters: 50, rotationDegrees: 0, corners: nil)
        syncManager.onContextUpdated = { [weak self] context in
            Task { @MainActor in
                self?.applyBridgeContext(context)
            }
        }
        syncManager.onSyncStatus = { [weak self] status in
            Task { @MainActor in
                self?.syncStatusText = status
            }
        }
        loadFinishedMatchesFromStore()
        locationManager.requestPermission()
        startClockTimer()
    }

    func onAppVisible() {
        hasBridgeContextInCurrentVisibility = false
        syncManager.requestLatestContext(reason: "app_visible")
        updateHomeSyncMessage(syncing: true)
        scheduleSyncTimeoutHint()
        Task { @MainActor in
            await refreshMatchesFromBackend(force: true, reason: "app_visible")
        }
    }

    var activeOrUpcomingMatch: UpcomingMatchState? {
        let sorted = confirmedMatches.sorted { $0.startAt < $1.startAt }
        if let active = sorted.first(where: { $0.isStartWindowOpen(now: now) }) {
            return active
        }
        return sorted.first
    }

    var canStartMatch: Bool {
        guard let match = activeOrUpcomingMatch else { return false }
        return match.isStartWindowOpen(now: now)
    }

    var preMatchStatusText: String {
        guard let match = activeOrUpcomingMatch else {
            return "Sin partido activo"
        }
        return startAvailabilityText(for: match)
    }

    func canStart(match: UpcomingMatchState) -> Bool {
        match.isStartWindowOpen(now: now)
    }

    func startAvailabilityText(for match: UpcomingMatchState) -> String {
        if match.isStartWindowOpen(now: now) {
            return "Listo para iniciar"
        }
        if now > match.endAt {
            return "Partido finalizado"
        }
        let delta = max(0, Int(match.startAt.timeIntervalSince(now)))
        let minutes = max(1, delta / 60)
        if minutes >= 60 * 48 {
            let days = max(1, Int(ceil(Double(minutes) / (60.0 * 24.0))))
            return "En \(days) día\(days == 1 ? "" : "s")"
        }
        if minutes >= 60 {
            let hours = max(1, Int(ceil(Double(minutes) / 60.0)))
            return "En \(hours) hora\(hours == 1 ? "" : "s")"
        }
        return "En \(minutes) min"
    }

    var elapsedSeconds: Int {
        guard let session = activeSession else { return 0 }
        let end = session.endTime ?? Date()
        return max(0, Int(end.timeIntervalSince(session.startTime)))
    }

    var elapsedLabel: String {
        let secs = elapsedSeconds
        return String(format: "%02d:%02d", secs / 60, secs % 60)
    }

    var distanceLabel: String {
        let filtered = activeSession?.distanceMetersFiltered
        let raw = activeSession?.distanceMetersRaw ?? activeSession?.distanceMeters
        let meters: Double
        if let filtered, let raw, filtered <= 1, raw > 5 {
            meters = raw
        } else {
            meters = filtered ?? raw ?? 0
        }
        if meters >= 1000 {
            return String(format: "%.2f km", meters / 1000)
        }
        return String(format: "%.0f m", meters)
    }

    var gpsStatus: String {
        locationManager.gpsStatus
    }

    func startMatch() {
        guard let match = activeOrUpcomingMatch else { return }
        startMatch(match: match)
    }

    func startMatch(match: UpcomingMatchState) {
        guard activeSession == nil else { return }
        guard canStart(match: match) else { return }
        guard match.id > 0 else {
            showTransientBanner("Pichanga inválida para iniciar")
            return
        }

        var session = MatchSession(
            userId: linkedUserId ?? 1,
            groupPichangaId: match.id,
            fieldId: match.fieldId,
            fieldGeometryId: selectedGeometry?.id,
            status: .live,
            startTime: Date()
        )
        session.sideInfo = "unknown"
        session.distanceMetersRaw = 0
        session.distanceMetersFiltered = 0
        session.distanceMeters = 0
        trackingEngine.reset()
        activeSession = session
        lastMovementAt = Date()
        workoutManager.startWorkoutIfPossible()
        locationManager.start { [weak self] sample in
            Task { @MainActor in
                self?.appendSample(sample)
            }
        }
        startTimer()
        playHaptic(.start)
        showTransientBanner("Partido iniciado")
    }

    func pauseOrResume() {
        guard var session = activeSession else { return }
        if session.status == .paused {
            session.status = .live
            addEvent(.resume)
        } else if session.status == .live {
            session.status = .paused
            addEvent(.pause)
        }
        activeSession = session
    }

    func registerGoal() {
        addEvent(.goal)
        playHaptic(.success)
    }

    func registerAssist() {
        addEvent(.assist)
    }

    func confirmPendingMatch(_ match: UpcomingMatchState, teamCode: String) async {
        let token = linkedAuthToken.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = linkedApiBaseUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else {
            showTransientBanner("Sin sesión iPhone")
            return
        }
        guard !base.isEmpty else {
            showTransientBanner("Sin API configurada")
            return
        }
        guard let url = URL(string: "\(base.trimmingCharacters(in: CharacterSet(charactersIn: "/")))/pichangas/\(match.id)/confirm") else {
            showTransientBanner("URL inválida")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["team_code": teamCode])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                showTransientBanner("Sin respuesta servidor")
                return
            }
        if (200..<300).contains(http.statusCode) {
            pruneOptimisticConfirmed()
            optimisticConfirmedIds[match.id] = Date()
            pendingMatches.removeAll { $0.id == match.id }
            if !confirmedMatches.contains(where: { $0.id == match.id }) {
                let confirmedMatch = UpcomingMatchState(
                    id: match.id,
                    title: match.title,
                    centerName: match.centerName,
                    fieldId: match.fieldId,
                    fieldName: match.fieldName,
                    startAt: match.startAt,
                    durationMinutes: match.durationMinutes,
                    teamCodes: match.teamCodes,
                    status: "confirmed"
                )
                confirmedMatches.append(confirmedMatch)
                confirmedMatches.sort { $0.startAt < $1.startAt }
            }
            showTransientBanner("Confirmado equipo \(teamCode)")
            await refreshMatchesFromBackend(force: true, reason: "confirm_success")
            return
        }

            let message = parseServerMessage(data: data) ?? "Error \(http.statusCode)"
            showTransientBanner(message)
        } catch {
            showTransientBanner("Sin conexión")
        }
    }

    func finishMatch(autoFinished: Bool = false) {
        guard var session = activeSession else { return }
        let finishedMatch = currentMatchForActiveSession()
        if let pichangaId = session.groupPichangaId {
            locallyFinishedPichangaIds.insert(pichangaId)
            confirmedMatches.removeAll { $0.id == pichangaId }
            pendingMatches.removeAll { $0.id == pichangaId }
        }
        session.endTime = Date()
        session.status = autoFinished ? .autoFinished : .finished
        if session.distanceMetersFiltered == nil {
            session.distanceMetersFiltered = session.distanceMeters
        }
        if session.distanceMetersRaw == nil {
            session.distanceMetersRaw = session.distanceMeters
        }
        session.distanceMeters = session.distanceMetersFiltered ?? session.distanceMeters
        activeSession = session
        finalizeSession(session, finishedMatch: finishedMatch)
        activeSession = nil
        stopRealtimeCapture()
        playHaptic(.stop)
        selectedHomeTab = 2
    }

    func simulateThirtyMinutes() {
        guard let simulatedPichangaId = activeOrUpcomingMatch?.id, simulatedPichangaId > 0 else {
            showTransientBanner("Sin pichanga válida para simular")
            return
        }
        let now = Date()
        let start = now.addingTimeInterval(-1800)
        var samples: [PositionSample] = []
        for idx in 0..<180 {
            let ratio = Double(idx) / 179.0
            let trackX = sin(ratio * 12) * 0.00022
            let trackY = cos(ratio * 12) * 0.00012
            let lat = selectedField.centerLat + trackY
            let lng = selectedField.centerLng + trackX
            samples.append(PositionSample(
                timestamp: start.addingTimeInterval(Double(idx) * 10),
                lat: lat,
                lng: lng,
                horizontalAccuracy: 8,
                speed: 2.4
            ))
        }

        let goals = [
            MatchEvent(type: .goal, timestamp: start.addingTimeInterval(480), minute: 9, clockTime: "16:08"),
            MatchEvent(type: .goal, timestamp: start.addingTimeInterval(1320), minute: 23, clockTime: "16:22"),
            MatchEvent(type: .assist, timestamp: start.addingTimeInterval(960), minute: 17, clockTime: "16:16")
        ]

        var session = MatchSession(
            userId: linkedUserId ?? 1,
            groupPichangaId: simulatedPichangaId,
            fieldId: selectedField.id,
            fieldGeometryId: selectedGeometry?.id,
            status: .finished,
            startTime: start,
            endTime: now
        )
        session.samples = samples
        session.events = goals
        let estimated = estimateDistance(samples: samples)
        session.distanceMetersRaw = estimated
        session.distanceMetersFiltered = estimated
        session.distanceMeters = estimated
        finalizeSession(session, finishedMatch: nil)
        showTransientBanner("Simulación 30 min lista")
    }

    func clearConfirmation() {
        confirmationText = nil
    }

    func dismissSummaryToFinished() {
        latestSummary = nil
        selectedHomeTab = 2
    }

    func openSummary(for finished: FinishedMatchState) {
        latestSummary = finished.summary
    }

    private func appendSample(_ sample: PositionSample) {
        guard var session = activeSession, session.status == .live else { return }
        let output = trackingEngine.consume(sample: sample)
        let enrichedSample = PositionSample(
            id: sample.id,
            timestamp: sample.timestamp,
            lat: sample.lat,
            lng: sample.lng,
            horizontalAccuracy: sample.horizontalAccuracy,
            speed: sample.speed,
            qualityFlag: output.qualityFlag
        )
        session.samples.append(enrichedSample)
        let rawDistance = (session.distanceMetersRaw ?? session.distanceMeters) + output.deltaMetersRaw
        let filteredDistance = (session.distanceMetersFiltered ?? session.distanceMeters) + output.deltaMetersFiltered
        session.distanceMetersRaw = rawDistance
        session.distanceMetersFiltered = filteredDistance
        session.distanceMeters = filteredDistance
        if output.deltaMetersFiltered >= 3 || output.isMovementDetected {
            lastMovementAt = Date()
        }
        activeSession = session
    }

    private func addEvent(_ type: MatchEventType) {
        guard var session = activeSession else { return }
        let now = Date()
        let minute = max(1, Int(floor(now.timeIntervalSince(session.startTime) / 60)) + 1)
        let clock = DateFormatter.watchClock.string(from: now)
        let event = MatchEvent(type: type, timestamp: now, minute: minute, clockTime: clock)
        session.events.append(event)
        activeSession = session
        switch type {
        case .goal:
            confirmationText = "Gol min \(minute)"
        case .assist:
            confirmationText = "Asistencia min \(minute)"
        case .pause:
            confirmationText = "Partido en pausa"
        case .resume:
            confirmationText = "Partido reanudado"
        case .sideChange:
            confirmationText = "Cambio de lado"
        }
        if let confirmationText {
            showTransientBanner(confirmationText)
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        now = Date()
        objectWillChange.send()
        guard activeSession != nil else { return }
        if let lastMovementAt, Date().timeIntervalSince(lastMovementAt) >= 1800 {
            finishMatch(autoFinished: true)
        }
    }

    private func startClockTimer() {
        clockTimer?.invalidate()
        clockTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.now = Date()
                self?.objectWillChange.send()
            }
        }
    }

    private func stopRealtimeCapture() {
        timer?.invalidate()
        timer = nil
        locationManager.stop()
        workoutManager.endWorkout()
    }

    private func finalizeSession(_ session: MatchSession, finishedMatch: UpcomingMatchState?) {
        store.save(session: session)
        let filteredDistance = session.distanceMetersFiltered ?? session.distanceMeters
        let rawDistance = session.distanceMetersRaw ?? session.distanceMeters
        let displayDistance = (filteredDistance <= 1 && rawDistance > 5) ? rawDistance : filteredDistance
        let summary = MatchSummary(
            sourceSessionId: session.id,
            minutesPlayed: max(1, Int((session.endTime ?? Date()).timeIntervalSince(session.startTime) / 60)),
            distanceMeters: displayDistance,
            goals: session.events.filter { $0.type == .goal },
            assists: session.events.filter { $0.type == .assist },
            samples: acceptedSamplesForHeatmap(from: session.samples)
        )
        latestSummary = summary
        if let finished = buildFinishedState(session: session, summary: summary, match: finishedMatch) {
            upsertFinishedMatch(finished)
        }
        syncManager.queueSessionForSync(session)
    }

    private func applyBridgeContext(_ context: WatchBridgeContext) {
        pruneOptimisticConfirmed()
        hasBridgeContextInCurrentVisibility = true
        linkedUserId = context.userId
        linkedUserLabel = (context.userNick?.isEmpty == false ? context.userNick : context.userName)
        linkedAuthTokenAvailable = context.hasAuthToken
        linkedAuthToken = context.authToken
        linkedApiBaseUrl = context.apiBaseUrl ?? ""
        let optimisticIds = Set(optimisticConfirmedIds.keys)

        var mergedConfirmedById: [Int: UpcomingMatchState] = [:]
        let confirmedSource = context.confirmedMatches.isEmpty ? confirmedMatches : context.confirmedMatches
        for match in confirmedSource {
            mergedConfirmedById[match.id] = match
        }
        for match in confirmedMatches where optimisticIds.contains(match.id) {
            mergedConfirmedById[match.id] = mergedConfirmedById[match.id] ?? match
        }
        let baseConfirmed = Array(mergedConfirmedById.values).sorted { $0.startAt < $1.startAt }

        var mergedPendingById: [Int: UpcomingMatchState] = [:]
        let pendingSource = context.pendingMatches.isEmpty ? pendingMatches : context.pendingMatches
        for match in pendingSource {
            mergedPendingById[match.id] = match
        }
        for id in optimisticIds {
            mergedPendingById.removeValue(forKey: id)
        }
        var mergedPending = Array(mergedPendingById.values).sorted { $0.startAt < $1.startAt }
        if !locallyFinishedPichangaIds.isEmpty {
            mergedPending.removeAll { locallyFinishedPichangaIds.contains($0.id) }
        }
        var mergedConfirmed = baseConfirmed
        if !locallyFinishedPichangaIds.isEmpty {
            mergedConfirmed.removeAll { locallyFinishedPichangaIds.contains($0.id) }
        }
        mergedConfirmed = mergedConfirmed.filter { isStillRelevant($0, now: now) }
        mergedPending = mergedPending.filter { isStillRelevant($0, now: now) }

        confirmedMatches = mergedConfirmed
        pendingMatches = mergedPending
        for match in mergedConfirmed where optimisticIds.contains(match.id) {
            optimisticConfirmedIds.removeValue(forKey: match.id)
        }
        print("[WatchBridge] Received context user_id=\(context.userId ?? -1) has_token=\(context.hasAuthToken) confirmed=\(context.confirmedMatches.count) pending=\(context.pendingMatches.count)")
        updateHomeSyncMessage(syncing: false)
        schedulePostContextRefreshIfNeeded()
    }

    private func schedulePostContextRefreshIfNeeded() {
        if let task = postContextRefreshTask, !task.isCancelled {
            return
        }
        if let lastPostContextRefreshAt, Date().timeIntervalSince(lastPostContextRefreshAt) < 5 {
            return
        }
        lastPostContextRefreshAt = Date()
        postContextRefreshTask = Task { @MainActor in
            defer { postContextRefreshTask = nil }
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            let shouldForce = confirmedMatches.isEmpty && pendingMatches.isEmpty
            await refreshMatchesFromBackend(force: shouldForce, reason: "post_context")
        }
    }

    private func refreshMatchesFromBackend(force: Bool, reason: String) async {
        pruneOptimisticConfirmed()
        let token = linkedAuthToken.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = linkedApiBaseUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty, !base.isEmpty else {
            return
        }

        let bypassThrottle = force || reason == "confirm_success" || reason == "manual_user_action"
        if !bypassThrottle, let lastFeedRefreshAt, Date().timeIntervalSince(lastFeedRefreshAt) < 20 {
            return
        }
        guard !isRefreshingFeed else { return }
        isRefreshingFeed = true
        defer { isRefreshingFeed = false }

        let trimmedBase = base.hasSuffix("/") ? String(base.dropLast()) : base
        guard var feedComponents = URLComponents(string: "\(trimmedBase)/watch/pichangas/home-feed") else {
            return
        }
        feedComponents.queryItems = [URLQueryItem(name: "days", value: "7")]
        guard let feedURL = feedComponents.url else { return }
        guard var availableComponents = URLComponents(string: "\(trimmedBase)/pichangas/available") else {
            return
        }
        availableComponents.queryItems = [URLQueryItem(name: "days", value: "7")]
        guard let availableURL = availableComponents.url else { return }

        var feedRequest = URLRequest(url: feedURL)
        feedRequest.httpMethod = "GET"
        feedRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        feedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var availableRequest = URLRequest(url: availableURL)
        availableRequest.httpMethod = "GET"
        availableRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        availableRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var refreshedConfirmed = confirmedMatches
        var refreshedPending = pendingMatches

        do {
            let (feedData, feedResponse) = try await URLSession.shared.data(for: feedRequest)
            guard let http = feedResponse as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
                logFeedIssue("home-feed failed reason=\(reason)")
                return
            }
            guard let feedJSON = try JSONSerialization.jsonObject(with: feedData) as? [String: Any] else {
                return
            }

            if let user = feedJSON["user"] as? [String: Any] {
                if let userId = parseInt(user["id"]) {
                    linkedUserId = userId
                }
                let nick = parseString(user["nick"])
                let name = parseString(user["name"])
                if let label = nick ?? name, !label.isEmpty {
                    linkedUserLabel = label
                }
            }

            refreshedConfirmed = parseMatches(from: feedJSON["confirmed_matches"] as? [[String: Any]])

            let (availableData, availableResponse) = try await URLSession.shared.data(for: availableRequest)
            if let availableHTTP = availableResponse as? HTTPURLResponse, (200 ..< 300).contains(availableHTTP.statusCode),
               let availableJSON = try JSONSerialization.jsonObject(with: availableData) as? [String: Any] {
                let availableItems = parseMatches(from: availableJSON["items"] as? [[String: Any]])
                let confirmedIds = Set(refreshedConfirmed.map(\.id))
                refreshedPending = availableItems.filter { item in
                    let status = (item.status ?? "").lowercased()
                    return status != "confirmed" && !confirmedIds.contains(item.id)
                }
            } else {
                logFeedIssue("available failed reason=\(reason)")
            }

            let optimisticIds = Set(optimisticConfirmedIds.keys)
            var mergedConfirmedById: [Int: UpcomingMatchState] = [:]
            for match in refreshedConfirmed {
                mergedConfirmedById[match.id] = match
            }
            for match in confirmedMatches where optimisticIds.contains(match.id) {
                mergedConfirmedById[match.id] = mergedConfirmedById[match.id] ?? match
            }
            let baseFinalConfirmed = Array(mergedConfirmedById.values).sorted { $0.startAt < $1.startAt }

            var mergedPendingById: [Int: UpcomingMatchState] = [:]
            for match in refreshedPending {
                mergedPendingById[match.id] = match
            }
            for id in optimisticIds {
                mergedPendingById.removeValue(forKey: id)
            }
            let baseFinalPending = Array(mergedPendingById.values).sorted { $0.startAt < $1.startAt }
            var finalConfirmed = baseFinalConfirmed
            var finalPending = baseFinalPending
            if !locallyFinishedPichangaIds.isEmpty {
                finalConfirmed.removeAll { locallyFinishedPichangaIds.contains($0.id) }
                finalPending.removeAll { locallyFinishedPichangaIds.contains($0.id) }
            }
            finalConfirmed = finalConfirmed.filter { isStillRelevant($0, now: now) }
            finalPending = finalPending.filter { isStillRelevant($0, now: now) }

            confirmedMatches = finalConfirmed
            pendingMatches = finalPending
            for match in finalConfirmed where optimisticIds.contains(match.id) {
                optimisticConfirmedIds.removeValue(forKey: match.id)
            }
            lastFeedRefreshAt = Date()
            updateHomeSyncMessage(syncing: false)
            print("[WatchBridge] home-feed success reason=\(reason) confirmed=\(finalConfirmed.count) pending=\(finalPending.count)")
        } catch is CancellationError {
            return
        } catch {
            updateHomeSyncMessage(syncing: false)
            logFeedIssue("home-feed error reason=\(reason) \(error.localizedDescription)")
        }
    }

    private func pruneOptimisticConfirmed() {
        guard !optimisticConfirmedIds.isEmpty else { return }
        let now = Date()
        optimisticConfirmedIds = optimisticConfirmedIds.filter { _, timestamp in
            now.timeIntervalSince(timestamp) < optimisticTTLSeconds
        }
    }

    private func currentMatchForActiveSession() -> UpcomingMatchState? {
        guard let session = activeSession, let pichangaId = session.groupPichangaId else {
            return nil
        }
        if let found = confirmedMatches.first(where: { $0.id == pichangaId }) {
            return found
        }
        return pendingMatches.first(where: { $0.id == pichangaId })
    }

    private func buildFinishedState(
        session: MatchSession,
        summary: MatchSummary,
        match: UpcomingMatchState?
    ) -> FinishedMatchState? {
        guard let endTime = session.endTime else { return nil }
        let durationMinutes = max(1, Int(endTime.timeIntervalSince(session.startTime) / 60))
        let centerName = match?.centerName ?? "Centro Deportivo"
        let fieldName = match?.fieldName ?? "Cancha \(session.fieldId)"
        return FinishedMatchState(
            id: session.id,
            sessionId: session.id,
            groupPichangaId: session.groupPichangaId,
            centerName: centerName,
            fieldName: fieldName,
            startAt: session.startTime,
            durationMinutes: durationMinutes,
            summary: summary
        )
    }

    private func upsertFinishedMatch(_ finished: FinishedMatchState) {
        if let index = finishedMatches.firstIndex(where: { $0.sessionId == finished.sessionId }) {
            finishedMatches[index] = finished
        } else {
            finishedMatches.append(finished)
        }
        finishedMatches.sort { $0.startAt > $1.startAt }
        if finishedMatches.count > 7 {
            finishedMatches = Array(finishedMatches.prefix(7))
        }
    }

    private func loadFinishedMatchesFromStore() {
        let sessions = store.loadSessions()
        let filtered = sessions.filter { $0.status == .finished || $0.status == .autoFinished }
        var loaded: [FinishedMatchState] = []
        for session in filtered {
            if let pichangaId = session.groupPichangaId {
                locallyFinishedPichangaIds.insert(pichangaId)
            }
            let summary = MatchSummary(
                sourceSessionId: session.id,
                minutesPlayed: max(1, Int((session.endTime ?? Date()).timeIntervalSince(session.startTime) / 60)),
                distanceMeters: {
                    let filtered = session.distanceMetersFiltered ?? session.distanceMeters
                    let raw = session.distanceMetersRaw ?? session.distanceMeters
                    return (filtered <= 1 && raw > 5) ? raw : filtered
                }(),
                goals: session.events.filter { $0.type == .goal },
                assists: session.events.filter { $0.type == .assist },
                samples: acceptedSamplesForHeatmap(from: session.samples)
            )
            if let finished = buildFinishedState(session: session, summary: summary, match: nil) {
                loaded.append(finished)
            }
        }
        finishedMatches = Array(loaded.sorted { $0.startAt > $1.startAt }.prefix(7))
    }

    private func isStillRelevant(_ match: UpcomingMatchState, now: Date) -> Bool {
        now <= match.endAt
    }

    private func logFeedIssue(_ message: String) {
        let now = Date()
        if lastFeedErrorKey == message, let lastFeedErrorAt, now.timeIntervalSince(lastFeedErrorAt) < 12 {
            return
        }
        lastFeedErrorKey = message
        lastFeedErrorAt = now
        print("[WatchBridge] \(message)")
    }

    private func scheduleSyncTimeoutHint() {
        syncTimeoutTask?.cancel()
        syncTimeoutTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            guard !isLinked else { return }
            homeSyncMessage = "Abre Fulbii en iPhone para vincular"
        }
    }

    private func updateHomeSyncMessage(syncing: Bool) {
        if isLinked {
            homeSyncMessage = nil
            return
        }
        homeSyncMessage = syncing ? "Sincronizando con iPhone…" : "Abre Fulbii en iPhone para vincular"
    }

    private func parseMatches(from items: [[String: Any]]?) -> [UpcomingMatchState] {
        guard let items else { return [] }
        return items.compactMap { item in
            guard
                let id = parseInt(item["id"]),
                let title = parseNonEmptyString(item["title"], fallback: ""),
                let centerName = parseNonEmptyString(
                    firstNonEmpty([
                        parseString(item["center_name"]),
                        parseString(item["polideportivo_name"]),
                        parseString(item["polideportivo_nombre"]),
                        parseString(item["field_center_name"]),
                    ]),
                    fallback: "Centro Deportivo"
                ),
                let fieldName = parseNonEmptyString(
                    firstNonEmpty([
                        parseString(item["field_name"]),
                        parseString(item["cancha_name"]),
                        parseString(item["cancha_nombre"]),
                        parseString(item["field_title"]),
                    ]),
                    fallback: "Cancha"
                ),
                let startAtRaw = parseNonEmptyString(item["start_at"] ?? item["starts_at"]),
                let startAt = parseISODate(startAtRaw)
            else {
                return nil
            }
            let durationMinutes = parseInt(item["duration_minutes"]) ?? 90
            let fieldId = parseInt(item["field_id"]) ?? 0
            let teamCodes = parseTeamCodes(item)
            return UpcomingMatchState(
                id: id,
                title: title,
                centerName: centerName,
                fieldId: fieldId,
                fieldName: fieldName,
                startAt: startAt,
                durationMinutes: durationMinutes,
                teamCodes: teamCodes.isEmpty ? ["A", "B"] : teamCodes,
                status: parseString(item["status"] ?? item["me_participant_status"])
            )
        }
    }

    private func parseISODate(_ raw: String) -> Date? {
        if let parsed = ISO8601DateFormatter.fractional.date(from: raw) {
            return parsed
        }
        if let parsed = ISO8601DateFormatter.standard.date(from: raw) {
            return parsed
        }
        return ISO8601DateFormatter().date(from: raw)
    }

    private func parseString(_ value: Any?) -> String? {
        guard let value else { return nil }
        let parsed = "\(value)".trimmingCharacters(in: .whitespacesAndNewlines)
        return parsed.isEmpty ? nil : parsed
    }

    private func parseNonEmptyString(_ value: Any?, fallback: String? = nil) -> String? {
        if let parsed = parseString(value) {
            return parsed
        }
        return fallback
    }

    private func parseInt(_ value: Any?) -> Int? {
        if let intValue = value as? Int {
            return intValue
        }
        if let numberValue = value as? NSNumber {
            return numberValue.intValue
        }
        if let stringValue = value as? String {
            return Int(stringValue)
        }
        return nil
    }

    private func firstNonEmpty(_ values: [String?]) -> String? {
        for value in values {
            let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return nil
    }

    private func parseTeamCodes(_ item: [String: Any]) -> [String] {
        var codes: [String] = []

        if let fromList = item["team_codes"] as? [Any] {
            codes.append(contentsOf: fromList.compactMap { value in
                let raw = "\(value)".trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                return raw.isEmpty ? nil : raw
            })
        }

        if codes.isEmpty, let teams = item["teams"] as? [Any] {
            for rawTeam in teams {
                guard let team = rawTeam as? [String: Any] else { continue }
                let code = parseString(team["code"])?.uppercased() ?? ""
                if !code.isEmpty {
                    codes.append(code)
                }
            }
        }

        if codes.isEmpty {
            let fallbackKeys = ["team_a_code", "team_b_code", "team_c_code", "team_d_code"]
            for key in fallbackKeys {
                if let code = parseString(item[key])?.uppercased(), !code.isEmpty {
                    codes.append(code)
                }
            }
        }

        let unique = Array(Set(codes)).sorted()
        return unique.isEmpty ? ["A", "B"] : unique
    }

    private func showTransientBanner(_ text: String) {
        let ts = Date()
        if lastBannerKey == text, let lastBannerAt, ts.timeIntervalSince(lastBannerAt) < 1.0 {
            return
        }

        lastBannerKey = text
        lastBannerAt = ts
        transientBannerText = text
        bannerTask?.cancel()
        bannerTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            if transientBannerText == text {
                transientBannerText = nil
            }
        }
    }

    private func estimateDistance(samples: [PositionSample]) -> Double {
        guard samples.count > 1 else { return 0 }
        var sum = 0.0
        for idx in 1..<samples.count {
            let a = samples[idx - 1]
            let b = samples[idx]
            sum += haversineMeters(lat1: a.lat, lon1: a.lng, lat2: b.lat, lon2: b.lng)
        }
        return sum
    }

    private func acceptedSamplesForHeatmap(from samples: [PositionSample]) -> [PositionSample] {
        let accepted = samples.filter { sample in
            guard let quality = sample.qualityFlag else { return true }
            return quality != .rejected
        }
        return accepted.isEmpty ? samples : accepted
    }

    private func haversineMeters(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let r = 6_371_000.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180)
            * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return r * c
    }

    private func parseServerMessage(data: Data) -> String? {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let message = json["message"] as? String,
            !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }
        return message
    }

    private enum MatchHaptic {
        case start
        case success
        case stop
    }

    private func playHaptic(_ haptic: MatchHaptic) {
        #if canImport(WatchKit)
        let watchHaptic: WKHapticType = switch haptic {
        case .start:
            .start
        case .success:
            .success
        case .stop:
            .stop
        }
        WKInterfaceDevice.current().play(watchHaptic)
        #endif
    }
}

private struct TrackingEngine {
    struct Output {
        let acceptedPoint: PositionSample?
        let deltaMetersRaw: Double
        let deltaMetersFiltered: Double
        let qualityFlag: PositionSample.QualityFlag
        let isMovementDetected: Bool
    }

    private var lastRawSample: PositionSample?
    private var lastAcceptedSample: PositionSample?
    private var emaSpeed: Double = 0
    private var sustainedMovementCount = 0

    // Tuned for Series 3 physical tests: allow weaker GPS but keep anti-jitter.
    private let maxAccuracyMeters = 60.0
    private let maxFootballSpeedMetersPerSecond = 11.0
    private let stationaryDistanceThreshold = 1.7
    private let stationarySpeedThreshold = 0.45
    private let movementDistanceThreshold = 1.2
    private let movementSpeedThreshold = 0.35
    private let emaAlpha = 0.35
    private let minRequiredSamplesForMovement = 1

    mutating func reset() {
        lastRawSample = nil
        lastAcceptedSample = nil
        emaSpeed = 0
        sustainedMovementCount = 0
    }

    mutating func consume(sample: PositionSample) -> Output {
        guard sample.horizontalAccuracy >= 0, sample.horizontalAccuracy <= maxAccuracyMeters else {
            return Output(
                acceptedPoint: nil,
                deltaMetersRaw: 0,
                deltaMetersFiltered: 0,
                qualityFlag: .rejected,
                isMovementDetected: false
            )
        }

        var rawDelta = 0.0
        var impliedSpeed = sample.speed > 0 ? sample.speed : 0
        if let lastRawSample {
            let dt = sample.timestamp.timeIntervalSince(lastRawSample.timestamp)
            guard dt > 0 else {
                return Output(
                    acceptedPoint: nil,
                    deltaMetersRaw: 0,
                    deltaMetersFiltered: 0,
                    qualityFlag: .rejected,
                    isMovementDetected: false
                )
            }
            let rawDistance = haversineMeters(
                lat1: lastRawSample.lat,
                lon1: lastRawSample.lng,
                lat2: sample.lat,
                lon2: sample.lng
            )
            rawDelta = rawDistance
            impliedSpeed = max(impliedSpeed, rawDistance / dt)
            if impliedSpeed > maxFootballSpeedMetersPerSecond {
                self.lastRawSample = sample
                return Output(
                    acceptedPoint: nil,
                    deltaMetersRaw: 0,
                    deltaMetersFiltered: 0,
                    qualityFlag: .rejected,
                    isMovementDetected: false
                )
            }
        }

        emaSpeed = (emaAlpha * impliedSpeed) + ((1 - emaAlpha) * emaSpeed)

        guard let lastAcceptedSample else {
            sustainedMovementCount = 1
            self.lastAcceptedSample = sample
            self.lastRawSample = sample
            return Output(
                acceptedPoint: sample,
                deltaMetersRaw: rawDelta,
                deltaMetersFiltered: 0,
                qualityFlag: .good,
                isMovementDetected: false
            )
        }

        let acceptedDistance = haversineMeters(
            lat1: lastAcceptedSample.lat,
            lon1: lastAcceptedSample.lng,
            lat2: sample.lat,
            lon2: sample.lng
        )

        let hasStationaryPattern = acceptedDistance < stationaryDistanceThreshold && emaSpeed < stationarySpeedThreshold
        let movementCandidate = acceptedDistance >= movementDistanceThreshold && emaSpeed >= movementSpeedThreshold

        if hasStationaryPattern {
            sustainedMovementCount = 0
            self.lastRawSample = sample
            return Output(
                acceptedPoint: nil,
                deltaMetersRaw: rawDelta,
                deltaMetersFiltered: 0,
                qualityFlag: .weak,
                isMovementDetected: false
            )
        }

        if movementCandidate {
            sustainedMovementCount += 1
        } else {
            sustainedMovementCount = 0
            self.lastRawSample = sample
            return Output(
                acceptedPoint: nil,
                deltaMetersRaw: rawDelta,
                deltaMetersFiltered: 0,
                qualityFlag: .weak,
                isMovementDetected: false
            )
        }

        let isConfirmedMovement = sustainedMovementCount >= minRequiredSamplesForMovement
        let filteredDelta = isConfirmedMovement ? acceptedDistance : 0
        let quality: PositionSample.QualityFlag = isConfirmedMovement ? .good : .weak

        if isConfirmedMovement {
            self.lastAcceptedSample = sample
        }
        self.lastRawSample = sample

        return Output(
            acceptedPoint: isConfirmedMovement ? sample : nil,
            deltaMetersRaw: rawDelta,
            deltaMetersFiltered: filteredDelta,
            qualityFlag: quality,
            isMovementDetected: isConfirmedMovement
        )
    }

    private func haversineMeters(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let r = 6_371_000.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180)
            * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return r * c
    }
}

private extension DateFormatter {
    static let watchClock: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

private extension ISO8601DateFormatter {
    static let standard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static let fractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
