import Foundation

final class LocalStore {
    private let sessionsKey = "fulbii_watch_sessions"
    private let queueKey = "fulbii_watch_sync_queue"
    private let bridgeContextKey = "fulbii_watch_bridge_context"

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func save(session: MatchSession) {
        var sessions = loadSessions()
        sessions.removeAll { $0.id == session.id }
        sessions.append(session)
        persistSessions(sessions)
    }

    func loadSessions() -> [MatchSession] {
        guard let data = UserDefaults.standard.data(forKey: sessionsKey) else {
            return []
        }
        return (try? decoder.decode([MatchSession].self, from: data)) ?? []
    }

    func enqueueSyncPayload(_ payload: [String: Any]) {
        var queue = loadSyncQueue()
        queue.append(payload)
        persistQueue(queue)
    }

    func loadSyncQueue() -> [[String: Any]] {
        guard let data = UserDefaults.standard.data(forKey: queueKey) else {
            return []
        }
        guard let raw = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        return raw
    }

    func replaceSyncQueue(_ queue: [[String: Any]]) {
        persistQueue(queue)
    }

    func clearSyncQueue() {
        UserDefaults.standard.removeObject(forKey: queueKey)
    }

    func saveBridgeContext(_ context: [String: Any]) {
        guard JSONSerialization.isValidJSONObject(context) else { return }
        guard let data = try? JSONSerialization.data(withJSONObject: context) else { return }
        UserDefaults.standard.set(data, forKey: bridgeContextKey)
    }

    func loadBridgeContext() -> [String: Any]? {
        guard let data = UserDefaults.standard.data(forKey: bridgeContextKey) else {
            return nil
        }
        guard let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return raw
    }

    private func persistSessions(_ sessions: [MatchSession]) {
        guard let data = try? encoder.encode(sessions) else { return }
        UserDefaults.standard.set(data, forKey: sessionsKey)
    }

    private func persistQueue(_ queue: [[String: Any]]) {
        guard JSONSerialization.isValidJSONObject(queue) else { return }
        guard let data = try? JSONSerialization.data(withJSONObject: queue) else { return }
        UserDefaults.standard.set(data, forKey: queueKey)
    }
}
