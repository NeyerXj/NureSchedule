//
//  NureSchedualApp.swift
//  NureSchedual
//
//  Created by Kostya Volkov on 11.01.2025.
//

import SwiftUI

@main
struct NureSchedualApp: App {
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

