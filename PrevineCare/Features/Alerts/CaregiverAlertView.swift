import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct CaregiverAlertView: View {
    @EnvironmentObject private var appState: CareAppState
    @Environment(\.dismiss) private var dismiss

    let event: RiskEvent

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
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

            Section {
                Button("Marcar como atendido") {
                    appState.markAlertResolved(event)
                    dismiss()
                }
                Button("Llamar al paciente") {
                    call(appState.caregiver.phone)
                }
                Button("Llamar a contacto de emergencia") {
                    call(appState.caregiver.emergencyPhone)
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Caregiver Alert")
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
