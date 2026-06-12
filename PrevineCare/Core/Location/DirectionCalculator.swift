import CoreLocation
import Foundation

public struct DirectionCalculator: Sendable {
    public init() {}

    public static func distanceMeters(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: origin.latitude, longitude: origin.longitude)
            .distance(from: CLLocation(latitude: destination.latitude, longitude: destination.longitude))
    }

    public static func bearingDegrees(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> Double {
        let lat1 = origin.latitude.radians
        let lat2 = destination.latitude.radians
        let deltaLongitude = (destination.longitude - origin.longitude).radians

        let y = sin(deltaLongitude) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLongitude)
        let bearing = atan2(y, x).degrees
        return bearing.normalizedDegrees
    }

    public static func relativeBearingDegrees(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        headingDegrees: Double
    ) -> Double {
        (bearingDegrees(from: origin, to: destination) - headingDegrees).normalizedDegrees
    }

    public static func nearestSafePlace(to location: CLLocationCoordinate2D, in places: [SafePlace]) -> SafePlace? {
        places.min {
            distanceMeters(from: location, to: $0.coordinate) < distanceMeters(from: location, to: $1.coordinate)
        }
    }
}

private extension Double {
    var radians: Double { self * .pi / 180 }
    var degrees: Double { self * 180 / .pi }
    var normalizedDegrees: Double {
        let value = truncatingRemainder(dividingBy: 360)
        return value >= 0 ? value : value + 360
    }
}
