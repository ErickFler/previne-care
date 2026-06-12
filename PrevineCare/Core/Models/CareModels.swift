import CoreLocation
import Foundation

public struct PatientProfile: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var birthDate: Date?
    public var notes: String?
    public var emergencyNotes: String?

    public init(
        id: UUID = UUID(),
        name: String = "Patient",
        birthDate: Date? = nil,
        notes: String? = nil,
        emergencyNotes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.notes = notes
        self.emergencyNotes = emergencyNotes
    }
}

public struct CaregiverProfile: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var phone: String?
    public var relationship: String?
    public var emergencyPhone: String?
    public var caregiverPIN: String

    public init(
        id: UUID = UUID(),
        name: String = "Caregiver",
        phone: String? = nil,
        relationship: String? = nil,
        emergencyPhone: String? = nil,
        caregiverPIN: String = "1234"
    ) {
        self.id = id
        self.name = name
        self.phone = phone
        self.relationship = relationship
        self.emergencyPhone = emergencyPhone
        self.caregiverPIN = caregiverPIN
    }
}

public enum ReminderType: String, CaseIterable, Codable, Sendable {
    case medication
    case appointment
    case meal
    case hydration
    case movement
    case routine
    case other

    public var displayName: String {
        switch self {
        case .medication: "Medication"
        case .appointment: "Appointment"
        case .meal: "Meal"
        case .hydration: "Hydration"
        case .movement: "Movement"
        case .routine: "Routine"
        case .other: "Other"
        }
    }
}

public enum ReminderStatus: String, CaseIterable, Codable, Sendable {
    case pending
    case completed
    case missed
    case skipped
}

public enum RecurrenceFrequency: String, CaseIterable, Codable, Sendable {
    case none
    case daily
    case weekly
    case monthly
    case customDaysOfWeek

    public var displayName: String {
        switch self {
        case .none: "One time"
        case .daily: "Daily"
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        case .customDaysOfWeek: "Specific weekdays"
        }
    }
}

public struct RecurrenceRule: Codable, Equatable, Sendable {
    public var frequency: RecurrenceFrequency
    public var interval: Int
    public var selectedWeekdays: Set<Int>
    public var startDate: Date
    public var endDate: Date?

    public init(
        frequency: RecurrenceFrequency = .none,
        interval: Int = 1,
        selectedWeekdays: Set<Int> = [],
        startDate: Date = Date(),
        endDate: Date? = nil
    ) {
        self.frequency = frequency
        self.interval = max(1, interval)
        self.selectedWeekdays = selectedWeekdays
        self.startDate = startDate
        self.endDate = endDate
    }
}

public struct Reminder: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var type: ReminderType
    public var scheduleDate: Date
    public var repeats: Bool
    public var instructions: String
    public var requiresConfirmation: Bool
    public var status: ReminderStatus
    public var isCritical: Bool
    public var recurrenceRule: RecurrenceRule?

    public init(
        id: UUID = UUID(),
        title: String,
        type: ReminderType,
        scheduleDate: Date,
        repeats: Bool = true,
        instructions: String = "",
        requiresConfirmation: Bool = true,
        status: ReminderStatus = .pending,
        isCritical: Bool = false,
        recurrenceRule: RecurrenceRule? = nil
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.scheduleDate = scheduleDate
        self.repeats = repeats
        self.instructions = instructions
        self.requiresConfirmation = requiresConfirmation
        self.status = status
        self.isCritical = isCritical
        self.recurrenceRule = recurrenceRule
    }

    public var effectiveRecurrenceRule: RecurrenceRule {
        if let recurrenceRule {
            return recurrenceRule
        }
        return RecurrenceRule(frequency: repeats ? .daily : .none, startDate: scheduleDate)
    }
}

public struct ReminderOccurrence: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var reminderId: UUID
    public var occurrenceDate: Date
    public var status: ReminderStatus
    public var completedAt: Date?

    public init(
        id: UUID = UUID(),
        reminderId: UUID,
        occurrenceDate: Date,
        status: ReminderStatus = .pending,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.reminderId = reminderId
        self.occurrenceDate = occurrenceDate
        self.status = status
        self.completedAt = completedAt
    }
}

public enum SafePlaceType: String, CaseIterable, Codable, Sendable {
    case home
    case clinic
    case pharmacy
    case family
    case park
    case custom
    case dayCenter
    case other

    public static var allCases: [SafePlaceType] {
        [.home, .clinic, .pharmacy, .family, .park, .custom]
    }

    public var displayName: String {
        switch self {
        case .home: "Home"
        case .clinic: "Clinic"
        case .pharmacy: "Pharmacy"
        case .family: "Family"
        case .park: "Park"
        case .custom: "Custom"
        case .dayCenter: "Day Center"
        case .other: "Custom"
        }
    }
}

public enum SafeZoneShape: String, Codable, Sendable {
    case circle
    case polygon
}

public struct SafePlace: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var type: SafePlaceType
    // MVP safe zones are circular. Polygon support is reserved for future map-drawn zones.
    public var shape: SafeZoneShape?
    public var latitude: Double
    public var longitude: Double
    public var radiusMeters: Double
    public var allowedStartTime: DateComponents?
    public var allowedEndTime: DateComponents?
    public var allowedDays: Set<Int>?

    public init(
        id: UUID = UUID(),
        name: String,
        type: SafePlaceType = .custom,
        shape: SafeZoneShape? = .circle,
        latitude: Double,
        longitude: Double,
        radiusMeters: Double = 150,
        allowedStartTime: DateComponents? = nil,
        allowedEndTime: DateComponents? = nil,
        allowedDays: Set<Int>? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.shape = shape
        self.latitude = latitude
        self.longitude = longitude
        self.radiusMeters = radiusMeters
        self.allowedStartTime = allowedStartTime
        self.allowedEndTime = allowedEndTime
        self.allowedDays = allowedDays
    }

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    public var coreLocation: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}

public struct LocationEvent: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var latitude: Double
    public var longitude: Double
    public var accuracy: Double
    public var timestamp: Date

    public init(
        id: UUID = UUID(),
        latitude: Double,
        longitude: Double,
        accuracy: Double,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.accuracy = accuracy
        self.timestamp = timestamp
    }

    public var location: CLLocation {
        CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: 0,
            horizontalAccuracy: accuracy,
            verticalAccuracy: -1,
            timestamp: timestamp
        )
    }
}

public enum RiskLevel: String, CaseIterable, Codable, Sendable {
    case low
    case medium
    case high
}

public enum RiskEventStatus: String, CaseIterable, Codable, Sendable {
    case open
    case acknowledged
    case resolved
}

public struct RiskEvent: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var patientID: UUID?
    public var riskScore: Int
    public var riskLevel: RiskLevel
    public var reasons: [String]
    public var timestamp: Date
    public var status: RiskEventStatus
    public var lastLocation: LocationEvent?

    public init(
        id: UUID = UUID(),
        patientID: UUID? = nil,
        riskScore: Int,
        riskLevel: RiskLevel,
        reasons: [String],
        timestamp: Date = Date(),
        status: RiskEventStatus = .open,
        lastLocation: LocationEvent? = nil
    ) {
        self.id = id
        self.patientID = patientID
        self.riskScore = riskScore
        self.riskLevel = riskLevel
        self.reasons = reasons
        self.timestamp = timestamp
        self.status = status
        self.lastLocation = lastLocation
    }
}

public struct CareAlert: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var riskEvent: RiskEvent
    public var patientName: String

    public init(id: UUID = UUID(), riskEvent: RiskEvent, patientName: String) {
        self.id = id
        self.riskEvent = riskEvent
        self.patientName = patientName
    }
}

public enum GuidanceSessionStatus: String, Codable, Sendable {
    case active
    case completed
    case cancelled
    case failed
}

public enum HelpModeState: String, Codable, Sendable {
    case normal
    case helpRequested
    case waitingForCaregiverDestination
    case guidanceActive
    case resolved
}

public struct ActiveGuidanceSession: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var patientId: UUID?
    public var destinationSafePlaceId: UUID
    public var destinationName: String
    public var destinationLatitude: Double
    public var destinationLongitude: Double
    public var startedAt: Date
    public var status: GuidanceSessionStatus
    public var lastKnownDistanceMeters: Double?
    public var lastKnownBearingDegrees: Double?

    public init(
        id: UUID = UUID(),
        patientId: UUID? = nil,
        destinationSafePlaceId: UUID,
        destinationName: String,
        destinationLatitude: Double,
        destinationLongitude: Double,
        startedAt: Date = Date(),
        status: GuidanceSessionStatus = .active,
        lastKnownDistanceMeters: Double? = nil,
        lastKnownBearingDegrees: Double? = nil
    ) {
        self.id = id
        self.patientId = patientId
        self.destinationSafePlaceId = destinationSafePlaceId
        self.destinationName = destinationName
        self.destinationLatitude = destinationLatitude
        self.destinationLongitude = destinationLongitude
        self.startedAt = startedAt
        self.status = status
        self.lastKnownDistanceMeters = lastKnownDistanceMeters
        self.lastKnownBearingDegrees = lastKnownBearingDegrees
    }

    public var destinationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: destinationLatitude, longitude: destinationLongitude)
    }
}
