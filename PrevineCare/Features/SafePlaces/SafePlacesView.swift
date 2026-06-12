import CoreLocation
import MapKit
import SwiftUI

struct SafePlacesView: View {
    @EnvironmentObject private var appState: CareAppState
    @EnvironmentObject private var locationService: LocationService
    @State private var showEditor = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                Button {
                    showEditor = true
                } label: {
                    Label("Add safe place", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryActionButtonStyle(color: AppTheme.primary))

                if appState.safePlaces.isEmpty {
                    emptyState
                } else {
                    ForEach(appState.safePlaces) { place in
                        SafePlaceCard(place: place) {
                            appState.safePlaces.removeAll { $0.id == place.id }
                        }
                    }
                }
            }
            .padding()
        }
        .background(AppTheme.background)
        .navigationTitle("Safe Places")
        .sheet(isPresented: $showEditor) {
            SafePlaceEditorView { newPlace in
                appState.safePlaces.append(newPlace)
            }
            .environmentObject(locationService)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(AppTheme.primary)
            Text("No safe places yet")
                .font(.headline)
            Text("Add places like home, clinic, or a family member's house so PrevineCare can reason about location safely on this device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct SafePlaceCard: View {
    let place: SafePlace
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 4) {
                    Text(place.name)
                        .font(.headline)
                    Text(place.type.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Menu {
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
                .accessibilityLabel("Safe place actions")
            }

            HStack(spacing: 8) {
                Label("\(Int(place.radiusMeters)) m", systemImage: "circle.dashed")
                Text(blocksApproximation(for: place.radiusMeters))
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(AppTheme.support)

            Text(String(format: "%.5f, %.5f", place.latitude, place.longitude))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var iconName: String {
        switch place.type {
        case .home: "house.fill"
        case .clinic: "cross.case.fill"
        case .pharmacy: "pills.fill"
        case .family: "person.2.fill"
        case .park: "tree.fill"
        case .custom, .dayCenter, .other: "mappin.circle.fill"
        }
    }
}

struct SafePlaceEditorView: View {
    @EnvironmentObject private var locationService: LocationService
    @Environment(\.dismiss) private var dismiss

    let onSave: (SafePlace) -> Void

    @State private var name = ""
    @State private var type: SafePlaceType = .home
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var radiusMeters = 150.0
    @State private var showMapPicker = false
    @State private var waitingForCurrentLocation = false
    @State private var debugLatitude = ""
    @State private var debugLongitude = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Place") {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $type) {
                        ForEach(SafePlaceType.allCases, id: \.self) { placeType in
                            Text(placeType.displayName).tag(placeType)
                        }
                    }
                }

                Section("Location") {
                    Button {
                        useCurrentLocation()
                    } label: {
                        Label("Use current location", systemImage: "location.fill")
                    }

                    Button {
                        prepareMapSelection()
                        showMapPicker = true
                    } label: {
                        Label("Choose on map", systemImage: "map.fill")
                    }

                    if waitingForCurrentLocation {
                        Text("Waiting for the current location...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    selectedLocationSummary
                }

                Section("Safe radius") {
                    SafeRadiusSelectorView(radiusMeters: $radiusMeters)
                }

                Section {
                    DisclosureGroup("Advanced coordinate details") {
                        TextField("Latitude", text: $debugLatitude)
                            .keyboardType(.decimalPad)
                        TextField("Longitude", text: $debugLongitude)
                            .keyboardType(.decimalPad)
                        Button("Apply debug coordinates") {
                            applyDebugCoordinates()
                        }
                        .disabled(!canApplyDebugCoordinates)
                    }
                }
            }
            .navigationTitle("Add safe place")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showMapPicker) {
                SafePlaceMapPickerView(
                    coordinate: $selectedCoordinate,
                    radiusMeters: $radiusMeters
                )
            }
            .onAppear {
                locationService.requestPermission()
                syncDebugFields()
            }
            .onReceive(locationService.$currentLocation.compactMap { $0 }) { location in
                guard waitingForCurrentLocation else { return }
                selectedCoordinate = location.coordinate
                waitingForCurrentLocation = false
                syncDebugFields()
            }
        }
    }

    @ViewBuilder
    private var selectedLocationSummary: some View {
        if let selectedCoordinate {
            VStack(alignment: .leading, spacing: 4) {
                Text("Selected point")
                    .font(.subheadline.weight(.semibold))
                Text(String(format: "%.5f, %.5f", selectedCoordinate.latitude, selectedCoordinate.longitude))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            Text("Choose a point with current location or the map.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var canSave: Bool {
        selectedCoordinate != nil && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canApplyDebugCoordinates: Bool {
        Double(debugLatitude) != nil && Double(debugLongitude) != nil
    }

    private func useCurrentLocation() {
        locationService.requestPermission()
        if let coordinate = locationService.currentLocation?.coordinate {
            selectedCoordinate = coordinate
            waitingForCurrentLocation = false
            syncDebugFields()
        } else {
            waitingForCurrentLocation = true
            locationService.requestLocationOnce()
        }
    }

    private func prepareMapSelection() {
        if selectedCoordinate == nil {
            selectedCoordinate = locationService.currentLocation?.coordinate ?? Self.defaultCoordinate
            syncDebugFields()
        }
    }

    private func applyDebugCoordinates() {
        guard let latitude = Double(debugLatitude), let longitude = Double(debugLongitude) else { return }
        selectedCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private func syncDebugFields() {
        guard let selectedCoordinate else {
            debugLatitude = ""
            debugLongitude = ""
            return
        }
        debugLatitude = String(format: "%.6f", selectedCoordinate.latitude)
        debugLongitude = String(format: "%.6f", selectedCoordinate.longitude)
    }

    private func save() {
        guard let selectedCoordinate else { return }
        onSave(
            SafePlace(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                type: type,
                shape: .circle,
                latitude: selectedCoordinate.latitude,
                longitude: selectedCoordinate.longitude,
                radiusMeters: radiusMeters
            )
        )
        dismiss()
    }

    private static let defaultCoordinate = CLLocationCoordinate2D(latitude: 25.6516, longitude: -100.2897)
}

struct SafePlaceMapPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var coordinate: CLLocationCoordinate2D?
    @Binding var radiusMeters: Double
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 25.6516, longitude: -100.2897),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MapReader { proxy in
                    Map(position: $position) {
                        if let coordinate {
                            MapCircle(center: coordinate, radius: radiusMeters)
                                .foregroundStyle(AppTheme.primary.opacity(0.18))
                                .stroke(AppTheme.primary, lineWidth: 2)

                            Marker("Safe place", systemImage: "mappin.circle.fill", coordinate: coordinate)
                                .tint(AppTheme.primary)
                        }
                    }
                    .mapControls {
                        MapCompass()
                        MapScaleView()
                    }
                    .gesture(
                        SpatialTapGesture().onEnded { value in
                            guard let newCoordinate = proxy.convert(value.location, from: .local) else { return }
                            coordinate = newCoordinate
                            recenter(on: newCoordinate)
                        }
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Tap the map to move the safe-place pin.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    SafeRadiusSelectorView(radiusMeters: $radiusMeters)
                }
                .padding()
                .background(AppTheme.background)
            }
            .navigationTitle("Choose on map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                if coordinate == nil {
                    coordinate = Self.defaultCoordinate
                }
                if let coordinate {
                    recenter(on: coordinate)
                }
            }
        }
    }

    private func recenter(on coordinate: CLLocationCoordinate2D) {
        let span = MKCoordinateSpan(latitudeDelta: spanDelta(for: radiusMeters), longitudeDelta: spanDelta(for: radiusMeters))
        position = .region(MKCoordinateRegion(center: coordinate, span: span))
    }

    private func spanDelta(for radiusMeters: Double) -> CLLocationDegrees {
        max(0.004, min(0.04, radiusMeters / 25_000))
    }

    private static let defaultCoordinate = CLLocationCoordinate2D(latitude: 25.6516, longitude: -100.2897)
}

struct SafeRadiusSelectorView: View {
    @Binding var radiusMeters: Double

    private let radiusOptions = [50.0, 100.0, 150.0, 200.0, 300.0, 500.0, 1000.0]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(Int(radiusMeters)) m")
                    .font(.headline)
                Spacer()
                Text(blocksApproximation(for: radiusMeters))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.support)
            }

            Slider(
                value: Binding(
                    get: { Double(selectedIndex) },
                    set: { radiusMeters = radiusOptions[Int($0.rounded())] }
                ),
                in: 0...Double(radiusOptions.count - 1),
                step: 1
            )

            HStack {
                Text("50 m")
                Spacer()
                Text("1000 m")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var selectedIndex: Int {
        radiusOptions.enumerated().min {
            abs($0.element - radiusMeters) < abs($1.element - radiusMeters)
        }?.offset ?? 2
    }
}
