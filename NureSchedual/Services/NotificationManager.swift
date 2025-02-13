import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    // Планирование уведомления о начале пары
    func scheduleLessonNotification(for task: Task) {
        guard UserDefaults.standard.bool(forKey: "isLessonStartNotificationsEnabled"),
              task.type != "Break" else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🎓 Скоро початок пари"
        content.body = """
            📚 \(task.title)
            🏛 Аудиторія: \(task.auditory)
            ⏰ Початок: \(formatTime(task.date))
            """
        content.sound = .default
        
        // Время уведомления (за 10 минут до начала)
        let notificationTime = task.date.addingTimeInterval(-600) // 10 минут
        
        // Проверяем, не прошло ли время уведомления
        if notificationTime > Date() {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: notificationTime)
            
            var trigger: UNNotificationTrigger
            
            if let timeZone = TimeZone.current.secondsFromGMT() as? Double {
                // Корректируем время с учетом часового пояса
                let adjustedDate = notificationTime.addingTimeInterval(-timeZone)
                trigger = UNCalendarNotificationTrigger(
                    dateMatching: calendar.dateComponents([.hour, .minute], from: adjustedDate),
                    repeats: false
                )
            } else {
                trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            }
            
            let request = UNNotificationRequest(
                identifier: "lesson_\(task.id)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    // Уведомление об изменениях в расписании
    func scheduleScheduleChangeNotification(changes: [ScheduleChange]) {
        guard UserDefaults.standard.bool(forKey: "isScheduleChangesNotificationsEnabled") else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "📅 Зміни у розкладі"
        content.categoryIdentifier = "schedule_change"
        content.interruptionLevel = .timeSensitive
        
        // Группируем изменения по датам
        let groupedChanges = Dictionary(grouping: changes) { change in
            Calendar.current.startOfDay(for: change.date)
        }
        
        // Находим ближайшую дату
        let nearestDate = changes
            .map { $0.date }
            .min { $0.timeIntervalSinceNow < $1.timeIntervalSinceNow }
        
        if let nearestDate = nearestDate {
            let iso8601Formatter = ISO8601DateFormatter()
            content.userInfo = ["first_change_date": iso8601Formatter.string(from: nearestDate)]
        }
        
        // Форматируем текст уведомления
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "uk_UA")
        dateFormatter.dateStyle = .medium
        
        var body = "Змінено розклад на наступні дати:\n"
        for date in groupedChanges.keys.sorted() {
            body += "\n📆 \(dateFormatter.string(from: date))"
        }
        
        content.body = body
        content.sound = .defaultCritical
        
        // Действия уведомления
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "Переглянути",
            options: .foreground
        )
        
        let category = UNNotificationCategory(
            identifier: "schedule_change",
            actions: [viewAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // Отмена всех уведомлений
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    // Обновляем существующий метод
    func cancelAllLessonNotifications() {
        // Ищем только уведомления о начале пар (по идентификатору)
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let lessonNotifications = requests.filter { $0.identifier.starts(with: "lesson_") }
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: lessonNotifications.map { $0.identifier }
            )
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
} 