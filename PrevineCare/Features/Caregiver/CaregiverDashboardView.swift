import SwiftUI

struct CaregiverDashboardView: View {
    @EnvironmentObject private var appState: CareAppState
    @EnvironmentObject private var locationService: LocationService
    @State private var showEnterPIN = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    CareCard {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(appState.patient.name)
                                    .font(.title2.bold())
                                Text(LocalAssistantService().caregiverSummary(
                                    patient: appState.patient,
                                    reminders: appState.reminders,
                                    latestRisk: appState.latestOpenRiskEvent
                                ))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                            Spacer()
                            riskBadge
                        }
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

                if let event = appState.latestOpenRiskEvent {
                    Section("Open alert") {
                        NavigationLink {
                            CaregiverAlertView(event: event)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.riskLevel.rawValue.capitalized)
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.statusColor(for: event.riskLevel))
                                Text(event.reasons.joined(separator: " "))
                                    .font(.caption)
                                    .lineLimit(2)
                            }
                        }
                    }
                }

                Section("Today") {
                    ForEach(appState.todayReminders) { reminder in
                        ReminderRow(reminder: reminder) {
                            appState.toggleReminder(reminder)
                        }
                    }
                }

                Section("Manage") {
                    NavigationLink("Reminders and routines") {
                        RemindersView()
                    }
                    NavigationLink("Safe places") {
                        SafePlacesView()
                    }
                    Button("Evaluate risk now") {
                        Task {
                            locationService.requestLocationOnce()
                            await appState.evaluateRisk(
                                currentLocation: locationService.currentLocation.map {
                                    LocationEvent(
                                        latitude: $0.coordinate.latitude,
                                        longitude: $0.coordinate.longitude,
                                        accuracy: $0.horizontalAccuracy,
                                        timestamp: $0.timestamp
                                    )
                                },
                                recentLocations: locationService.locationEvents
                            )
                        }
                    }
                }

                Section {
                    Button {
                        showEnterPIN = true
                    } label: {
                        Label("Enter patient mode", systemImage: "lock.fill")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("PrevineCare")
            .toolbar {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
            .sheet(isPresented: $showEnterPIN) {
                PINGateView(title: "Enter patient mode") { pin in
                    appState.enterPatientMode(pin: pin)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    private var riskBadge: some View {
        let level = appState.latestOpenRiskEvent?.riskLevel ?? .low
        return Text(level.rawValue.capitalized)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(.white)
            .background(AppTheme.statusColor(for: level))
            .clipShape(Capsule())
    }
}

private struct ReminderRow: View {
    let reminder: Reminder
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(AppTheme.primary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(reminder.title)
                    .font(.headline)
                Text(reminder.scheduleDate.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: onComplete) {
                Image(systemName: reminder.status == .completed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
    }

    private var iconName: String {
        switch reminder.type {
        case .medication: "pills.fill"
        case .appointment: "calendar"
        case .meal: "fork.knife"
        case .hydration: "drop.fill"
        case .movement: "figure.walk"
        case .routine: "checklist"
        case .other: "checkmark.circle"
        }
    }
}
