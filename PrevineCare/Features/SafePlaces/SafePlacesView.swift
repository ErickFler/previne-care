import SwiftUI

struct SafePlacesView: View {
    @EnvironmentObject private var appState: CareAppState
    @State private var name = ""
    @State private var type: SafePlaceType = .home
    @State private var latitude = ""
    @State private var longitude = ""
    @State private var radius = "150"

    var body: some View {
        Form {
            Section("New safe place") {
                TextField("Name", text: $name)
                Picker("Type", selection: $type) {
                    ForEach(SafePlaceType.allCases, id: \.self) { placeType in
                        Text(placeType.rawValue.capitalized).tag(placeType)
                    }
                }
                TextField("Latitude", text: $latitude)
                    .keyboardType(.decimalPad)
                TextField("Longitude", text: $longitude)
                    .keyboardType(.decimalPad)
                TextField("Radius meters", text: $radius)
                    .keyboardType(.numberPad)
                Button("Add safe place") {
                    addSafePlace()
                }
                .disabled(!canAdd)
            }

            Section("Configured places") {
                ForEach(appState.safePlaces) { place in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(place.name)
                            .font(.headline)
                        Text("\(place.latitude), \(place.longitude) · \(Int(place.radiusMeters)) m")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { offsets in
                    appState.safePlaces.remove(atOffsets: offsets)
                }
            }
        }
        .navigationTitle("Safe Places")
    }

    private var canAdd: Bool {
        Double(latitude) != nil &&
        Double(longitude) != nil &&
        Double(radius) != nil &&
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func addSafePlace() {
        guard
            let latitude = Double(latitude),
            let longitude = Double(longitude),
            let radius = Double(radius)
        else { return }

        appState.safePlaces.append(
            SafePlace(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                type: type,
                latitude: latitude,
                longitude: longitude,
                radiusMeters: radius
            )
        )
        name = ""
        self.latitude = ""
        self.longitude = ""
        self.radius = "150"
    }
}
