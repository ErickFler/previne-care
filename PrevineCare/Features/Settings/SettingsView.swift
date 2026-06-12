import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: CareAppState
    @Environment(\.dismiss) private var dismiss

    @State private var patientName = ""
    @State private var caregiverName = ""
    @State private var caregiverPhone = ""
    @State private var emergencyPhone = ""
    @State private var pin = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Patient") {
                    TextField("Name", text: $patientName)
                    TextField("Emergency notes", text: Binding(
                        get: { appState.patient.emergencyNotes ?? "" },
                        set: { appState.patient.emergencyNotes = $0 }
                    ), axis: .vertical)
                }

                Section("Caregiver") {
                    TextField("Name", text: $caregiverName)
                    TextField("Phone", text: $caregiverPhone)
                        .keyboardType(.phonePad)
                    TextField("Emergency phone", text: $emergencyPhone)
                        .keyboardType(.phonePad)
                }

                Section("Patient mode PIN") {
                    SecureField("PIN", text: $pin)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            patientName = appState.patient.name
            caregiverName = appState.caregiver.name
            caregiverPhone = appState.caregiver.phone ?? ""
            emergencyPhone = appState.caregiver.emergencyPhone ?? ""
            pin = appState.caregiver.caregiverPIN
        }
    }

    private func save() {
        appState.patient.name = patientName
        appState.caregiver.name = caregiverName
        appState.caregiver.phone = caregiverPhone
        appState.caregiver.emergencyPhone = emergencyPhone
        appState.caregiver.caregiverPIN = pin.filter(\.isNumber)
    }
}
