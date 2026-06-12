import SwiftUI

struct CaregiverGuidanceDestinationPickerView: View {
    @EnvironmentObject private var appState: CareAppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let session = appState.activeGuidanceSession {
                    Section("Guidance status") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(session.destinationName)
                                .font(.headline)
                            Text(session.status.rawValue.capitalized)
                                .foregroundStyle(statusColor(for: session.status))
                            if let distance = session.lastKnownDistanceMeters {
                                Text("\(Int(distance)) m away")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if session.status == .active {
                            Button(role: .destructive) {
                                appState.cancelActiveGuidanceSession()
                            } label: {
                                Label("Cancel guidance", systemImage: "xmark.circle")
                            }
                        }
                    }
                }

                Section("Guide patient to") {
                    if appState.safePlaces.isEmpty {
                        Text("No safe places configured.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(appState.safePlaces) { place in
                            Button {
                                appState.startGuidance(to: place)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: iconName(for: place.type))
                                        .frame(width: 26)
                                        .foregroundStyle(AppTheme.primary)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(place.name)
                                            .font(.headline)
                                        Text("\(place.type.displayName) · \(Int(place.radiusMeters)) m")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }

                Section("Demo") {
                    Button("Emergency demo action") {
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Guide Patient")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func iconName(for type: SafePlaceType) -> String {
        switch type {
        case .home: "house.fill"
        case .clinic: "cross.case.fill"
        case .pharmacy: "pills.fill"
        case .family: "person.2.fill"
        case .park: "tree.fill"
        case .custom, .dayCenter, .other: "mappin.circle.fill"
        }
    }

    private func statusColor(for status: GuidanceSessionStatus) -> Color {
        switch status {
        case .active: AppTheme.support
        case .completed: AppTheme.primary
        case .cancelled: .secondary
        case .failed: .red
        }
    }
}
