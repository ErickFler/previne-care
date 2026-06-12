import SwiftUI

struct PatientHomeView: View {
    @EnvironmentObject private var appState: CareAppState
    @EnvironmentObject private var locationService: LocationService
    @State private var showExitPIN = false
    @State private var showGuidance = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Hola, \(appState.patient.name)")
                            .font(.largeTitle.bold())
                        Text("Vamos paso a paso.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    nextUp
                    todayList
                    actionButtons
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("Paciente")
            .toolbar {
                Button {
                    showExitPIN = true
                } label: {
                    Image(systemName: "lock.circle")
                }
                .accessibilityLabel("Exit patient mode")
            }
            .sheet(isPresented: $showExitPIN) {
                PINGateView(title: "Exit patient mode") { pin in
                    appState.exitPatientMode(pin: pin)
                }
            }
            .sheet(isPresented: $showGuidance) {
                PatientGuidanceView()
            }
        }
    }

    private var nextUp: some View {
        CareCard {
            Text("Lo siguiente")
                .font(.headline)
            if let reminder = appState.nextReminder {
                Text(reminder.title)
                    .font(.title.bold())
                Text(reminder.instructions)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Button("Hecho") {
                    appState.complete(reminder)
                }
                .buttonStyle(PrimaryActionButtonStyle(color: AppTheme.support))
            } else {
                Text("Todo listo por ahora.")
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.support)
            }
        }
    }

    private var todayList: some View {
        CareCard {
            Text("Lista del día")
                .font(.headline)
            ForEach(appState.todayReminders) { reminder in
                HStack {
                    VStack(alignment: .leading) {
                        Text(reminder.title)
                            .font(.headline)
                        Text(reminder.scheduleDate.formatted(date: .omitted, time: .shortened))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: reminder.status == .completed ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(reminder.status == .completed ? AppTheme.support : .secondary)
                        .font(.title2)
                }
                Divider()
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button("Estoy bien") {
                appState.patientIsOkay()
            }
            .buttonStyle(PrimaryActionButtonStyle(color: AppTheme.support))

            Button("Necesito ayuda") {
                Task {
                    await appState.patientNeedsHelp(location: latestLocationEvent)
                    showGuidance = true
                }
            }
            .buttonStyle(PrimaryActionButtonStyle(color: .red))

            Button("Guía para volver") {
                showGuidance = true
            }
            .buttonStyle(PrimaryActionButtonStyle(color: AppTheme.primary))
        }
    }

    private var latestLocationEvent: LocationEvent? {
        locationService.currentLocation.map {
            LocationEvent(
                latitude: $0.coordinate.latitude,
                longitude: $0.coordinate.longitude,
                accuracy: $0.horizontalAccuracy,
                timestamp: $0.timestamp
            )
        }
    }
}
