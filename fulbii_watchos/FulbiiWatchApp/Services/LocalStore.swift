import Foundation

final class LocalStore {
    private let sessionsKey = "fulbii_watch_sessions"
    private let queueKey = "fulbii_watch_sync_queue"

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

    func enqueueSyncPayload(_ payload: [String: String]) {
        var queue = loadSyncQueue()
        queue.append(payload)
        persistQueue(queue)
    }

    func loadSyncQueue() -> [[String: String]] {
        guard let data = UserDefaults.standard.data(forKey: queueKey) else {
            return []
        }
        return (try? decoder.decode([[String: String]].self, from: data)) ?? []
    }

    func clearSyncQueue() {
        UserDefaults.standard.removeObject(forKey: queueKey)
    }

    private func persistSessions(_ sessions: [MatchSession]) {
        guard let data = try? encoder.encode(sessions) else { return }
        UserDefaults.standard.set(data, forKey: sessionsKey)
    }

    private func persistQueue(_ queue: [[String: String]]) {
        guard let data = try? encoder.encode(queue) else { return }
        UserDefaults.standard.set(data, forKey: queueKey)
    }
}
