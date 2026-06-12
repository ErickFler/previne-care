import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Panic Alert

struct PanicAlertView: View {
    @EnvironmentObject private var appState: CareAppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 90))
                .foregroundStyle(.white)

            VStack(spacing: 10) {
                Text("Tu cuidador fue avisado")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Quédate donde estás.\nAlguien viene a ayudarte.")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 14) {
                Button {
                    callPhone(appState.caregiver.phone)
                } label: {
                    Label("Llamar a mi cuidador", systemImage: "phone.fill")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity, minHeight: 64)
                        .foregroundStyle(AppTheme.destructive)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
                }

                Text("Emergency demo action")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.75))

                Button("Ya estoy bien") {
                    appState.patientIsOkay()
                    dismiss()
                }
                .font(.headline)
                .foregroundStyle(.white.opacity(0.75))
                .padding(.top, 4)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.destructive)
        .ignoresSafeArea()
    }

    private func callPhone(_ phone: String?) {
        #if canImport(UIKit)
        guard
            let phone,
            !phone.isEmpty,
            let url = URL(string: "tel://\(phone.filter(\.isNumber))")
        else { return }
        UIApplication.shared.open(url)
        #endif
    }
}

// MARK: - Patient Home

struct PatientHomeView: View {
    @EnvironmentObject private var appState: CareAppState
    @EnvironmentObject private var locationService: LocationService
    @State private var showExitPIN = false
    @State private var showGuidance = false
    @State private var showPanicConfirmation = false
    @State private var showPanicAlert = false

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
                    helpButton
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                panicButton
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
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
            .fullScreenCover(isPresented: $showPanicAlert) {
                PanicAlertView()
            }
            .confirmationDialog(
                "¿Necesitas ayuda urgente?",
                isPresented: $showPanicConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sí, avisar a mi cuidador", role: .destructive) {
                    Task {
                        await appState.patientPanic(location: latestLocationEvent)
                        showPanicAlert = true
                    }
                }
                Button("No, estoy bien", role: .cancel) {}
            } message: {
                Text("Tu cuidador recibirá una alerta de inmediato.")
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

    private var helpButton: some View {
        VStack(spacing: 12) {
            Button("Necesito ayuda") {
                Task {
                    await appState.patientNeedsHelp(location: latestLocationEvent)
                }
            }
            .buttonStyle(PrimaryActionButtonStyle(color: .red))
        }
    }

    private var panicButton: some View {
        Button {
            showPanicConfirmation = true
        } label: {
            Label("EMERGENCIA", systemImage: "sos.circle.fill")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, minHeight: 64)
                .foregroundStyle(.white)
                .background(AppTheme.destructive)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        }
        .accessibilityLabel("Botón de emergencia. Toca para avisar a tu cuidador de inmediato.")
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
