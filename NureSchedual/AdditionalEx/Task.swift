import SwiftUI

// Модель данных для расписания из API
struct ScheduleItem: Identifiable, Decodable {
    let id: Int?
    let numberPair: Int
    let subject: Subject
    let startTime: TimeInterval
    let endTime: TimeInterval
    let auditory: String
    let type: String
    let teachers: [Teacher]
    let groups: [Group]
    
    struct Subject: Decodable {
        let id: Int
        let title: String
        let brief: String
    }

    struct Teacher: Decodable {
        let id: Int
        let shortName: String
        let fullName: String
    }

    struct Group: Decodable {
        let id: Int
        let name: String
    }
}

struct TeacherAPI: Identifiable, Decodable {
    let id: Int?
    let name: String? // Зроблено опціональним, якщо поле `name` не завжди присутнє
    let startTime: TimeInterval
    let endTime: TimeInterval
    let auditory: String
    let type: String
    let subject: Subject
    let groups: [Group] // Змінено з `Groups` на масив `[Group]`
    
    struct Subject: Decodable {
        let id: Int
        let title: String
        let brief: String // Виправлено з `breif` на `brief`
        
        enum CodingKeys: String, CodingKey {
            case id
            case title
            case brief = "brief" // Мапінг, якщо JSON використовує `brief`
        }
    }
    
    struct Group: Decodable {
        let id: Int
        let name: String
    }
}

struct Task: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let fullTitle: String
    let caption: String
    let date: Date
    let tint: Color
    
    var isCompleted: Bool = false
    
    // Новые поля:
    let auditory: String
    let type: String
    let teacher: String
}

var sampleTasks: [Task] = [
    Task(
        title: "Тестовая пара",
        fullTitle: "Тестовое занятие",
        caption: "Аудитория 101",
        date: Date(),
        tint: .blue,
        auditory: "101",
        type: "Лекція",
        teacher: "Преподаватель Иванов"
    ),
    Task(
        title: "Перерыв",
        fullTitle: "",
        caption: "",
        date: Date(),
        tint: .gray,
        auditory: "",
        type: "Перерва",
        teacher: ""
    )
]

func colorForType(_ type: String) -> Color {
    switch type {
    case "Лк": return .yellow
    case "Лб": return .cyan
    case "Пз": return .green
    case "Екз": return .red
    case "Конс": return .blue
    case "Зал": return .purple
    default: return .gray // Серый цвет для неизвестных типов
    }
}

func processScheduleData(scheduleItems: [ScheduleItem]) -> [Task] {
    var tasks: [Task] = []
    
    for (index, item) in scheduleItems.enumerated() {
        let taskTitle = item.subject.brief
        let fullTaskTitle = item.subject.title
        let taskDate = Date(timeIntervalSince1970: item.startTime)
        
        // Сконструируем строку для caption (если нужно)
        let taskCaption = "\(item.auditory)"
        
        // Определим цвет
        let taskTint = colorForType(item.type)
        
        // Создаём задачу
        let task = Task(
            title: taskTitle,
            fullTitle: fullTaskTitle,
            caption: taskCaption,
            date: taskDate,
            tint: taskTint,
            
            // Новые поля
            auditory: item.auditory,
            type: item.type,
            teacher: item.teachers.map { $0.shortName }.joined(separator: ", ")
        )
        tasks.append(task)
        
        // Если между текущей парой и следующей есть «окно» по времени — добавим перерыв
        if index < scheduleItems.count - 1 {
            let nextStartTime = scheduleItems[index + 1].startTime
            if nextStartTime > item.endTime {
                let breakTask = Task(
                    title: "Break",
                    fullTitle: "",
                    caption: "",
                    date: Date(timeIntervalSince1970: item.endTime),
                    tint: .gray,
                    
                    // Для break можно поставить заглушки
                    auditory: "",
                    type: "Перерва",
                    teacher: ""
                )
                tasks.append(breakTask)
            }
        }
    }
    
    return tasks
}
func processScheduleTeacherData(scheduleItems: [TeacherAPI]) -> [Task] {
    var tasks: [Task] = []
    
    for (index, item) in scheduleItems.enumerated() {
        let taskTitle = item.subject.brief
        let taskFullTitle = item.subject.title
        let taskDate = Date(timeIntervalSince1970: item.startTime)
        
        // Створюємо caption
        let taskCaption = "\(item.auditory)"
        
        // Визначаємо колір
        let taskTint = colorForType(item.type)
        
        // Отримуємо імена груп
        let groupNames = item.groups.map { $0.name }.joined(separator: ", ")
        
        // Створюємо завдання
        let task = Task(
            title: taskTitle,
            fullTitle: taskFullTitle,
            caption: taskCaption,
            date: taskDate,
            tint: taskTint,
            
            // Нові поля
            auditory: item.auditory,
            type: item.type,
            teacher: groupNames // Використовуємо імена груп
        )
        tasks.append(task)
        
        // Додаємо перерву, якщо між поточною парою та наступною є час
        if index < scheduleItems.count - 1 {
            let nextStartTime = scheduleItems[index + 1].startTime
            if nextStartTime > item.endTime {
                let breakTask = Task(
                    title: "Break",
                    fullTitle: "",
                    caption: "",
                    date: Date(timeIntervalSince1970: item.endTime),
                    tint: .gray,
                    
                    // Для перерви можна встановити заглушки
                    auditory: "",
                    type: "Перерва",
                    teacher: ""
                )
                tasks.append(breakTask)
            }
        }
    }
    
    return tasks
}

func createDate(hour: Int, minute: Int, timeZone: String) -> Date {
    var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    components.hour = hour
    components.minute = minute
    var calendar = Calendar.current
    
    // Указываем часовой пояс
    if let timeZone = TimeZone(identifier: timeZone) {
        calendar.timeZone = timeZone
    }
    
    return calendar.date(from: components) ?? Date()
}
