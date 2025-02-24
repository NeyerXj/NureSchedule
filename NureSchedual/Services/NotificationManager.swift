import Foundation
import SwiftUICore
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    // Добавим свойства для отслеживания последнего обновления
    private var lastScheduleHash: Int = 0
    private var lastUpdateTime: Date = Date()
    private let minimumUpdateInterval: TimeInterval = 300 // 5 минут
    
    // Добавим свойство для отслеживания состояния загрузки
    private var isLoadingNotifications: Bool = false
    
    // Добавим свойство для отслеживания текущего ID
    private var currentScheduleId: Int?
    private var currentScheduleType: ScheduleType = .group
    
    // Добавим свойство для хранения хеша последнего расписания
    private var lastScheduleHashString: String = ""
    
    private enum ScheduleType {
        case group
        case teacher
    }
    
    private init() {
        // Запрашиваем разрешения при инициализации
        requestNotificationPermissions()
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Разрешения на уведомления получены")
            } else {
                print("❌ Разрешения на уведомления отклонены")
                if let error = error {
                    print("❌ Ошибка: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Планирование уведомления о начале пары
    func scheduleLessonNotification(for task: Task) {
        guard task.title != "Break" else { return }
        
        let calendar = Calendar.current
        let currentDate = Date()
        let startDate = calendar.startOfDay(for: currentDate)
        let endDate = calendar.date(byAdding: .day, value: 7, to: startDate)!
        
        // Финальная проверка даты
        guard task.date > currentDate && task.date < endDate else {
//            print("⚠️ Пропуск уведомления - дата вне периода 7 дней: \(formatDateTime(task.date))")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "🎓 Скоро початок пари"
        content.body = """
            📚 \(task.title)
            🏛 Аудиторія: \(task.auditory)
            ⏰ Початок: \(formatTime(task.date))
            """
        content.sound = .default
        
        // Время уведомления - за 10 минут до начала
        let notificationTime = calendar.date(byAdding: .minute, value: -10, to: task.date) ?? task.date
        
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notificationTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "lesson_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Ошибка планирования уведомления: \(error.localizedDescription)")
            } else {
                print(currentDate)
                print("✅ Уведомление запланировано на \(self.formatDateTime(notificationTime))")
            }
        }
    }
    
    // Уведомление об изменениях в расписании
    func scheduleScheduleChangeNotification(changes: [ScheduleChange]) {
        // Проверяем общий переключатель и переключатель для конкретного типа уведомлений
        guard UserDefaults.standard.bool(forKey: "isNotificationsEnabled") &&
              UserDefaults.standard.bool(forKey: "isScheduleChangesNotificationsEnabled") else {
            return
        }
        
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
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("📱 Статус уведомлений:")
            print("- Авторизация: \(settings.authorizationStatus.rawValue)")
            print("- Уведомления в центре: \(settings.notificationCenterSetting.rawValue)")
            print("- Звук: \(settings.soundSetting.rawValue)")
            print("- Бейдж: \(settings.badgeSetting.rawValue)")
            print("- Временные: \(settings.providesAppNotificationSettings)")
        }
    }
    
    func scheduleTestNotification() {
        // Временно включаем уведомления для теста
        UserDefaults.standard.set(true, forKey: "isNotificationsEnabled")
        
        let content = UNMutableNotificationContent()
        content.title = "🔔 Тестове повідомлення"
        content.body = "Перевірка роботи повідомлень"
        content.sound = .default
        content.threadIdentifier = "test"
        content.interruptionLevel = .timeSensitive
        
        // Создаем уведомление через 5 секунд
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "test_notification",
            content: content,
            trigger: trigger
        )
        
        print("🔄 Планирование тестового уведомления")
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Ошибка планирования тестового уведомления: \(error)")
            } else {
                print("✅ Тестовое уведомление запланировано")
            }
        }
    }
    
    // Добавим функцию для создания тестового уведомления о паре
    func scheduleTestLessonNotification() {
        // Временно включаем уведомления для теста
        UserDefaults.standard.set(true, forKey: "isNotificationsEnabled")
        UserDefaults.standard.set(true, forKey: "isLessonStartNotificationsEnabled")
        
        // Создаем тестовую пару через 2 минуты от текущего времени
        let currentDate = Date()
        let testDate = Calendar.current.date(byAdding: .minute, value: 2, to: currentDate) ?? currentDate
        
        print("⏰ Текущее время: \(formatDateTime(currentDate))")
        print("📅 Планируемое время пары: \(formatDateTime(testDate))")
        
        let testTask = Task(
            title: "Тестова пара",
            fullTitle: "Тестова пара (повна назва)",
            caption: "Тест",
            date: testDate,
            tint: .blue,
            auditory: "Test-101",
            type: "Лекція",
            teacher: "Тестовий викладач"
        )
        
        // Создаем тестовое уведомление через 30 секунд
        let content = UNMutableNotificationContent()
        content.title = "🎓 Скоро початок пари"
        content.body = """
            �� \(testTask.title)
            🏛 Аудиторія: \(testTask.auditory)
            ⏰ Початок: \(formatTime(testTask.date))
            """
        content.sound = .default
        content.threadIdentifier = "lessons"
        content.interruptionLevel = .timeSensitive
        
        // Устанавливаем время уведомления на 30 секунд от текущего времени
        let notificationTime = Calendar.current.date(byAdding: .second, value: 30, to: currentDate) ?? currentDate
        
        print("📋 Детали тестового уведомления:")
        print("- Текущее время: \(formatDateTime(currentDate))")
        print("- Время пары: \(formatDateTime(testDate))")
        print("- Время уведомления: \(formatDateTime(notificationTime))")
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: notificationTime)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "test_lesson_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Ошибка планирования тестового уведомления: \(error.localizedDescription)")
            } else {
                print("✅ Тестовое уведомление о паре запланировано на \(self.formatDateTime(notificationTime))")
            }
        }
    }
    
    // Добавим вспомогательный метод для форматирования даты и времени
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        return formatter.string(from: date)
    }
    
    // Обновляем метод shouldUpdateNotifications
    private func shouldUpdateNotifications(for tasks: [Task]) -> Bool {
        let currentHash = tasks.reduce("") { hash, task in
            hash + "\(task.date.timeIntervalSince1970)_\(task.title)_\(task.auditory)"
        }
        
        let scheduleChanged = currentHash != lastScheduleHashString
        
        if scheduleChanged {
            print("📝 Обнаружены изменения в расписании")
            lastScheduleHashString = currentHash
            return true
        }
        
        print("🔄 Расписание не изменилось, пропускаем обновление уведомлений")
        return false
    }
    
    // Обновляем метод fetchAndProcessSchedule
    private func fetchAndProcessSchedule(from url: URL) {
        // Проверяем, не выполняется ли уже загрузка
        guard !isLoadingNotifications else {
            print("🔄 Загрузка уведомлений уже выполняется")
            return
        }
        
        isLoadingNotifications = true
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            defer { 
                self.isLoadingNotifications = false
                print("✅ Загрузка уведомлений завершена")
            }
            
            if let error = error {
                print("❌ Ошибка загрузки расписания: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("❌ Нет данных расписания")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                let scheduleItems = try decoder.decode([ScheduleItem].self, from: data)
                
                // Проверяем, что получили данные
                guard !scheduleItems.isEmpty else {
                    print("⚠️ Получено пустое расписание")
                    return
                }
                
                print("🔄 Вызов processScheduleData")
                let tasks = self.processScheduleData(scheduleItems: scheduleItems)
                
                if self.shouldUpdateNotifications(for: tasks) {
                    print("🔄 Вызов updateNotificationsForTasks")
                    self.updateNotificationsForTasks(tasks)
                }
            } catch {
                print("❌ Ошибка обработки расписания: \(error.localizedDescription)")
                print("Детали ошибки: \(error)")
            }
        }.resume()
    }
    
    // Выделим обновление уведомлений в отдельный метод
    private func updateNotificationsForTasks(_ tasks: [Task]) {
        let calendar = Calendar.current
        let currentDate = Date()
        let startDate = calendar.startOfDay(for: currentDate)
        let endDate = calendar.date(byAdding: .day, value: 7, to: startDate)!
        
        print("\n📅 Планирование уведомлений:")
        print("- Текущая дата: \(formatDateTime(currentDate))")
        print("- Период: \(formatDateTime(startDate)) - \(formatDateTime(endDate))")
        
        // Отменяем все существующие уведомления
        cancelAllNotifications()
        
        // Дополнительная проверка перед созданием уведомлений
        let validTasks = tasks.filter { task in
            let taskStartOfDay = calendar.startOfDay(for: task.date)
            let isValid = taskStartOfDay >= startDate && taskStartOfDay < endDate
            
            print("\n🔍 Проверка задачи:")
            print("- Предмет: \(task.title)")
            print("- Дата: \(formatDateTime(task.date))")
            print("- Валидна: \(isValid)")
            
            return isValid
        }
        
        print("\n📊 Планирование:")
        print("- Всего задач: \(tasks.count)")
        print("- Прошло проверку: \(validTasks.count)")
        
        // Создаем уведомления только для валидных задач
        for task in validTasks {
            scheduleLessonNotification(for: task)
        }
    }
    
    // Функция для проверки запланированных уведомлений
    func checkScheduledNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { [self] requests in
            let calendar = Calendar.current
            let currentDate = Date()
            let endDate = calendar.date(byAdding: .day, value: 7, to: currentDate) ?? currentDate
            
            // Фильтруем уведомления только на ближайшие 7 дней
            let filteredRequests = requests.filter { request in
                guard let trigger = request.trigger as? UNCalendarNotificationTrigger else { return false }
                let components = trigger.dateComponents
                guard let date = calendar.date(from: components) else { return false }
                return date > currentDate && date <= endDate
            }
            
            print("\n📋 Запланированные уведомления на ближайшие 7 дней:")
            print("- Текущая дата: \(self.formatDateTime(currentDate))")
            print("- Конец периода: \(self.formatDateTime(endDate))")
            print("- Всего уведомлений: \(filteredRequests.count)")
            
            // Группируем по дням
            let groupedRequests = Dictionary(grouping: filteredRequests) { request -> Date in
                if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                   let date = calendar.date(from: trigger.dateComponents) {
                    return calendar.startOfDay(for: date)
                }
                return currentDate
            }
            
            // Выводим только уведомления в пределах недели
            for (date, requests) in groupedRequests.sorted(by: { $0.key < $1.key }) {
                print("\n📆 \(self.formatDateTime(date)):")
                for request in requests {
                    if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                        print("🔔 \(request.content.title)")
                        print("📝 \(request.content.body)")
                        print("⏰ \(self.formatDateTime(calendar.date(from: trigger.dateComponents) ?? date))")
                        print("---")
                    }
                }
            }
        }
    }
    
    private func processScheduleData(scheduleItems: [ScheduleItem]) -> [Task] {
        var tasks: [Task] = []
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Устанавливаем точные границы периода в 7 дней
        let startDate = calendar.startOfDay(for: currentDate)
        let endDate = calendar.date(byAdding: .day, value: 7, to: startDate)!
        
        print("\n🔄 Обработка расписания:")
        print("- Текущая дата: \(formatDateTime(currentDate))")
        print("- Начало периода: \(formatDateTime(startDate))")
        print("- Конец периода: \(formatDateTime(endDate))")
        print("- Всего пар из API: \(scheduleItems.count)")
        
        // Фильтруем элементы
        let filteredItems = scheduleItems.compactMap { item -> (ScheduleItem, Date)? in
            let itemDate = Date(timeIntervalSince1970: TimeInterval(item.startTime))
            let itemStartOfDay = calendar.startOfDay(for: itemDate)
            
            // Строгая проверка на период в 7 дней
            if itemStartOfDay >= startDate && itemStartOfDay < endDate {
                print("\n✅ Пара в пределах 7 дней:")
                print("- Предмет: \(item.subject.title)")
                print("- Дата: \(formatDateTime(itemDate))")
                return (item, itemDate)
            } else {
                print("\n❌ Пара вне периода 7 дней:")
                print("- Предмет: \(item.subject.title)")
                print("- Дата: \(formatDateTime(itemDate))")
                return nil
            }
        }.sorted { $0.1 < $1.1 }
        
        // Создаем задачи
        for (item, date) in filteredItems {
            let task = Task(
                title: item.subject.brief,
                fullTitle: item.subject.title,
                caption: item.type,
                date: date,
                tint: getTintColor(for: item.type),
                auditory: item.auditory,
                type: item.type,
                teacher: item.teachers.first?.fullName ?? "Не указан"
            )
            tasks.append(task)
        }
        
        print("\n📊 Итоги:")
        print("- Всего пар: \(scheduleItems.count)")
        print("- Отфильтровано на 7 дней: \(tasks.count)")
        
        return tasks
    }
    
    // Вспомогательная функция для определения цвета в зависимости от типа пары
    private func getTintColor(for type: String) -> Color {
        switch type.lowercased() {
        case "лекція", "лекция":
            return .blue
        case "практика", "практическое":
            return .green
        case "лабораторна", "лабораторная":
            return .orange
        case "консультація", "консультация":
            return .purple
        case "екзамен", "экзамен":
            return .red
        default:
            return .blue
        }
    }
    
    // Обновляем метод updateScheduleNotifications
    func updateScheduleNotifications(force: Bool = false) {
        // Проверяем, выполняется ли уже обновление
        guard !isLoadingNotifications else {
            print("⏳ Обновление уведомлений уже выполняется")
            return
        }
        
        if force {
            // Сбрасываем состояние при принудительном обновлении
            lastScheduleHashString = ""
            currentScheduleId = nil
            print("🔄 Принудительное обновление уведомлений")
        }
        
        let isTeacherMode = UserDefaults.standard.bool(forKey: "isTeacherMode")
        
        // Проверяем, не загружаем ли мы то же самое расписание
        if !force {
            if isTeacherMode {
                if let teacherId = UserDefaults.standard.object(forKey: "savedTeachersId") as? Int,
                   currentScheduleId == teacherId && currentScheduleType == .teacher {
                    print("✅ Расписание преподавателя уже актуально")
                    return
                }
            } else {
                if let groupId = UserDefaults.standard.object(forKey: "selectedGroupId") as? Int,
                   currentScheduleId == groupId && currentScheduleType == .group {
                    print("✅ Расписание группы уже актуально")
                    return
                }
            }
        }
        
        // Обновляем только при смене режима или принудительном обновлении
        if isTeacherMode {
            if let teacherId = UserDefaults.standard.object(forKey: "savedTeachersId") as? Int {
                currentScheduleId = teacherId
                currentScheduleType = .teacher
                fetchAndScheduleNotifications(forTeacherId: teacherId)
            }
        } else {
            if let groupId = UserDefaults.standard.object(forKey: "selectedGroupId") as? Int {
                currentScheduleId = groupId
                currentScheduleType = .group
                fetchAndScheduleNotifications(forGroupId: groupId)
            }
        }
    }
    
    private func fetchAndScheduleNotifications(forGroupId groupId: Int) {
        print("📅 Обновление уведомлений для группы ID: \(groupId)")
        
        guard let url = URL(string: "https://api.mindenit.org/schedule/groups/\(groupId)") else {
            print("❌ Неверный URL для группы")
            return
        }
        
        fetchAndProcessSchedule(from: url)
    }
    
    private func fetchAndScheduleNotifications(forTeacherId teacherId: Int) {
        print("📅 Обновление уведомлений для преподавателя ID: \(teacherId)")
        
        guard let url = URL(string: "https://api.mindenit.org/schedule/teachers/\(teacherId)") else {
            print("❌ Неверный URL для преподавателя")
            return
        }
        
        fetchAndProcessSchedule(from: url)
    }
} 
