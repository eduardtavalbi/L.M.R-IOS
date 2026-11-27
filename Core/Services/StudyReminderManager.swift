import Foundation
import UserNotifications

enum StudyReminderManager {
    static let notificationID = "lmr.daily-study-reminder"

    static func schedule(hour: Int, minute: Int) async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        guard granted else { return false }

        let content = UNMutableNotificationContent()
        content.title = "Время повторить слова"
        content.body = "Пара минут практики сегодня помогут сохранить прогресс."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        center.removePendingNotificationRequests(withIdentifiers: [notificationID])
        try await center.add(request)
        return true
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
    }
}
