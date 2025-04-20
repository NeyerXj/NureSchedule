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
        
        // Настройка фоновых задач
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(
                forTaskWithIdentifier: "KV-corporation.NureSchedual.schedulecheck",
                using: nil
            ) { task in
                self.handleScheduleCheck(task: task as! BGAppRefreshTask)
            }
        }
        
        // Запрашиваем все возможные разрешения для уведомлений
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound, .provisional, .criticalAlert]
        ) { granted, error in
            if granted {
                print("✅ Все разрешения на уведомления получены")
                // Регистрируем для пуш-уведомлений
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("❌ Разрешения на уведомления отклонены: \(error?.localizedDescription ?? "неизвестная ошибка")")
            }
        }
        
        // Включаем фоновое обновление
        application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        
        return true
    }
    
    private func handleNotificationPayload(_ payload: [String: AnyObject]) {
        if let dateString = payload["first_change_date"] as? String,
           let date = ISO8601DateFormatter().date(from: dateString) {
            UserDefaults.standard.set(date.timeIntervalSince1970, forKey: "notification_selected_date")
            UserDefaults.standard.set(true, forKey: "should_navigate_to_date")
        }
    }
    
    // Обработчик фоновой задачи
    private func handleScheduleCheck(task: BGAppRefreshTask) {
        print("🔄 Начало фоновой проверки расписания")
        
        // Устанавливаем обработчик истечения времени
        task.expirationHandler = {
            print("⚠️ Время выполнения фоновой задачи истекло")
            task.setTaskCompleted(success: false)
        }
        
        // Проверяем сохраненные данные группы/преподавателя
        if let groupId = UserDefaults.standard.object(forKey: "selectedGroupId") as? Int {
            print("📱 Обновление расписания для группы ID: \(groupId)")
            
            // Здесь добавьте вашу логику обновления расписания
            // Например, вызов API и обновление уведомлений
            
            // После успешного обновления
            self.scheduleNextCheck()
            task.setTaskCompleted(success: true)
        } else {
            print("❌ Нет сохраненной группы для обновления")
            task.setTaskCompleted(success: false)
        }
    }
    
    // Планирование следующей проверки
    private func scheduleNextCheck() {
        let request = BGAppRefreshTaskRequest(identifier: "KV-corporation.NureSchedual.schedulecheck")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 900) // Проверка каждые 15 минут
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Следующая фоновая проверка запланирована")
        } catch {
            print("❌ Ошибка планирования следующей проверки: \(error.localizedDescription)")
        }
    }
    
    // Добавляем методы делегата для обработки уведомлений
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Показываем уведомление даже когда приложение активно
        completionHandler([.banner, .sound])
    }
    
    // Обработка нажатия на уведомление когда приложение запущено
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("👆 Пользователь нажал на уведомление: \(response.notification.request.identifier)")
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
    
    // Обработка фоновых обновлений
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("🔄 Начало фонового обновления")
        
        // Проверяем сохраненные данные
        if let groupId = UserDefaults.standard.object(forKey: "selectedGroupId") as? Int {
            // Обновляем расписание и уведомления
            fetchAndUpdateSchedule(for: groupId) { success in
                completionHandler(success ? .newData : .failed)
            }
        } else {
            completionHandler(.noData)
        }
    }
    
    private func fetchAndUpdateSchedule(for groupId: Int, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://api.mindenit.org/schedule/groups/\(groupId)") else {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                completion(false)
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let scheduleItems = try decoder.decode([ScheduleItem].self, from: data)
                
                // Сохраняем в кэш
                CacheManager.save(data: data, filename: "schedule_group_\(groupId).json")
                UserDefaults.standard.set(Date(), forKey: "cache_date_\(groupId)")
                
                // Обновляем уведомления
                let tasks = processScheduleData(scheduleItems: scheduleItems)
                NotificationManager.shared.cancelAllNotifications()
                tasks.forEach { task in
                    NotificationManager.shared.scheduleLessonNotification(for: task)
                }
                
                completion(true)
            } catch {
                print("❌ Ошибка обновления расписания: \(error)")
                completion(false)
            }
        }.resume()
    }
}

// Добавляем новое уведомление
extension Notification.Name {
    static let openScheduleAtDate = Notification.Name("openScheduleAtDate")
}

@main
struct NureSchedualApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var promotionalManager = PromotionalManager.shared
    @AppStorage("hasSeenFeatureTour") private var hasSeenFeatureTour = false
    @State private var showFeatureTour = false
    @State private var showOnboarding = false
    
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
                
                // Показываем туториал для новых пользователей
                if !hasSeenFeatureTour {
                    FeatureTourView(isShowingTour: $showFeatureTour)
                        .onChange(of: showFeatureTour) { newValue in
                            if !newValue {
                                hasSeenFeatureTour = true
                                showOnboarding = true
                            }
                        }
                }
                
                // Показываем онбординг после туториала
                if showOnboarding {
                    OnboardingOverlayView(isShowingOnboarding: $showOnboarding, onComplete: {
                        promotionalManager.checkAndShowPromos()
                    })
                }
                
                // Показываем промо статистики
                if promotionalManager.shouldShowStatisticsPromo {
                    StatisticsPromotionView(isPresented: $promotionalManager.shouldShowStatisticsPromo)
                }
                
                // Показываем промо Telegram
                if promotionalManager.shouldShowTelegramPromo {
                    TelegramPromotionView(isPresented: $promotionalManager.shouldShowTelegramPromo)
                }
            }
            .onAppear {
                if hasSeenFeatureTour {
                    promotionalManager.checkAndShowPromos()
                } else {
                    showFeatureTour = true
                }
            }
        }
    }
}

