import CoreLocation
import XCTest
@testable import PrevineCareCore

final class RiskEngineTests: XCTestCase {
    func testOutsideSafePlaceCreatesMediumRisk() {
        let home = SafePlace(name: "Home", type: .home, latitude: 25.0, longitude: -100.0, radiusMeters: 100)
        let event = LocationEvent(latitude: 25.01, longitude: -100.01, accuracy: 20)
        let context = RiskAssessmentContext(currentLocation: event, safePlaces: [home])

        let result = RiskEngine().evaluate(context)

        XCTAssertEqual(result.riskLevel, .medium)
        XCTAssertTrue(result.reasons.contains("Patient is outside all safe places."))
    }

    func testCriticalUnconfirmedReminderRaisesRisk() {
        let reminder = Reminder(
            title: "Take medication",
            type: .medication,
            scheduleDate: Date(),
            requiresConfirmation: true,
            status: .pending,
            isCritical: true
        )

        let result = RiskEngine().evaluate(RiskAssessmentContext(reminders: [reminder]))

        XCTAssertGreaterThanOrEqual(result.riskScore, 25)
        XCTAssertTrue(result.reasons.contains("A critical reminder has not been confirmed."))
    }

    func testLostPatientDetectorReturnsHighConfidenceForMultipleSignals() {
        let home = SafePlace(name: "Home", type: .home, latitude: 25.0, longitude: -100.0, radiusMeters: 100)
        let location = LocationEvent(latitude: 25.02, longitude: -100.02, accuracy: 15)
        let context = RiskAssessmentContext(
            currentLocation: location,
            recentLocationEvents: [
                LocationEvent(latitude: 25.0201, longitude: -100.0201, accuracy: 15),
                LocationEvent(latitude: 25.0202, longitude: -100.0201, accuracy: 15),
                LocationEvent(latitude: 25.0201, longitude: -100.0202, accuracy: 15)
            ],
            safePlaces: [home],
            minutesAwayFromHome: 120,
            minutesSinceLastResponse: 60
        )

        let result = LostPatientDetector().evaluate(context)

        XCTAssertTrue(result.isPossiblyLost)
        XCTAssertEqual(result.confidenceLevel, .high)
    }
}
