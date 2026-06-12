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
                Text("Your caregiver has been notified")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Stay where you are.\nSomeone is coming to help you.")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 14) {
                Button {
                    callPhone(appState.caregiver.phone)
                } label: {
                    Label("Call my caregiver", systemImage: "phone.fill")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity, minHeight: 64)
                        .foregroundStyle(AppTheme.destructive)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
                }

                if let emergencyPhone = appState.caregiver.emergencyPhone, !emergencyPhone.isEmpty {
                    Button {
                        callPhone(emergencyPhone)
                    } label: {
                        Label("Call emergency services", systemImage: "cross.fill")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity, minHeight: 64)
                            .foregroundStyle(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(.white.opacity(0.6), lineWidth: 2)
                            )
                    }
                }

                Button("I'm okay now") {
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
                        Text("Hello, \(appState.patient.name)")
                            .font(.largeTitle.bold())
                        Text("Let's take it step by step.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    nextUp
                    todayList
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
            .navigationTitle("Patient")
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
                "Do you need urgent help?",
                isPresented: $showPanicConfirmation,
                titleVisibility: .visible
            ) {
                Button("Yes, alert my caregiver", role: .destructive) {
                    Task {
                        await appState.patientPanic(location: latestLocationEvent)
                        showPanicAlert = true
                    }
                }
                Button("No, I'm okay", role: .cancel) {}
            } message: {
                Text("Your caregiver will receive an alert immediately.")
            }
        }
    }

    private var nextUp: some View {
        CareCard {
            Text("Up next")
                .font(.headline)
            if let reminder = appState.nextReminder {
                Text(reminder.title)
                    .font(.title.bold())
                Text(reminder.instructions)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Button("Done") {
                    appState.complete(reminder)
                }
                .buttonStyle(PrimaryActionButtonStyle(color: AppTheme.support))
            } else {
                Text("All done for now.")
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.support)
            }
        }
    }

    private var todayList: some View {
        CareCard {
            Text("Today's list")
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

    private var panicButton: some View {
        Button {
            showPanicConfirmation = true
        } label: {
            Label("EMERGENCY", systemImage: "sos.circle.fill")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, minHeight: 64)
                .foregroundStyle(.white)
                .background(AppTheme.destructive)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        }
        .accessibilityLabel("Emergency button. Tap to alert your caregiver immediately.")
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
