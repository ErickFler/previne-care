import CoreLocation
import Foundation

public enum LostConfidenceLevel: String, Codable, Sendable {
    case low
    case medium
    case high
}

public struct LostPatientAssessment: Equatable, Sendable {
    public var isPossiblyLost: Bool
    public var confidenceLevel: LostConfidenceLevel
    public var reasons: [String]
    public var recommendedAction: String

    public init(
        isPossiblyLost: Bool,
        confidenceLevel: LostConfidenceLevel,
        reasons: [String],
        recommendedAction: String
    ) {
        self.isPossiblyLost = isPossiblyLost
        self.confidenceLevel = confidenceLevel
        self.reasons = reasons
        self.recommendedAction = recommendedAction
    }
}

public struct LostPatientDetector: Sendable {
    public init() {}

    public func evaluate(_ context: RiskAssessmentContext) -> LostPatientAssessment {
        var score = 0
        var reasons: [String] = []

        if let currentLocation = context.currentLocation {
            let isOutsideAllSafePlaces = context.safePlaces.allSatisfy {
                currentLocation.location.distance(from: $0.coreLocation) > $0.radiusMeters
            }

            if context.safePlaces.isEmpty {
                score += 1
                reasons.append("No safe places are configured.")
            } else if isOutsideAllSafePlaces {
                score += 2
                reasons.append("Patient is outside every safe place.")
            }

            let isKnownAtExpectedTime = context.safePlaces.contains { place in
                currentLocation.location.distance(from: place.coreLocation) <= place.radiusMeters &&
                RiskEngine.isAllowedNow(place: place, date: context.now)
            }
            if !isKnownAtExpectedTime {
                score += 1
                reasons.append("Current place is unknown or outside the expected schedule.")
            }
        } else {
            score += 1
            reasons.append("Current location is unavailable.")
        }

        if let minutesAwayFromHome = context.minutesAwayFromHome, minutesAwayFromHome >= 90 {
            score += 1
            reasons.append("Patient has been away from home too long.")
        }

        if let minutesSinceLastResponse = context.minutesSinceLastResponse, minutesSinceLastResponse >= 45 {
            score += 1
            reasons.append("Patient has not responded to check-in.")
        }

        if stayedStillInUnknownArea(context) {
            score += 1
            reasons.append("Patient appears stopped in an unknown area.")
        }

        let confidence: LostConfidenceLevel
        switch score {
        case 4...: confidence = .high
        case 2...3: confidence = .medium
        default: confidence = .low
        }

        let possiblyLost = confidence != .low
        let action = switch confidence {
        case .high:
            "Notify the caregiver and guide the patient to stay where they are."
        case .medium:
            "Show calm guidance and ask the patient to confirm they are okay."
        case .low:
            "Continue local monitoring."
        }

        return LostPatientAssessment(
            isPossiblyLost: possiblyLost,
            confidenceLevel: confidence,
            reasons: reasons.isEmpty ? ["No lost-patient rules were triggered."] : reasons,
            recommendedAction: action
        )
    }

    private func stayedStillInUnknownArea(_ context: RiskAssessmentContext) -> Bool {
        guard
            let currentLocation = context.currentLocation,
            context.recentLocationEvents.count >= 3
        else { return false }

        let known = context.safePlaces.contains {
            currentLocation.location.distance(from: $0.coreLocation) <= $0.radiusMeters
        }
        guard !known else { return false }

        let recent = context.recentLocationEvents.suffix(3)
        let distances = recent.map { $0.location.distance(from: currentLocation.location) }
        return distances.allSatisfy { $0 < 35 }
    }
}
