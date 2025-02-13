//
//  SettingsButton.swift
//  NureSchedual
//
//  Created by Kostya Volkov on 17.01.2025.
//

import SwiftUI
  struct SettingsButton: View {
        @Binding var showSettings: Bool // Биндинг для управления состоянием отображения настроек
    
        var body: some View {
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showSettings = true
                }
            }) {
                Image(systemName: "gearshape.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36) // Увеличиваем размер иконки
                    .foregroundColor(.white) // Белый цвет иконки
                    .padding(10) // Увеличиваем padding для фона
                    .background(Color.gray.opacity(0.4)) // Светло-серый фон
                    .clipShape(Circle()) // Обрезаем фон до формы круга
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
            }
            .accessibilityLabel("Настройки")
        }
    }
