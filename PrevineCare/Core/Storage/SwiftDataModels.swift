import Foundation
import SwiftData

@Model
final class PersistedPatientProfile {
    var id: UUID
    var name: String
    var birthDate: Date?
    var notes: String?
    var emergencyNotes: String?

    init(id: UUID = UUID(), name: String, birthDate: Date? = nil, notes: String? = nil, emergencyNotes: String? = nil) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.notes = notes
        self.emergencyNotes = emergencyNotes
    }
}

@Model
final class PersistedSafePlace {
    var id: UUID
    var name: String
    var typeRawValue: String
    var latitude: Double
    var longitude: Double
    var radiusMeters: Double

    init(id: UUID = UUID(), name: String, typeRawValue: String, latitude: Double, longitude: Double, radiusMeters: Double) {
        self.id = id
        self.name = name
        self.typeRawValue = typeRawValue
        self.latitude = latitude
        self.longitude = longitude
        self.radiusMeters = radiusMeters
    }
}
