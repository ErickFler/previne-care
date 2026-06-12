import CoreLocation
import XCTest
@testable import PrevineCareCore

final class DirectionCalculatorTests: XCTestCase {
    func testBearingNorthIsNearZero() {
        let origin = CLLocationCoordinate2D(latitude: 25.0, longitude: -100.0)
        let destination = CLLocationCoordinate2D(latitude: 26.0, longitude: -100.0)

        let bearing = DirectionCalculator.bearingDegrees(from: origin, to: destination)

        XCTAssertLessThan(bearing, 1.0)
    }

    func testNearestSafePlace() {
        let origin = CLLocationCoordinate2D(latitude: 25.0, longitude: -100.0)
        let near = SafePlace(name: "Near", latitude: 25.001, longitude: -100.0)
        let far = SafePlace(name: "Far", latitude: 26.0, longitude: -100.0)

        let nearest = DirectionCalculator.nearestSafePlace(to: origin, in: [far, near])

        XCTAssertEqual(nearest?.name, "Near")
    }

    func testRelativeAngleUsesSignedDegrees() {
        XCTAssertEqual(DirectionCalculator.relativeAngle(targetBearing: 10, deviceHeading: 350), 20, accuracy: 0.001)
        XCTAssertEqual(DirectionCalculator.relativeAngle(targetBearing: 350, deviceHeading: 10), -20, accuracy: 0.001)
        XCTAssertEqual(DirectionCalculator.relativeAngle(targetBearing: 180, deviceHeading: 0), 180, accuracy: 0.001)
    }

    func testLocationInsideSafePlace() {
        let origin = CLLocationCoordinate2D(latitude: 25.0, longitude: -100.0)
        let home = SafePlace(name: "Home", latitude: 25.0, longitude: -100.0, radiusMeters: 100)

        XCTAssertTrue(isLocationInsideSafePlace(location: origin, safePlace: home))
    }

    func testBlocksApproximationUsesCaregiverFriendlyLabels() {
        XCTAssertEqual(blocksApproximation(for: 50), "Small area")
        XCTAssertEqual(blocksApproximation(for: 100), "Around 1 block")
        XCTAssertEqual(blocksApproximation(for: 200), "Around 2–3 blocks")
        XCTAssertEqual(blocksApproximation(for: 500), "Neighborhood range")
        XCTAssertEqual(blocksApproximation(for: 1000), "Large safe zone")
    }
}
