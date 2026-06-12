import SwiftUI

struct RemindersView: View {
    @EnvironmentObject private var appState: CareAppState
    @State private var title = ""
    @State private var instructions = ""
    @State private var type: ReminderType = .routine
    @State private var date = Date()
    @State private var isCritical = false

    var body: some View {
        Form {
            Section("New reminder") {
                TextField("Title", text: $title)
                TextField("Instructions", text: $instructions, axis: .vertical)
                Picker("Type", selection: $type) {
                    ForEach(ReminderType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                DatePicker("Time", selection: $date, displayedComponents: [.hourAndMinute])
                Toggle("Critical", isOn: $isCritical)
                Button("Add reminder") {
                    addReminder()
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Section("Today") {
                ForEach(appState.todayReminders) { reminder in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(reminder.title)
                            .font(.headline)
                        Text(reminder.instructions)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { offsets in
                    let sorted = appState.todayReminders
                    let ids = offsets.map { sorted[$0].id }
                    appState.reminders.removeAll { ids.contains($0.id) }
                }
            }
        }
        .navigationTitle("Reminders")
    }

    private func addReminder() {
        appState.reminders.append(
            Reminder(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                type: type,
                scheduleDate: date,
                instructions: instructions,
                isCritical: isCritical
            )
        )
        title = ""
        instructions = ""
        type = .routine
        date = Date()
        isCritical = false
    }
}
