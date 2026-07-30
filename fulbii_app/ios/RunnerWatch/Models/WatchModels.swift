import CoreLocation
import Foundation

enum MatchSessionStatus: String, Codable {
    case idle
    case live
    case paused
    case finished
    case autoFinished = "auto_finished"
}

enum MatchEventType: String, Codable {
    case goal
    case assist
    case pause
    case resume
    case sideChange = "side_change"
}

struct Field: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let centerLat: Double
    let centerLng: Double
}

struct FieldCorner: Codable, Hashable {
    let lat: Double
    let lng: Double
}

struct FieldGeometry: Codable, Identifiable, Hashable {
    var id: String { "field-\(fieldId)" }
    let fieldId: Int
    let widthMeters: Double
    let lengthMeters: Double
    let rotationDegrees: Double
    let corners: [FieldCorner]?
}

struct PositionSample: Codable, Identifiable, Hashable {
    enum QualityFlag: String, Codable, Hashable {
        case good
        case weak
        case rejected
    }

    let id: UUID
    let timestamp: Date
    let lat: Double
    let lng: Double
    let horizontalAccuracy: Double
    let speed: Double
    let qualityFlag: QualityFlag?

    init(
        id: UUID = UUID(),
        timestamp: Date,
        lat: Double,
        lng: Double,
        horizontalAccuracy: Double,
        speed: Double,
        qualityFlag: QualityFlag? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.lat = lat
        self.lng = lng
        self.horizontalAccuracy = horizontalAccuracy
        self.speed = speed
        self.qualityFlag = qualityFlag
    }

    var location: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

struct MatchEvent: Codable, Identifiable, Hashable {
    let id: UUID
    let type: MatchEventType
    let timestamp: Date
    let minute: Int
    let clockTime: String

    init(id: UUID = UUID(), type: MatchEventType, timestamp: Date, minute: Int, clockTime: String) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.minute = minute
        self.clockTime = clockTime
    }
}

struct MatchSession: Codable, Identifiable {
    let id: UUID
    let userId: Int
    let groupPichangaId: Int?
    let fieldId: Int
    let fieldGeometryId: String?
    var status: MatchSessionStatus
    let startTime: Date
    var endTime: Date?
    var sideInfo: String
    var distanceMeters: Double
    var distanceMetersRaw: Double?
    var distanceMetersFiltered: Double?
    var samples: [PositionSample]
    var events: [MatchEvent]

    init(
        id: UUID = UUID(),
        userId: Int,
        groupPichangaId: Int?,
        fieldId: Int,
        fieldGeometryId: String?,
        status: MatchSessionStatus,
        startTime: Date,
        endTime: Date? = nil,
        sideInfo: String = "unknown",
        distanceMeters: Double = 0,
        distanceMetersRaw: Double? = nil,
        distanceMetersFiltered: Double? = nil,
        samples: [PositionSample] = [],
        events: [MatchEvent] = []
    ) {
        self.id = id
        self.userId = userId
        self.groupPichangaId = groupPichangaId
        self.fieldId = fieldId
        self.fieldGeometryId = fieldGeometryId
        self.status = status
        self.startTime = startTime
        self.endTime = endTime
        self.sideInfo = sideInfo
        self.distanceMeters = distanceMeters
        self.distanceMetersRaw = distanceMetersRaw
        self.distanceMetersFiltered = distanceMetersFiltered
        self.samples = samples
        self.events = events
    }
}

struct MatchSummary: Equatable, Hashable {
    let sourceSessionId: UUID?
    let minutesPlayed: Int
    let distanceMeters: Double
    let goals: [MatchEvent]
    let assists: [MatchEvent]
    let samples: [PositionSample]
}

struct FinishedMatchState: Identifiable, Hashable {
    let id: UUID
    let sessionId: UUID
    let groupPichangaId: Int?
    let centerName: String
    let fieldName: String
    let startAt: Date
    let durationMinutes: Int
    let summary: MatchSummary
}

struct FieldProjectedPoint: Identifiable, Hashable {
    let id = UUID()
    let x: Double
    let y: Double
}

struct UpcomingMatchState: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let centerName: String
    let fieldId: Int
    let fieldName: String
    let startAt: Date
    let durationMinutes: Int
    let teamCodes: [String]
    let status: String?

    var endAt: Date {
        startAt.addingTimeInterval(Double(durationMinutes * 60))
    }

    func isStartWindowOpen(now: Date) -> Bool {
        let allowedStart = startAt.addingTimeInterval(-300)
        return now >= allowedStart && now <= endAt
    }
}
