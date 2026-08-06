import Foundation
import WatchKit

@MainActor
final class MatchSessionManager: ObservableObject {
    @Published var selectedField: Field
    @Published var selectedGeometry: FieldGeometry?
    @Published var activeSession: MatchSession?
    @Published var latestSummary: MatchSummary?
    @Published var confirmationText: String?
    @Published var transientBannerText: String?
    @Published var assistanceEnabled = true
    @Published var debugSimulationEnabled = true
    @Published var todayMatches: [UpcomingMatchState] = []
    @Published var linkedUserId: Int?
    @Published var linkedAuthTokenAvailable = false

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

    init() {
        let store = LocalStore()
        self.store = store
        self.locationManager = LocationCaptureManager()
        self.workoutManager = WorkoutManager()
        self.syncManager = WatchSyncManager(store: store)

        selectedField = Field(id: 1, name: "Cancha Mock Fulbii", centerLat: -12.0464, centerLng: -77.0428)
        selectedGeometry = FieldGeometry(fieldId: 1, widthMeters: 30, lengthMeters: 50, rotationDegrees: 0, corners: nil)
        todayMatches = [Self.defaultMockUpcomingMatch()]
        syncManager.onContextUpdated = { [weak self] context in
            Task { @MainActor in
                self?.applyBridgeContext(context)
            }
        }
        locationManager.requestPermission()
        startClockTimer()
    }

    var activeOrUpcomingMatch: UpcomingMatchState? {
        let sorted = todayMatches.sorted { $0.startAt < $1.startAt }
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

        if match.isStartWindowOpen(now: now) {
            return "Listo para iniciar"
        }

        let minutes = max(1, Int(match.startAt.timeIntervalSince(now) / 60))
        return "Disponible en \(minutes) min"
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
        let meters = activeSession?.distanceMeters ?? 0
        if meters >= 1000 {
            return String(format: "%.2f km", meters / 1000)
        }
        return String(format: "%.0f m", meters)
    }

    var gpsStatus: String {
        locationManager.gpsStatus
    }

    func startMatch() {
        guard activeSession == nil, canStartMatch else { return }
        guard let match = activeOrUpcomingMatch else { return }

        var session = MatchSession(
            userId: linkedUserId ?? 1,
            groupPichangaId: match.id,
            fieldId: match.fieldId,
            fieldGeometryId: selectedGeometry?.id,
            status: .live,
            startTime: Date()
        )
        session.sideInfo = "unknown"
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

    func finishMatch(autoFinished: Bool = false) {
        guard var session = activeSession else { return }
        session.endTime = Date()
        session.status = autoFinished ? .autoFinished : .finished
        activeSession = session
        finalizeSession(session)
        activeSession = nil
        stopRealtimeCapture()
        playHaptic(.stop)
    }

    func simulateThirtyMinutes() {
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
            groupPichangaId: activeOrUpcomingMatch?.id,
            fieldId: selectedField.id,
            fieldGeometryId: selectedGeometry?.id,
            status: .finished,
            startTime: start,
            endTime: now
        )
        session.samples = samples
        session.events = goals
        session.distanceMeters = estimateDistance(samples: samples)
        finalizeSession(session)
        showTransientBanner("Simulación 30 min lista")
    }

    func clearConfirmation() {
        confirmationText = nil
    }

    private func appendSample(_ sample: PositionSample) {
        guard var session = activeSession, session.status == .live else { return }
        if let last = session.samples.last {
            let meters = haversineMeters(
                lat1: last.lat, lon1: last.lng,
                lat2: sample.lat, lon2: sample.lng
            )
            session.distanceMeters += meters
            if meters >= 3 || sample.speed >= 0.5 {
                lastMovementAt = Date()
            }
        } else {
            lastMovementAt = Date()
        }
        session.samples.append(sample)
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

    private func finalizeSession(_ session: MatchSession) {
        store.save(session: session)
        latestSummary = MatchSummary(
            minutesPlayed: max(1, Int((session.endTime ?? Date()).timeIntervalSince(session.startTime) / 60)),
            distanceMeters: session.distanceMeters,
            goals: session.events.filter { $0.type == .goal },
            assists: session.events.filter { $0.type == .assist },
            samples: session.samples
        )
        syncManager.queueSessionForSync(session)
    }

    private func applyBridgeContext(_ context: WatchBridgeContext) {
        linkedUserId = context.userId
        linkedAuthTokenAvailable = context.hasAuthToken
        if !context.matches.isEmpty {
            todayMatches = context.matches
        }
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

    private static func defaultMockUpcomingMatch() -> UpcomingMatchState {
        let start = Date().addingTimeInterval(5 * 60)
        return UpcomingMatchState(
            id: 1001,
            title: "Pichanga Fulbii",
            centerName: "Mock Centro Deportivo",
            fieldId: 1,
            fieldName: "Cancha Mock Fulbii",
            startAt: start,
            durationMinutes: 90
        )
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

    private func playHaptic(_ haptic: WKHapticType) {
        WKInterfaceDevice.current().play(haptic)
    }
}

private extension DateFormatter {
    static let watchClock: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
