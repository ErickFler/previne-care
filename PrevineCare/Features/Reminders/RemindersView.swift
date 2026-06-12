import SwiftUI

struct RemindersView: View {
    @EnvironmentObject private var appState: CareAppState
    @State private var selectedDate = Date()
    @State private var showEditor = false
    @State private var editingReminder: Reminder?

    var body: some View {
        ReminderCalendarView(
            selectedDate: $selectedDate,
            items: appState.remindersForDate(selectedDate),
            onAdd: { showEditor = true },
            onEdit: { editingReminder = $0 },
            onDelete: appState.deleteReminder,
            onToggle: toggle
        )
        .navigationTitle("Reminders")
        .sheet(isPresented: $showEditor) {
            ReminderEditorView { reminder in
                appState.saveReminder(reminder)
            }
        }
        .sheet(item: $editingReminder) { reminder in
            ReminderEditorView(reminder: reminder) { updated in
                appState.saveReminder(updated)
            }
        }
    }

    private func toggle(_ item: ReminderDayItem) {
        let nextStatus: ReminderStatus = item.occurrence.status == .completed ? .pending : .completed
        appState.setReminder(item.reminder, status: nextStatus, on: item.occurrence.occurrenceDate)
    }
}

struct ReminderCalendarView: View {
    @Binding var selectedDate: Date
    let items: [ReminderDayItem]
    let onAdd: () -> Void
    let onEdit: (Reminder) -> Void
    let onDelete: (Reminder) -> Void
    let onToggle: (ReminderDayItem) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                calendarHeader

                Button {
                    onAdd()
                } label: {
                    Label("Add reminder", systemImage: "plus.circle.fill")
                }
                .buttonStyle(PrimaryActionButtonStyle())

                reminderSection(title: "Pending", items: items.filter { status(for: $0) == .pending })
                reminderSection(title: "Completed", items: items.filter { status(for: $0) == .completed })
                reminderSection(title: "Missed", items: items.filter { status(for: $0) == .missed })
            }
            .padding(AppTheme.Spacing.lg)
        }
        .background(AppTheme.background)
    }

    private var calendarHeader: some View {
        CareCard {
            HStack {
                Button {
                    selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.borderless)

                Spacer()

                DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                    .labelsHidden()

                Spacer()

                Button {
                    selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.borderless)
            }

            Button("Today") {
                selectedDate = Date()
            }
            .buttonStyle(SecondaryActionButtonStyle())
        }
    }

    @ViewBuilder
    private func reminderSection(title: String, items: [ReminderDayItem]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text(title)
                    .font(AppTheme.Typography.cardTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(items) { item in
                    ReminderOccurrenceCard(
                        item: item,
                        status: status(for: item),
                        onToggle: { onToggle(item) },
                        onEdit: { onEdit(item.reminder) },
                        onDelete: { onDelete(item.reminder) }
                    )
                }
            }
        }
    }

    private func status(for item: ReminderDayItem) -> ReminderStatus {
        if item.occurrence.status == .pending && item.occurrence.occurrenceDate < Date() && !Calendar.current.isDateInToday(item.occurrence.occurrenceDate) {
            return .missed
        }
        return item.occurrence.status
    }
}

private struct ReminderOccurrenceCard: View {
    let item: ReminderDayItem
    let status: ReminderStatus
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        CareCard {
            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                Button(action: onToggle) {
                    Image(systemName: status == .completed ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(status == .completed ? AppTheme.support : AppTheme.primary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(item.reminder.title)
                        .font(.headline)
                    Text(item.occurrence.occurrenceDate.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !item.reminder.instructions.isEmpty {
                        Text(item.reminder.instructions)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(item.reminder.effectiveRecurrenceRule.frequency.displayName)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppTheme.primary)
                }

                Spacer()

                Menu {
                    Button(action: onToggle) {
                        Label(status == .completed ? "Mark pending" : "Mark complete", systemImage: status == .completed ? "circle" : "checkmark.circle")
                    }
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

struct ReminderEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Reminder) -> Void
    private let existingReminder: Reminder?

    @State private var title: String
    @State private var instructions: String
    @State private var type: ReminderType
    @State private var date: Date
    @State private var requiresConfirmation: Bool
    @State private var isCritical: Bool
    @State private var recurrenceFrequency: RecurrenceFrequency
    @State private var selectedWeekdays: Set<Int>

    init(reminder: Reminder? = nil, onSave: @escaping (Reminder) -> Void) {
        existingReminder = reminder
        self.onSave = onSave
        _title = State(initialValue: reminder?.title ?? "")
        _instructions = State(initialValue: reminder?.instructions ?? "")
        _type = State(initialValue: reminder?.type ?? .routine)
        _date = State(initialValue: reminder?.scheduleDate ?? Date())
        _requiresConfirmation = State(initialValue: reminder?.requiresConfirmation ?? true)
        _isCritical = State(initialValue: reminder?.isCritical ?? false)
        _recurrenceFrequency = State(initialValue: reminder?.effectiveRecurrenceRule.frequency ?? .none)
        _selectedWeekdays = State(initialValue: reminder?.effectiveRecurrenceRule.selectedWeekdays ?? [])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Reminder") {
                    TextField("Title", text: $title)
                    Picker("Type", selection: $type) {
                        ForEach(ReminderType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    TextField("Instructions", text: $instructions, axis: .vertical)
                }

                Section("Schedule") {
                    DatePicker("Date and time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    Picker("Repeats", selection: $recurrenceFrequency) {
                        ForEach(RecurrenceFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.displayName).tag(frequency)
                        }
                    }

                    if recurrenceFrequency == .customDaysOfWeek {
                        WeekdayPicker(selectedWeekdays: $selectedWeekdays)
                    }
                }

                Section("Confirmation") {
                    Toggle("Requires confirmation", isOn: $requiresConfirmation)
                    Toggle("Critical", isOn: $isCritical)
                }
            }
            .navigationTitle(existingReminder == nil ? "Add reminder" : "Edit reminder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let recurrence = RecurrenceRule(
            frequency: recurrenceFrequency,
            selectedWeekdays: selectedWeekdays,
            startDate: date
        )
        onSave(
            Reminder(
                id: existingReminder?.id ?? UUID(),
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                type: type,
                scheduleDate: date,
                repeats: recurrenceFrequency != .none,
                instructions: instructions,
                requiresConfirmation: requiresConfirmation,
                status: existingReminder?.status ?? .pending,
                isCritical: isCritical,
                recurrenceRule: recurrence
            )
        )
        dismiss()
    }
}

private struct WeekdayPicker: View {
    @Binding var selectedWeekdays: Set<Int>
    private let days = [(1, "Sun"), (2, "Mon"), (3, "Tue"), (4, "Wed"), (5, "Thu"), (6, "Fri"), (7, "Sat")]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            ForEach(days, id: \.0) { day in
                Toggle(day.1, isOn: Binding(
                    get: { selectedWeekdays.contains(day.0) },
                    set: { isSelected in
                        if isSelected {
                            selectedWeekdays.insert(day.0)
                        } else {
                            selectedWeekdays.remove(day.0)
                        }
                    }
                ))
            }
        }
    }
}
