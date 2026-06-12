import Foundation

enum LocationFormatting {
    static func coordinateText(_ event: LocationEvent?) -> String {
        guard let event else { return "No location available" }
        return String(format: "%.5f, %.5f", event.latitude, event.longitude)
    }
}
