import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct CaregiverAlertView: View {
    @EnvironmentObject private var appState: CareAppState
    @Environment(\.dismiss) private var dismiss
    @State private var showDestinationPicker = false

    let event: RiskEvent

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Possible lost state")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.warning)
                        .clipShape(Capsule())
                    Text(appState.patient.name)
                        .font(.title.bold())
                    Text(event.riskLevel.rawValue.capitalized)
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.statusColor(for: event.riskLevel))
                    Text("Score \(event.riskScore)/100")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Reasons") {
                ForEach(event.reasons, id: \.self) { reason in
                    Text(reason)
                }
            }

            Section("Last known location") {
                Text(LocationFormatting.coordinateText(event.lastLocation))
                Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .foregroundStyle(.secondary)
            }

            Section("Guide destination") {
                if let session = appState.activeGuidanceSession {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(session.destinationName)
                            .font(.headline)
                        Text(session.status.rawValue.capitalized)
                            .foregroundStyle(session.status == .active ? AppTheme.support : .secondary)
                    }
                }

                Button {
                    showDestinationPicker = true
                } label: {
                    Label("Choose safe place", systemImage: "location.north.circle.fill")
                }
            }

            Section("Safe places") {
                if appState.safePlaces.isEmpty {
                    Text("No safe places configured.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(appState.safePlaces) { place in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(place.name)
                                .font(.headline)
                            Text("\(place.type.displayName) · \(Int(place.radiusMeters)) m")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                Button("Mark as attended") {
                    appState.markAlertResolved(event)
                    dismiss()
                }
                Button("Cancel guidance") {
                    appState.cancelActiveGuidanceSession()
                }
                .disabled(appState.activeGuidanceSession?.status != .active)
                Button("Call patient") {
                    call(appState.caregiver.phone)
                }
                Button("Call emergency contact") {
                    call(appState.caregiver.emergencyPhone)
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Caregiver Alert")
        .sheet(isPresented: $showDestinationPicker) {
            CaregiverGuidanceDestinationPickerView()
        }
    }

    private func call(_ phone: String?) {
        #if canImport(UIKit)
        guard
            let phone,
            let url = URL(string: "tel://\(phone.filter(\.isNumber))")
        else { return }
        UIApplication.shared.open(url)
        #endif
    }
}
