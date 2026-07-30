import Foundation
import WatchConnectivity

struct WatchBridgeContext {
    let userId: Int?
    let userNick: String?
    let userName: String?
    let authToken: String
    let hasAuthToken: Bool
    let apiBaseUrl: String?
    let confirmedMatches: [UpcomingMatchState]
    let pendingMatches: [UpcomingMatchState]
}

final class WatchSyncManager: NSObject, WCSessionDelegate {
    private let store: LocalStore
    var onSyncStatus: ((String) -> Void)?
    var onContextUpdated: ((WatchBridgeContext) -> Void)? {
        didSet {
            guard
                let onContextUpdated,
                let lastBridgeContext
            else { return }
            onContextUpdated(lastBridgeContext)
        }
    }
    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    private let isoFormatterFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    private var lastBridgeContext: WatchBridgeContext?
    private var uploadTask: Task<Void, Never>?
    private var lastUploadFailure: String?

    init(store: LocalStore) {
        self.store = store
        super.init()
        activate()
    }

    private func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        if let persistedContext = store.loadBridgeContext(), !persistedContext.isEmpty {
            handleIncomingContext(persistedContext)
        }
        // Apply last known context immediately to avoid "unlinked" UI on cold open.
        let cachedContext = session.receivedApplicationContext
        if !cachedContext.isEmpty {
            handleIncomingContext(cachedContext)
        }
    }

    func requestLatestContext(reason: String) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        let cachedContext = session.receivedApplicationContext
        if !cachedContext.isEmpty {
            handleIncomingContext(cachedContext)
        }

        guard session.isReachable else {
            print("[WatchBridge] pull_context skipped (not reachable) reason=\(reason)")
            return
        }

        let message: [String: Any] = [
            "type": "watch_pull_context",
            "reason": reason,
            "requested_at": isoFormatter.string(from: Date()),
        ]
        session.sendMessage(
            message,
            replyHandler: { [weak self] reply in
                guard let self else { return }
                if !reply.isEmpty {
                    print("[WatchBridge] pull_context reply received reason=\(reason)")
                    self.handleIncomingContext(reply)
                    let userId = self.parseInt(reply["user_id"]) ?? -1
                    let hasToken = !(((reply["auth_token"] as? String) ?? "").isEmpty)
                    print("[WatchBridge] pull_context reply received user_id=\(userId) has_token=\(hasToken)")
                } else {
                    print("[WatchBridge] pull_context empty reply reason=\(reason)")
                }
            },
            errorHandler: { error in
                print("[WatchBridge] pull_context failed reason=\(reason) \(error.localizedDescription)")
            }
        )
    }

    func queueSessionForSync(_ session: MatchSession) {
        guard let pichangaId = session.groupPichangaId, pichangaId > 0 else {
            print("[WatchBridge] queue rejected: invalid groupPichangaId for session \(session.id.uuidString)")
            return
        }
        let distanceFiltered = session.distanceMetersFiltered ?? session.distanceMeters
        let distanceRaw = session.distanceMetersRaw ?? session.distanceMeters
        let displayDistance = (distanceFiltered <= 1 && distanceRaw > 5) ? distanceRaw : distanceFiltered
        let sanitizedDistanceFiltered = sanitizeFiniteNumber(distanceFiltered, fallback: 0)
        let sanitizedDistanceRaw = sanitizeFiniteNumber(distanceRaw, fallback: sanitizedDistanceFiltered)
        let sanitizedDisplayDistance = sanitizeFiniteNumber(displayDistance, fallback: sanitizedDistanceFiltered)
        var payload: [String: Any] = [
            "schema_version": "1",
            "sessionId": session.id.uuidString,
            "groupPichangaId": pichangaId,
            "fieldId": session.fieldId,
            "status": session.status.rawValue,
            "startTime": isoFormatterFractional.string(from: session.startTime),
            "distanceMeters": sanitizedDisplayDistance,
            "distanceMetersFiltered": sanitizedDistanceFiltered,
            "distanceMetersRaw": sanitizedDistanceRaw,
            "samples": session.samples.map { sample in
                var samplePayload: [String: Any] = [
                    "timestamp": isoFormatterFractional.string(from: sample.timestamp),
                    "lat": sample.lat,
                    "lng": sample.lng,
                ]
                if sample.horizontalAccuracy.isFinite {
                    samplePayload["horizontalAccuracy"] = max(0, sample.horizontalAccuracy)
                }
                if sample.speed.isFinite, sample.speed >= 0 {
                    samplePayload["speed"] = sample.speed
                }
                if let qualityFlag = sample.qualityFlag?.rawValue {
                    samplePayload["quality_flag"] = qualityFlag
                }
                return samplePayload
            },
            "events": session.events.map { event in
                [
                    "type": event.type.rawValue,
                    "timestamp": isoFormatterFractional.string(from: event.timestamp),
                    "minute": event.minute,
                    "clockTime": event.clockTime,
                ]
            },
        ]
        if let fieldGeometryId = session.fieldGeometryId {
            payload["fieldGeometryId"] = fieldGeometryId
        }
        if let endTime = session.endTime {
            payload["endTime"] = isoFormatterFractional.string(from: endTime)
        }
        store.enqueueSyncPayload(payload)
        onSyncStatus?("En cola: sesión \(session.id.uuidString.prefix(6))")
        print("[WatchBridge] Queue session sync id=\(session.id.uuidString) status=\(session.status.rawValue) samples=\(session.samples.count) events=\(session.events.count)")
        let forceUpload = session.status == .finished || session.status == .autoFinished
        scheduleQueueUpload(reason: "session_enqueued", force: forceUpload)

        guard WCSession.isSupported() else { return }
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(
                ["type": "watch_session_sync", "payload": payload],
                replyHandler: nil,
                errorHandler: { [weak self] error in
                    self?.onSyncStatus?("WC sendMessage falló")
                    print("[WatchBridge] sendMessage failed: \(error.localizedDescription)")
                }
            )
        }
        WCSession.default.transferUserInfo(["type": "watch_session_sync", "payload": payload])
    }

    func session(_: WCSession, activationDidCompleteWith _: WCSessionActivationState, error _: Error?) {
        let cachedContext = WCSession.default.receivedApplicationContext
        if !cachedContext.isEmpty {
            handleIncomingContext(cachedContext)
        }
        requestLatestContext(reason: "activation")
        scheduleQueueUpload(reason: "activation")
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        print("[WatchBridge] reachability changed isReachable=\(session.isReachable)")
        if session.isReachable {
            requestLatestContext(reason: "reachability")
            scheduleQueueUpload(reason: "reachability")
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_: WCSession) {}

    func sessionDidDeactivate(_: WCSession) {
        WCSession.default.activate()
    }
    #endif

    func session(_: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handleIncomingContext(applicationContext)
    }

    func session(_: WCSession, didReceiveMessage message: [String: Any]) {
        handleIncomingContext(message)
    }

    func session(
        _: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        handleIncomingContext(message)
        replyHandler(["ok": true])
    }

    private func handleIncomingContext(_ context: [String: Any]) {
        let userId = parseInt(context["user_id"])
        let token = (context["auth_token"] as? String) ?? ""
        let userNick = parseString(context["user_nick"])
        let userName = parseString(context["user_name"])
        let apiBaseUrl = parseString(context["api_base_url"])
        let confirmed = parseMatches(from: context["confirmed_matches"] as? [[String: Any]])
        let pending = parseMatches(from: context["pending_matches"] as? [[String: Any]])
        // Backward compatibility for previous payload shape.
        let fallbackUpcoming = parseMatches(from: context["upcoming_matches"] as? [[String: Any]])
        let resolvedConfirmed = confirmed.isEmpty ? fallbackUpcoming : confirmed
        print("[WatchBridge] Incoming context user_id=\(userId ?? -1) has_token=\(!token.isEmpty) confirmed=\(resolvedConfirmed.count) pending=\(pending.count)")
        let bridgeContext = WatchBridgeContext(
            userId: userId,
            userNick: userNick,
            userName: userName,
            authToken: token,
            hasAuthToken: !token.isEmpty,
            apiBaseUrl: apiBaseUrl,
            confirmedMatches: resolvedConfirmed,
            pendingMatches: pending
        )
        store.saveBridgeContext(context)
        lastBridgeContext = bridgeContext
        onContextUpdated?(bridgeContext)
        scheduleQueueUpload(reason: "context_update")
    }

    private func scheduleQueueUpload(reason: String, force: Bool = false) {
        if force, let task = uploadTask {
            task.cancel()
            uploadTask = nil
        }
        if uploadTask != nil { return }
        uploadTask = Task { [weak self] in
            guard let self else { return }
            defer { self.uploadTask = nil }
            await self.flushSyncQueue(reason: reason)
        }
    }

    private func flushSyncQueue(reason: String) async {
        let token = ((lastBridgeContext?.authToken) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let baseRaw = ((lastBridgeContext?.apiBaseUrl) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let base = baseRaw.hasSuffix("/") ? String(baseRaw.dropLast()) : baseRaw
        guard !token.isEmpty, !base.isEmpty else {
            onSyncStatus?("Sin token/base URL para subir")
            return
        }

        let queue = store.loadSyncQueue()
        guard !queue.isEmpty else {
            onSyncStatus?("Sin pendientes por subir")
            return
        }

        var remaining: [[String: Any]] = []
        for payload in queue {
            let uploaded = await uploadPayload(payload, token: token, baseUrl: base)
            if !uploaded {
                remaining.append(payload)
            }
        }

        store.replaceSyncQueue(remaining)
        if remaining.isEmpty {
            onSyncStatus?("Subida \(queue.count)/\(queue.count)")
        } else if let lastUploadFailure, !lastUploadFailure.isEmpty {
            onSyncStatus?("Subida \(queue.count - remaining.count)/\(queue.count) (\(lastUploadFailure))")
        } else {
            onSyncStatus?("Subida \(queue.count - remaining.count)/\(queue.count)")
        }
        print("[WatchBridge] syncQueue flush reason=\(reason) queued=\(queue.count) remaining=\(remaining.count)")
    }

    private func uploadPayload(_ payload: [String: Any], token: String, baseUrl: String) async -> Bool {
        lastUploadFailure = nil
        guard
            let sessionId = parseString(payload["sessionId"]),
            let startTime = parseString(payload["startTime"])
        else {
            lastUploadFailure = "payload inválido"
            return false
        }

        let groupPichangaId = normalizePositiveInt(payload["groupPichangaId"])
        guard let groupPichangaId else {
            print("[WatchBridge] upload rejected store: invalid groupPichangaId session=\(sessionId)")
            lastUploadFailure = "groupPichangaId inválido"
            return false
        }
        let fieldId = normalizePositiveInt(payload["fieldId"])
        let fieldGeometryId = normalizePositiveInt(payload["fieldGeometryId"])
        let endTime = parseString(payload["endTime"])
        let status = parseString(payload["status"]) ?? MatchSessionStatus.finished.rawValue
        let distance = (payload["distanceMeters"] as? NSNumber)?.doubleValue
            ?? Double(parseString(payload["distanceMeters"]) ?? "")
            ?? 0
        let distanceFiltered = (payload["distanceMetersFiltered"] as? NSNumber)?.doubleValue
            ?? Double(parseString(payload["distanceMetersFiltered"]) ?? "")
            ?? distance
        let distanceRaw = (payload["distanceMetersRaw"] as? NSNumber)?.doubleValue
            ?? Double(parseString(payload["distanceMetersRaw"]) ?? "")
            ?? distanceFiltered
        let rawSamples = payload["samples"] as? [[String: Any]] ?? []
        let samples = rawSamples.map { sample -> [String: Any] in
            var normalized = sample
            if let speedNumber = sample["speed"] as? NSNumber {
                if speedNumber.doubleValue < 0 {
                    normalized["speed"] = NSNull()
                }
            } else if let speedText = sample["speed"] as? String, let speed = Double(speedText), speed < 0 {
                normalized["speed"] = NSNull()
            }
            return normalized
        }
        let events = payload["events"] as? [[String: Any]] ?? []

        let storeBody: [String: Any] = [
            "external_session_id": sessionId,
            "group_pichanga_id": groupPichangaId,
            "field_id": fieldId ?? NSNull(),
            "field_geometry_id": fieldGeometryId ?? NSNull(),
            "start_time": startTime,
            "status": "live",
            "device": "watchos",
            "source": "live",
            "distance_meters_raw": distanceRaw,
            "distance_meters_filtered": distanceFiltered,
            "device_payload": [
                "watch_session_id": sessionId,
                "schema_version": payload["schema_version"] as? String ?? "1",
            ],
        ]
        guard
            let storeResponse = await postJSON(
                url: "\(baseUrl)/watch/match-sessions",
                token: token,
                body: storeBody,
                step: "store"
            ),
            let createdSession = storeResponse["session"] as? [String: Any],
            let backendSessionId = parseInt(createdSession["id"])
        else {
            return false
        }

        if !samples.isEmpty {
            let samplesOk = await postJSON(
                url: "\(baseUrl)/watch/match-sessions/\(backendSessionId)/samples/batch",
                token: token,
                body: ["samples": samples],
                step: "samples_batch"
            ) != nil
            if !samplesOk {
                return false
            }
        }

        if !events.isEmpty {
            let eventsOk = await postJSON(
                url: "\(baseUrl)/watch/match-sessions/\(backendSessionId)/events/batch",
                token: token,
                body: ["events": events],
                step: "events_batch"
            ) != nil
            if !eventsOk {
                return false
            }
        }

        let finishStatus = status == MatchSessionStatus.autoFinished.rawValue ? status : MatchSessionStatus.finished.rawValue
        let finishDistance = (distanceFiltered <= 1 && distanceRaw > 5) ? distanceRaw : distanceFiltered
        let finishBody: [String: Any] = [
            "end_time": endTime ?? startTime,
            "status": finishStatus,
            "distance_meters": finishDistance,
            "distance_meters_raw": distanceRaw,
            "distance_meters_filtered": distanceFiltered,
        ]
        let finished = await postJSON(
            url: "\(baseUrl)/watch/match-sessions/\(backendSessionId)/finish",
            token: token,
            body: finishBody,
            step: "finish"
        ) != nil

        if finished {
            onSyncStatus?("Subida OK sesión \(sessionId.prefix(6))")
            print("[WatchBridge] session uploaded id=\(sessionId) backend_id=\(backendSessionId)")
        } else {
            onSyncStatus?("Falló upload sesión \(sessionId.prefix(6))")
        }
        return finished
    }

    private func postJSON(url: String, token: String, body: [String: Any], step: String) async -> [String: Any]? {
        guard let endpoint = URL(string: url) else { return nil }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            lastUploadFailure = "\(step): json inválido"
            print("[WatchBridge] upload \(step) payload serialization error: \(error.localizedDescription)")
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
                if let http = response as? HTTPURLResponse {
                    let bodyText = String(data: data, encoding: .utf8) ?? "<non-utf8>"
                    lastUploadFailure = "\(step):\(http.statusCode)"
                    print("[WatchBridge] upload \(step) failed status=\(http.statusCode) body=\(bodyText)")
                } else {
                    lastUploadFailure = "\(step):respuesta inválida"
                    print("[WatchBridge] upload \(step) failed non-http response")
                }
                return nil
            }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return json ?? [:]
        } catch {
            lastUploadFailure = "\(step):red"
            print("[WatchBridge] upload \(step) network error: \(error.localizedDescription)")
            return nil
        }
    }

    private func sanitizeFiniteNumber(_ value: Double, fallback: Double) -> Double {
        if value.isFinite {
            return value
        }
        return fallback.isFinite ? fallback : 0
    }

    private func parseMatches(from items: [[String: Any]]?) -> [UpcomingMatchState] {
        guard let items else { return [] }
        return items.compactMap { item in
            guard
                let id = parseInt(item["id"]),
                let title = parseNonEmptyString(item["title"], fallback: ""),
                let centerName = parseNonEmptyString(item["center_name"], fallback: "Centro Deportivo"),
                let fieldName = parseNonEmptyString(item["field_name"], fallback: "Cancha"),
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
                status: parseString(item["status"])
            )
        }
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
            if let direct = Int(stringValue) {
                return direct
            }
            if let range = stringValue.range(of: #"\d+"#, options: .regularExpression) {
                return Int(String(stringValue[range]))
            }
        }
        return nil
    }

    private func normalizePositiveInt(_ value: Any?) -> Int? {
        guard let parsed = parseInt(value), parsed > 0 else { return nil }
        return parsed
    }

    private func parseISODate(_ raw: String) -> Date? {
        if let parsed = isoFormatterFractional.date(from: raw) {
            return parsed
        }
        if let parsed = isoFormatter.date(from: raw) {
            return parsed
        }
        return ISO8601DateFormatter().date(from: raw)
    }
}
