//
//  NureSchedualApp.swift
//  NureSchedual
//
//  Created by Kostya Volkov on 11.01.2025.
//

import SwiftUI
import BackgroundTasks
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Проверяем, было ли приложение запущено из уведомления
        if let notificationPayload = launchOptions?[.remoteNotification] as? [String: AnyObject] {
            handleNotificationPayload(notificationPayload)
        }
        
        // Настраиваем делегат уведомлений
        UNUserNotificationCenter.current().delegate = self
        
        // Проверяем, есть ли входящее уведомление
        if let notification = launchOptions?[.userActivityDictionary] as? [String: Any],
           let userInfo = notification["UIApplicationLaunchOptionsUserActivityInfoKey"] as? [String: Any],
           let dateString = userInfo["first_change_date"] as? String,
           let date = ISO8601DateFormatter().date(from: dateString) {
            UserDefaults.standard.set(date.timeIntervalSince1970, forKey: "notification_selected_date")
            UserDefaults.standard.set(true, forKey: "should_navigate_to_date")
        }
        
        // Регистрируем задачу для фоновой проверки
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "KV-corporation.NureSchedual.schedulecheck",
            using: nil
        ) { task in
            self.handleScheduleCheck(task: task as! BGAppRefreshTask)
        }
        
        // Регистрируем для фоновых уведомлений
        application.registerForRemoteNotifications()
        
        // Запрашиваем разрешение на уведомления с дополнительными опциями
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge, .provisional, .criticalAlert]
        ) { granted, error in
            if granted {
                print("✅ Разрешение на уведомления получено")
            } else {
                print("❌ Разрешение на уведомления не получено")
                if let error = error {
                    print("Ошибка: \(error.localizedDescription)")
                }
            }
        }
        
        return true
    }
    
    private func handleNotificationPayload(_ payload: [String: AnyObject]) {
        if let dateString = payload["first_change_date"] as? String,
           let date = ISO8601DateFormatter().date(from: dateString) {
            UserDefaults.standard.set(date.timeIntervalSince1970, forKey: "notification_selected_date")
            UserDefaults.standard.set(true, forKey: "should_navigate_to_date")
        }
    }
    
    func handleScheduleCheck(task: BGAppRefreshTask) {
        // Получаем сохраненный ID группы
        if let groupId = UserDefaults.standard.object(forKey: "selectedGroupId") as? Int {
            let scheduleChecker = ScheduleChecker()
            
            // Добавляем обработчик завершения задачи
            task.expirationHandler = {
                task.setTaskCompleted(success: false)
            }
            
            // Проверяем изменения
            scheduleChecker.checkScheduleChanges(groupId: groupId) {
                // Планируем следующую проверку
                self.scheduleNextCheck()
                task.setTaskCompleted(success: true)
            }
        }
    }
    
    func scheduleNextCheck() {
        let request = BGAppRefreshTaskRequest(identifier: "KV-corporation.NureSchedual.schedulecheck")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600) // Проверка каждый час
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Не удалось запланировать проверку: \(error)")
        }
    }
    
    // Добавляем методы делегата для обработки уведомлений
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Показываем уведомление даже когда приложение активно
        completionHandler([.banner, .sound, .badge])
    }
    
    // Обработка нажатия на уведомление когда приложение запущено
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == "VIEW_ACTION" || response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            if let dateString = response.notification.request.content.userInfo["first_change_date"] as? String,
               let date = ISO8601DateFormatter().date(from: dateString) {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: "notification_selected_date")
                UserDefaults.standard.set(true, forKey: "should_navigate_to_date")
                NotificationCenter.default.post(name: .openScheduleAtDate, object: nil)
            }
        }
        completionHandler()
    }
}

// Добавляем новое уведомление
extension Notification.Name {
    static let openScheduleAtDate = Notification.Name("openScheduleAtDate")
}

@main
struct NureSchedualApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Состояние для отображения индикатора загрузки
    @State private var showLoading = true

    init() {
        // Принудительная установка украинского языка
        UserDefaults.standard.set(["uk"], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Создаем градиентный слой
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.08, green: 0.06, blue: 0.11, alpha: 1.0).cgColor,
            UIColor(red: 0.08, green: 0.06, blue: 0.12, alpha: 1.0).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradient.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 82)
        
        // Создаем изображение из градиента
        if let gradientImage = UIImage.from(gradient: gradient) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundImage = gradientImage
            appearance.backgroundColor = .clear // Убедитесь, что backgroundColor прозрачный
            
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Основное содержимое приложения внутри NavigationStack
                NavigationStack {
                    ContentView()
                }
            }
            .onAppear {
            }
        }
    }
}

