import Combine
import CoreLocation
import Foundation

@MainActor
public final class LocationService: NSObject, ObservableObject {
    private let manager = CLLocationManager()

    @Published public private(set) var authorizationStatus: CLAuthorizationStatus
    @Published public private(set) var currentLocation: CLLocation?
    @Published public private(set) var currentHeading: CLHeading?
    @Published public private(set) var locationEvents: [LocationEvent] = []

    public override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 20
    }

    public func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    public func requestLocationOnce() {
        manager.requestLocation()
    }

    public func startMonitoring() {
        manager.startUpdatingLocation()
        #if !os(macOS)
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
        #endif
    }

    public func stopMonitoring() {
        manager.stopUpdatingLocation()
        #if !os(macOS)
        manager.stopUpdatingHeading()
        #endif
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in
            self?.authorizationStatus = status
            if Self.isLocationAuthorized(status) {
                self?.requestLocationOnce()
            }
        }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        Task { @MainActor [weak self] in
            self?.currentLocation = latest
            self?.locationEvents.append(
                LocationEvent(
                    latitude: latest.coordinate.latitude,
                    longitude: latest.coordinate.longitude,
                    accuracy: latest.horizontalAccuracy,
                    timestamp: latest.timestamp
                )
            )
            if let count = self?.locationEvents.count, count > 50 {
                self?.locationEvents.removeFirst(count - 50)
            }
        }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor [weak self] in
            self?.currentHeading = newHeading
        }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }

    private static func isLocationAuthorized(_ status: CLAuthorizationStatus) -> Bool {
        #if os(macOS)
        return status == .authorizedAlways
        #else
        return status == .authorizedWhenInUse || status == .authorizedAlways
        #endif
    }
}
