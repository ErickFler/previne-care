import Foundation
@preconcurrency import UserNotifications

@MainActor
public final class LocalNotificationService {
    public static let shared = LocalNotificationService()

    private init() {}

    public func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        @unknown default:
            return false
        }
    }

    public func scheduleReminder(_ reminder: Reminder) async {
        guard reminder.status == .pending else { return }
        guard await requestAuthorizationIfNeeded() else { return }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.scheduleDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: reminder.repeats)

        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.instructions.isEmpty ? "It is time for this routine." : reminder.instructions
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "reminder.\(reminder.id.uuidString)",
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    public func notifyCaregiver(riskEvent: RiskEvent, patientName: String) async {
        guard riskEvent.riskLevel == .medium || riskEvent.riskLevel == .high else { return }
        guard await requestAuthorizationIfNeeded() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Check on \(patientName)"
        content.body = riskEvent.reasons.first ?? "PrevineCare detected a possible risk."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "risk.\(riskEvent.id.uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    public func cancelReminder(id: UUID) {
        let identifier = "reminder.\(id.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
    }
}
