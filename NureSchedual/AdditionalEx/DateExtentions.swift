//
//  DateExtentions.swift
//  NureSchedual
//
//  Created by Kostya Volkov on 11.01.2025.
//

import SwiftUI
extension Date {
    func format(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "uk_UA") // Украинская локаль
        formatter.timeZone = TimeZone.current // Устанавливаем текущий часовой пояс
        return formatter.string(from: self)
    }

    
    var isToday:Bool{
        return Calendar.current.isDateInToday(self)
    }
    
    
    // Функция для сравнения только дня, месяца и года
    /// Проверяет, совпадает ли текущий час с часом этой даты.
        var isSameHour: Bool {
            let calendar = Calendar.current
            return calendar.isDate(self, equalTo: Date(), toGranularity: .hour)
        }
        
        /// Проверяет, является ли дата прошедшей (меньше текущей).
        var isPast: Bool {
            return self < Date()
        }
    func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        Calendar.current.isDate(date1, inSameDayAs: date2)
    }
    
    func createNextWeek() -> [WeekDay] {
            let calendar = Calendar.current
            let startOfCurrentWeek = self.startOfWeek()
            guard let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfCurrentWeek) else {
                return []
            }
            return fetchWeek(nextWeekStart)
        }

        func createPreviousWeek() -> [WeekDay] {
            let calendar = Calendar.current
            let startOfCurrentWeek = self.startOfWeek()
            guard let previousWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: startOfCurrentWeek) else {
                return []
            }
            return fetchWeek(previousWeekStart)
        }

    func startOfWeek() -> Date {
        let calendar = Calendar.current
        // Находим компоненты для начала недели
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        // Возвращаем дату начала недели
        return calendar.date(from: components) ?? self
    }
    struct WeekDay: Identifiable {
            var id: UUID = .init()
            var date: Date
        }
    
    func fetchWeek(_ date: Date = .init()) -> [WeekDay] {
        let calendar = Calendar.current
        // Берём начало недели
        let startOfWeek = date.startOfWeek()

        var week: [WeekDay] = []
        // Строим неделю с первого дня недели
        (0..<7).forEach { offset in
            if let day = calendar.date(byAdding: .day, value: offset, to: startOfWeek) {
                week.append(WeekDay(date: day))
            }
        }
        return week
    }
}
