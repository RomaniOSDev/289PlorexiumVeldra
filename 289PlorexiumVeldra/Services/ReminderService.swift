import Foundation
import UserNotifications

enum ReminderService {
    private static let identifier = "ww.daily.log.reminder"

    static func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    static func schedule(settings: ReminderSettings) {
        cancel()
        guard settings.enabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Plorexium Veldra"
        content.body = "Did you forget to log today's temperature?"
        content.sound = HapticService.soundEnabled ? .default : nil

        var components = DateComponents()
        components.hour = settings.hour
        components.minute = settings.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
