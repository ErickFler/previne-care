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
}
