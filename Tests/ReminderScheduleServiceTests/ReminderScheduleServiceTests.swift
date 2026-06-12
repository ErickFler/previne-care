import XCTest
@testable import PrevineCareCore

final class ReminderScheduleServiceTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testDailyRecurrenceGeneratesFutureDates() {
        let start = date(2026, 6, 1, 8, 0)
        let reminder = Reminder(
            title: "Medicine",
            type: .medication,
            scheduleDate: start,
            recurrenceRule: RecurrenceRule(frequency: .daily, startDate: start)
        )

        let dates = ReminderScheduleService().occurrences(
            for: reminder,
            from: date(2026, 6, 1, 0, 0),
            to: date(2026, 6, 3, 23, 59),
            calendar: calendar
        )

        XCTAssertEqual(dates.count, 3)
        XCTAssertTrue(calendar.isDate(dates[1], inSameDayAs: date(2026, 6, 2, 8, 0)))
    }

    func testWeeklyRecurrenceGeneratesMatchingWeekday() {
        let start = date(2026, 6, 1, 9, 0)
        let reminder = Reminder(
            title: "Walk",
            type: .movement,
            scheduleDate: start,
            recurrenceRule: RecurrenceRule(frequency: .weekly, startDate: start)
        )

        let dates = ReminderScheduleService().occurrences(
            for: reminder,
            from: date(2026, 6, 1, 0, 0),
            to: date(2026, 6, 15, 23, 59),
            calendar: calendar
        )

        XCTAssertEqual(dates.count, 3)
    }

    func testCustomWeekdaysGeneratesSelectedDays() {
        let start = date(2026, 6, 1, 10, 0)
        let reminder = Reminder(
            title: "Hydration",
            type: .hydration,
            scheduleDate: start,
            recurrenceRule: RecurrenceRule(frequency: .customDaysOfWeek, selectedWeekdays: [2, 4, 6], startDate: start)
        )

        let dates = ReminderScheduleService().occurrences(
            for: reminder,
            from: date(2026, 6, 1, 0, 0),
            to: date(2026, 6, 7, 23, 59),
            calendar: calendar
        )

        XCTAssertEqual(dates.count, 3)
    }

    func testOccurrenceCompletionDoesNotCompleteReminderDefinition() {
        let reminder = Reminder(title: "Medicine", type: .medication, scheduleDate: Date())
        let occurrence = ReminderOccurrence(reminderId: reminder.id, occurrenceDate: Date(), status: .completed)

        XCTAssertEqual(occurrence.status, .completed)
        XCTAssertEqual(reminder.status, .pending)
    }

    func testSafePlaceEditCanPreserveIdentifier() {
        let id = UUID()
        let updated = SafePlace(id: id, name: "Home updated", type: .home, latitude: 25.1, longitude: -100.1, radiusMeters: 300)

        XCTAssertEqual(updated.id, id)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
