import Foundation
import WatchConnectivity

struct WatchBridgeContext {
    let userId: Int?
    let hasAuthToken: Bool
    let matches: [UpcomingMatchState]
}

final class WatchSyncManager: NSObject, WCSessionDelegate {
    private let store: LocalStore
    var onContextUpdated: ((WatchBridgeContext) -> Void)?
    private let isoFormatter = ISO8601DateFormatter()

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
    }

    func queueSessionForSync(_ session: MatchSession) {
        let payload: [String: String] = [
            "schema_version": "1",
            "sessionId": session.id.uuidString,
            "status": session.status.rawValue,
            "startTime": isoFormatter.string(from: session.startTime),
            "endTime": session.endTime.map { isoFormatter.string(from: $0) } ?? "",
            "distanceMeters": String(format: "%.2f", session.distanceMeters),
            "eventsCount": String(session.events.count),
            "samplesCount": String(session.samples.count)
        ]
        store.enqueueSyncPayload(payload)

        guard WCSession.isSupported(), WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(["type": "watch_session_sync", "payload": payload], replyHandler: nil, errorHandler: nil)
    }

    func session(_: WCSession, activationDidCompleteWith _: WCSessionActivationState, error _: Error?) {}

    func sessionReachabilityDidChange(_: WCSession) {}

    func session(_: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handleIncomingContext(applicationContext)
    }

    func session(_: WCSession, didReceiveMessage message: [String: Any]) {
        handleIncomingContext(message)
    }

    private func handleIncomingContext(_ context: [String: Any]) {
        let userId = parseInt(context["user_id"])
        let token = (context["auth_token"] as? String) ?? ""
        var matches: [UpcomingMatchState] = []
        if let items = context["upcoming_matches"] as? [[String: Any]] {
            matches = items.compactMap { item in
                guard
                    let id = parseInt(item["id"]),
                    let title = item["title"] as? String,
                    let centerName = item["center_name"] as? String,
                    let fieldId = parseInt(item["field_id"]),
                    let fieldName = item["field_name"] as? String,
                    let startAtRaw = item["start_at"] as? String,
                    let startAt = isoFormatter.date(from: startAtRaw),
                    let durationMinutes = parseInt(item["duration_minutes"])
                else {
                    return nil
                }
                return UpcomingMatchState(
                    id: id,
                    title: title,
                    centerName: centerName,
                    fieldId: fieldId,
                    fieldName: fieldName,
                    startAt: startAt,
                    durationMinutes: durationMinutes
                )
            }
        }
        onContextUpdated?(
            WatchBridgeContext(
                userId: userId,
                hasAuthToken: !token.isEmpty,
                matches: matches
            )
        )
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
}
