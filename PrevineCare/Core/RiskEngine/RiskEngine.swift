import CoreLocation
import Foundation

public struct RiskAssessmentContext: Sendable {
    public var patient: PatientProfile?
    public var currentLocation: LocationEvent?
    public var recentLocationEvents: [LocationEvent]
    public var safePlaces: [SafePlace]
    public var reminders: [Reminder]
    public var now: Date
    public var lastPatientCheckIn: Date?
    public var minutesAwayFromHome: Int?
    public var minutesSinceLastResponse: Int?

    public init(
        patient: PatientProfile? = nil,
        currentLocation: LocationEvent? = nil,
        recentLocationEvents: [LocationEvent] = [],
        safePlaces: [SafePlace] = [],
        reminders: [Reminder] = [],
        now: Date = Date(),
        lastPatientCheckIn: Date? = nil,
        minutesAwayFromHome: Int? = nil,
        minutesSinceLastResponse: Int? = nil
    ) {
        self.patient = patient
        self.currentLocation = currentLocation
        self.recentLocationEvents = recentLocationEvents
        self.safePlaces = safePlaces
        self.reminders = reminders
        self.now = now
        self.lastPatientCheckIn = lastPatientCheckIn
        self.minutesAwayFromHome = minutesAwayFromHome
        self.minutesSinceLastResponse = minutesSinceLastResponse
    }
}

public struct RiskAssessmentResult: Equatable, Sendable {
    public var riskScore: Int
    public var riskLevel: RiskLevel
    public var reasons: [String]

    public init(riskScore: Int, riskLevel: RiskLevel, reasons: [String]) {
        self.riskScore = riskScore
        self.riskLevel = riskLevel
        self.reasons = reasons
    }

    public var shouldAlertCaregiver: Bool {
        riskLevel == .medium || riskLevel == .high
    }
}

public struct RiskEngine: Sendable {
    public init() {}

    public func evaluate(_ context: RiskAssessmentContext) -> RiskAssessmentResult {
        var score = 0
        var reasons: [String] = []

        if let currentLocation = context.currentLocation {
            let location = currentLocation.location
            let containingPlaces = context.safePlaces.filter { place in
                location.distance(from: place.coreLocation) <= place.radiusMeters
            }

            if context.safePlaces.isEmpty {
                score += 20
                reasons.append("No safe places are configured.")
            } else if containingPlaces.isEmpty {
                score += 35
                reasons.append("Patient is outside all safe places.")
            } else if containingPlaces.allSatisfy({ !Self.isAllowedNow(place: $0, date: context.now) }) {
                score += 20
                reasons.append("Patient is at a known place outside the expected time.")
            }

            if currentLocation.accuracy > 120 {
                score += 5
                reasons.append("Current location accuracy is low.")
            }
        } else {
            score += 10
            reasons.append("No current location is available.")
        }

        if let minutesAwayFromHome = context.minutesAwayFromHome, minutesAwayFromHome >= 90 {
            score += 20
            reasons.append("Patient has been away from home for a long time.")
        }

        if context.reminders.contains(where: Self.isCriticalUnconfirmed) {
            score += 25
            reasons.append("A critical reminder has not been confirmed.")
        }

        if let minutesSinceLastResponse = context.minutesSinceLastResponse, minutesSinceLastResponse >= 60 {
            score += 20
            reasons.append("Patient has not responded recently.")
        } else if let lastCheckIn = context.lastPatientCheckIn {
            let minutes = Calendar.current.dateComponents([.minute], from: lastCheckIn, to: context.now).minute ?? 0
            if minutes >= 180 {
                score += 15
                reasons.append("Last patient check-in was several hours ago.")
            }
        }

        if Self.hasErraticMovement(context.recentLocationEvents) {
            score += 15
            reasons.append("Recent movement pattern looks unusual.")
        }

        if reasons.isEmpty {
            reasons.append("No risk rules were triggered.")
        }

        let boundedScore = min(max(score, 0), 100)
        return RiskAssessmentResult(
            riskScore: boundedScore,
            riskLevel: Self.level(for: boundedScore),
            reasons: reasons
        )
    }

    public func makeRiskEvent(from result: RiskAssessmentResult, context: RiskAssessmentContext) -> RiskEvent {
        RiskEvent(
            patientID: context.patient?.id,
            riskScore: result.riskScore,
            riskLevel: result.riskLevel,
            reasons: result.reasons,
            timestamp: context.now,
            status: .open,
            lastLocation: context.currentLocation
        )
    }

    public static func level(for score: Int) -> RiskLevel {
        switch score {
        case 70...100: .high
        case 35..<70: .medium
        default: .low
        }
    }

    public static func isAllowedNow(place: SafePlace, date: Date, calendar: Calendar = .current) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        if let allowedDays = place.allowedDays, !allowedDays.isEmpty, !allowedDays.contains(weekday) {
            return false
        }

        guard let start = place.allowedStartTime, let end = place.allowedEndTime else {
            return true
        }

        let currentMinute = (calendar.component(.hour, from: date) * 60) + calendar.component(.minute, from: date)
        let startMinute = ((start.hour ?? 0) * 60) + (start.minute ?? 0)
        let endMinute = ((end.hour ?? 23) * 60) + (end.minute ?? 59)

        if startMinute <= endMinute {
            return currentMinute >= startMinute && currentMinute <= endMinute
        }

        return currentMinute >= startMinute || currentMinute <= endMinute
    }

    private static func isCriticalUnconfirmed(_ reminder: Reminder) -> Bool {
        reminder.isCritical && reminder.requiresConfirmation && reminder.status != .completed
    }

    private static func hasErraticMovement(_ events: [LocationEvent]) -> Bool {
        guard events.count >= 4 else { return false }
        let sorted = events.sorted { $0.timestamp < $1.timestamp }
        let bearings = zip(sorted, sorted.dropFirst()).map {
            DirectionCalculator.bearingDegrees(from: $0.location.coordinate, to: $1.location.coordinate)
        }

        guard bearings.count >= 3 else { return false }
        var sharpTurns = 0
        for pair in zip(bearings, bearings.dropFirst()) {
            let delta = abs(pair.0 - pair.1)
            let normalized = min(delta, 360 - delta)
            if normalized > 110 {
                sharpTurns += 1
            }
        }
        return sharpTurns >= 2
    }
}
