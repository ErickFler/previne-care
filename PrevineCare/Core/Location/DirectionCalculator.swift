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

    public static func isLocationInsideSafePlace(location: CLLocationCoordinate2D, safePlace: SafePlace) -> Bool {
        distanceMeters(from: location, to: safePlace.coordinate) <= safePlace.radiusMeters
    }

    public static func distanceFromSafePlaceEdge(location: CLLocationCoordinate2D, safePlace: SafePlace) -> CLLocationDistance {
        safePlace.radiusMeters - distanceMeters(from: location, to: safePlace.coordinate)
    }
}

public func blocksApproximation(for radiusMeters: Double) -> String {
    switch radiusMeters {
    case ..<75:
        return "Small area"
    case ..<130:
        return "Around 1 block"
    case ..<300:
        return "Around 2–3 blocks"
    case ..<750:
        return "Neighborhood range"
    default:
        return "Large safe zone"
    }
}

public func isLocationInsideSafePlace(location: CLLocationCoordinate2D, safePlace: SafePlace) -> Bool {
    DirectionCalculator.isLocationInsideSafePlace(location: location, safePlace: safePlace)
}

public func nearestSafePlace(to location: CLLocationCoordinate2D, safePlaces: [SafePlace]) -> SafePlace? {
    DirectionCalculator.nearestSafePlace(to: location, in: safePlaces)
}

private extension Double {
    var radians: Double { self * .pi / 180 }
    var degrees: Double { self * 180 / .pi }
    var normalizedDegrees: Double {
        let value = truncatingRemainder(dividingBy: 360)
        return value >= 0 ? value : value + 360
    }
}
