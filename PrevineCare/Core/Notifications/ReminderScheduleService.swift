import Foundation

public struct ReminderScheduleService: Sendable {
    public init() {}

    public func occurrences(for reminder: Reminder, from start: Date, to end: Date, calendar: Calendar = .current) -> [Date] {
        guard start <= end else { return [] }
        let rule = reminder.effectiveRecurrenceRule
        let startDate = max(calendar.startOfDay(for: rule.startDate), calendar.startOfDay(for: reminder.scheduleDate))
        let endBoundary = rule.endDate.map { min($0, end) } ?? end
        guard startDate <= endBoundary else { return [] }

        switch rule.frequency {
        case .none:
            return calendar.isDate(reminder.scheduleDate, inRangeFrom: start, to: end) ? [reminder.scheduleDate] : []
        case .daily:
            return generateDaily(reminder: reminder, rule: rule, from: start, to: endBoundary, calendar: calendar)
        case .weekly:
            return generateWeekly(reminder: reminder, rule: rule, from: start, to: endBoundary, calendar: calendar)
        case .monthly:
            return generateMonthly(reminder: reminder, rule: rule, from: start, to: endBoundary, calendar: calendar)
        case .customDaysOfWeek:
            return generateCustomWeekdays(reminder: reminder, rule: rule, from: start, to: endBoundary, calendar: calendar)
        }
    }

    public func occurrences(on date: Date, reminders: [Reminder], calendar: Calendar = .current) -> [ReminderOccurrence] {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: start) ?? date
        return reminders.flatMap { reminder in
            occurrences(for: reminder, from: start, to: end, calendar: calendar).map {
                ReminderOccurrence(reminderId: reminder.id, occurrenceDate: $0)
            }
        }
        .sorted { $0.occurrenceDate < $1.occurrenceDate }
    }

    private func generateDaily(reminder: Reminder, rule: RecurrenceRule, from start: Date, to end: Date, calendar: Calendar) -> [Date] {
        generateByDay(reminder: reminder, rule: rule, from: start, to: end, calendar: calendar) { dayOffset in
            dayOffset % rule.interval == 0
        }
    }

    private func generateWeekly(reminder: Reminder, rule: RecurrenceRule, from start: Date, to end: Date, calendar: Calendar) -> [Date] {
        let startWeek = calendar.component(.weekOfYear, from: rule.startDate)
        return generateByDay(reminder: reminder, rule: rule, from: start, to: end, calendar: calendar) { _, day in
            let weekDelta = max(0, calendar.component(.weekOfYear, from: day) - startWeek)
            return weekDelta % rule.interval == 0 && calendar.component(.weekday, from: day) == calendar.component(.weekday, from: rule.startDate)
        }
    }

    private func generateMonthly(reminder: Reminder, rule: RecurrenceRule, from start: Date, to end: Date, calendar: Calendar) -> [Date] {
        let startComponents = calendar.dateComponents([.year, .month, .day], from: rule.startDate)
        return generateByDay(reminder: reminder, rule: rule, from: start, to: end, calendar: calendar) { _, day in
            let current = calendar.dateComponents([.year, .month, .day], from: day)
            let monthDelta = ((current.year ?? 0) - (startComponents.year ?? 0)) * 12 + ((current.month ?? 0) - (startComponents.month ?? 0))
            return monthDelta >= 0 && monthDelta % rule.interval == 0 && current.day == startComponents.day
        }
    }

    private func generateCustomWeekdays(reminder: Reminder, rule: RecurrenceRule, from start: Date, to end: Date, calendar: Calendar) -> [Date] {
        let weekdays = rule.selectedWeekdays.isEmpty ? [calendar.component(.weekday, from: rule.startDate)] : rule.selectedWeekdays
        return generateByDay(reminder: reminder, rule: rule, from: start, to: end, calendar: calendar) { _, day in
            weekdays.contains(calendar.component(.weekday, from: day))
        }
    }

    private func generateByDay(
        reminder: Reminder,
        rule: RecurrenceRule,
        from start: Date,
        to end: Date,
        calendar: Calendar,
        include: (Int) -> Bool
    ) -> [Date] {
        generateByDay(reminder: reminder, rule: rule, from: start, to: end, calendar: calendar) { dayOffset, _ in
            include(dayOffset)
        }
    }

    private func generateByDay(
        reminder: Reminder,
        rule: RecurrenceRule,
        from start: Date,
        to end: Date,
        calendar: Calendar,
        include: (Int, Date) -> Bool
    ) -> [Date] {
        let startDay = calendar.startOfDay(for: rule.startDate)
        let firstDay = max(calendar.startOfDay(for: start), startDay)
        let endDay = calendar.startOfDay(for: end)
        let time = calendar.dateComponents([.hour, .minute, .second], from: reminder.scheduleDate)
        var dates: [Date] = []
        var day = firstDay

        while day <= endDay {
            let dayOffset = calendar.dateComponents([.day], from: startDay, to: day).day ?? 0
            if dayOffset >= 0 && include(dayOffset, day), let occurrence = calendar.date(bySettingHour: time.hour ?? 0, minute: time.minute ?? 0, second: time.second ?? 0, of: day), occurrence >= start && occurrence <= end {
                dates.append(occurrence)
            }
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = nextDay
        }

        return dates
    }
}

private extension Calendar {
    func isDate(_ date: Date, inRangeFrom start: Date, to end: Date) -> Bool {
        date >= start && date <= end
    }
}
