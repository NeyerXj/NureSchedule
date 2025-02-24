import Foundation
import SwiftUI

struct ScheduleTask: Identifiable, Equatable {
    let id: String
    let title: String
    let fullTitle: String
    let type: String
    let date: Date
    let auditory: String
    let teacher: String
    let tint: Color
    var isCompleted: Bool = false
    
    // Вычисляемое свойство для caption
    var caption: String {
        return "\(type) • \(auditory)"
    }
    
    // Реализация Equatable
    static func == (lhs: ScheduleTask, rhs: ScheduleTask) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.fullTitle == rhs.fullTitle &&
               lhs.type == rhs.type &&
               lhs.date == rhs.date &&
               lhs.auditory == rhs.auditory &&
               lhs.teacher == rhs.teacher &&
               lhs.isCompleted == rhs.isCompleted
    }
    
    // Основной инициализатор
    init(id: String = UUID().uuidString,
         title: String,
         fullTitle: String? = nil,
         type: String,
         date: Date,
         auditory: String,
         teacher: String = "",
         tint: Color = .blue,
         isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.fullTitle = fullTitle ?? title
        self.type = type
        self.date = date
        self.auditory = auditory
        self.teacher = teacher
        self.tint = tint
        self.isCompleted = isCompleted
    }
    
    // Инициализатор для создания из ScheduleItem (для групп)
    init(from scheduleItem: ScheduleItem) {
        self.init(
            id: "\(scheduleItem.id)",
            title: scheduleItem.subject.title,
            fullTitle: scheduleItem.subject.title,
            type: scheduleItem.type,
            date: Date(timeIntervalSince1970: scheduleItem.startTime),
            auditory: scheduleItem.auditory,
            tint: Self.getTintColor(for: scheduleItem.type)
        )
    }
    
    // Инициализатор для создания из TeacherAPI
    init(from teacherItem: TeacherAPI) {
        self.init(
            id: "\(teacherItem.id)",
            title: teacherItem.subject.title,
            fullTitle: teacherItem.subject.title,
            type: teacherItem.type,
            date: Date(timeIntervalSince1970: teacherItem.startTime),
            auditory: teacherItem.auditory,
            teacher: "",
            tint: Self.getTintColor(for: teacherItem.type)
        )
    }
    
    // Вспомогательный метод для определения цвета в зависимости от типа пары
    private static func getTintColor(for type: String) -> Color {
        switch type.lowercased() {
        case "лк": return .blue
        case "лб": return .green
        case "пз": return .orange
        default: return .gray
        }
    }
} 