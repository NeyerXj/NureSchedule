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
        
        enum CodingKeys: String, CodingKey { case id, title, name, brief }
        
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decode(Int.self, forKey: .id)
            brief = try c.decodeIfPresent(String.self, forKey: .brief) ?? ""
            if let t = try c.decodeIfPresent(String.self, forKey: .title) {
                title = t
            } else if let n = try c.decodeIfPresent(String.self, forKey: .name) {
                title = n
            } else {
                throw DecodingError.keyNotFound(
                    CodingKeys.title,
                    .init(codingPath: decoder.codingPath, debugDescription: "Neither `title` nor `name` found in subject")
                )
            }
        }
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

    private struct AuditoriumRef: Decodable {
        let id: Int?
        let name: String?
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case numberPair
        case subject
        case startTime
        case endTime
        case auditory       // legacy: string
        case auditorium     // new: object { id, name }
        case type
        case teachers
        case groups
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(Int.self, forKey: .id)
        numberPair = try c.decode(Int.self, forKey: .numberPair)
        subject = try c.decode(Subject.self, forKey: .subject)
        startTime = try c.decode(TimeInterval.self, forKey: .startTime)
        endTime = try c.decode(TimeInterval.self, forKey: .endTime)
        type = try c.decode(String.self, forKey: .type)
        teachers = try c.decode([Teacher].self, forKey: .teachers)
        groups = try c.decode([Group].self, forKey: .groups)
        
        if let audString = try c.decodeIfPresent(String.self, forKey: .auditory) {
            auditory = audString
        } else if let audObj = try c.decodeIfPresent(AuditoriumRef.self, forKey: .auditorium),
                  let name = audObj.name {
            auditory = name
        } else {
            auditory = ""
        }
    }
}

struct TeacherAPI: Identifiable, Decodable {
    let id: Int?
    let name: String?
    let startTime: TimeInterval
    let endTime: TimeInterval
    let auditory: String
    let type: String
    let subject: Subject
    let groups: [Group]
    
    private struct AuditoriumRef: Decodable {
        let id: Int?
        let name: String?
    }
    
    struct Subject: Decodable {
        let id: Int
        let title: String
        let brief: String
        
        enum CodingKeys: String, CodingKey { case id, title, name, brief }
        
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decode(Int.self, forKey: .id)
            brief = try c.decodeIfPresent(String.self, forKey: .brief) ?? ""
            if let t = try c.decodeIfPresent(String.self, forKey: .title) {
                title = t
            } else if let n = try c.decodeIfPresent(String.self, forKey: .name) {
                title = n
            } else {
                throw DecodingError.keyNotFound(
                    CodingKeys.title,
                    .init(codingPath: decoder.codingPath, debugDescription: "Neither `title` nor `name` found in subject")
                )
            }
        }
    }
    
    struct Group: Decodable {
        let id: Int
        let name: String
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case startTime
        case endTime
        case auditory       // legacy
        case auditorium     // new: object { id, name }
        case type
        case subject
        case groups
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(Int.self, forKey: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        startTime = try c.decode(TimeInterval.self, forKey: .startTime)
        endTime = try c.decode(TimeInterval.self, forKey: .endTime)
        type = try c.decode(String.self, forKey: .type)
        subject = try c.decode(Subject.self, forKey: .subject)
        groups = try c.decode([Group].self, forKey: .groups)
        
        if let audString = try c.decodeIfPresent(String.self, forKey: .auditory) {
            auditory = audString
        } else if let audObj = try c.decodeIfPresent(AuditoriumRef.self, forKey: .auditorium),
                  let name = audObj.name {
            auditory = name
        } else {
            auditory = ""
        }
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
    let auditory: String
    let type: String
    let teacher: String
    var subTasks: [SubTask] = []
    
    init(
        title: String,
        fullTitle: String,
        caption: String,
        date: Date,
        tint: Color,
        isCompleted: Bool = false,
        auditory: String,
        type: String,
        teacher: String,
        subTasks: [SubTask] = []
    ) {
        self.title = title
        self.fullTitle = fullTitle
        self.caption = caption
        self.date = date
        self.tint = tint
        self.isCompleted = isCompleted
        self.auditory = auditory
        self.type = type
        self.teacher = teacher
        self.subTasks = subTasks
    }
    
    static func == (lhs: Task, rhs: Task) -> Bool {
        lhs.id == rhs.id
    }
}

// Добавляем структуру SubTask
struct SubTask: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let fullTitle: String
    let caption: String
    let group: String
    let auditory: String
    let type: String
    let teacher: String
    
    static func == (lhs: SubTask, rhs: SubTask) -> Bool {
        lhs.id == rhs.id
    }
}

var sampleTasks: [Task] = [
    Task(
        title: "Тестовая пара",
        fullTitle: "Тестовое занятие",
        caption: "Аудитория 101",
        date: Date(),
        tint: .blue,
        isCompleted: false,
        auditory: "101",
        type: "Лекція",
        teacher: "Преподаватель Иванов",
        subTasks: []
    ),
    Task(
        title: "Break",
        fullTitle: "",
        caption: "",
        date: Date(),
        tint: .gray,
        isCompleted: false,
        auditory: "",
        type: "Перерва",
        teacher: "",
        subTasks: []
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
    // Группируем занятия по времени начала и предмету
    let groupedItems = Dictionary(grouping: scheduleItems) { item in
        // Создаем ключ группировки на основе времени и ID предмета
        return "\(item.startTime)_\(item.subject.id)"
    }
    var tasks: [Task] = []
    
    for (_, items) in groupedItems {
        // Сортируем items по времени, чтобы обеспечить последовательность
        let sortedItems = items.sorted { $0.startTime < $1.startTime }
        let firstItem = sortedItems[0]
        
        if sortedItems.count > 1 && firstItem.subject.id == sortedItems[1].subject.id {
            // Если несколько групп на одну пару
            let taskDate = Date(timeIntervalSince1970: firstItem.startTime)
            
            // Создаем основную задачу
            var task = Task(
                title: firstItem.subject.brief,
                fullTitle: firstItem.subject.title,
                caption: firstItem.auditory,
                date: taskDate,
                tint: colorForType(firstItem.type),
                auditory: firstItem.auditory,
                type: firstItem.type,
                teacher: firstItem.teachers.map { $0.shortName }.joined(separator: ", "),
                subTasks: sortedItems.map { item in
                    SubTask(
                        title: item.subject.brief,
                        fullTitle: item.subject.title,
                        caption: item.auditory,
                        group: item.groups.map { $0.name }.joined(separator: ", "),
                        auditory: item.auditory,
                        type: item.type,
                        teacher: item.teachers.map { $0.shortName }.joined(separator: ", ")
                    )
                }
            )
            
            tasks.append(task)
        } else {
            // Если одна пара
            let taskDate = Date(timeIntervalSince1970: firstItem.startTime)
            
            let task = Task(
                title: firstItem.subject.brief,
                fullTitle: firstItem.subject.title,
                caption: firstItem.auditory,
                date: taskDate,
                tint: colorForType(firstItem.type),
                auditory: firstItem.auditory,
                type: firstItem.type,
                teacher: firstItem.teachers.map { $0.shortName }.joined(separator: ", "),
                subTasks: []
            )
            
            tasks.append(task)
        }
    }
    
    // Сортируем все задачи по времени
    let sortedTasks = tasks.sorted { $0.date < $1.date }
    
    // Добавляем перерывы между парами
    var tasksWithBreaks: [Task] = []
    for i in 0..<sortedTasks.count {
        tasksWithBreaks.append(sortedTasks[i])
        
        // Если есть следующая пара, проверяем нужен ли перерыв
        if i < sortedTasks.count - 1 {
            let currentEndTime = TimeInterval(sortedTasks[i].date.timeIntervalSince1970)
            let nextStartTime = TimeInterval(sortedTasks[i + 1].date.timeIntervalSince1970)
            
            // Если есть промежуток между парами, добавляем перерыв
            if nextStartTime > currentEndTime {
                // Находим оригинальный ScheduleItem для текущей задачи
                if let originalItem = scheduleItems.first(where: { Date(timeIntervalSince1970: $0.startTime) == sortedTasks[i].date }) {
                    let breakTask = Task(
                        title: "Break",
                        fullTitle: "",
                        caption: "",
                        date: Date(timeIntervalSince1970: originalItem.endTime),
                        tint: .gray,
                        isCompleted: false,
                        auditory: "",
                        type: "Перерва",
                        teacher: "",
                        subTasks: []
                    )
                    tasksWithBreaks.append(breakTask)
                }
            }
        }
    }
    
    return tasksWithBreaks
}

func processScheduleTeacherData(scheduleItems: [TeacherAPI]) -> [Task] {
    let groupedItems = Dictionary(grouping: scheduleItems) { item in
        return "\(item.startTime)_\(item.subject.id)"
    }
    var tasks: [Task] = []
    
    for (_, items) in groupedItems {
        let sortedItems = items.sorted { $0.startTime < $1.startTime }
        let firstItem = sortedItems[0]
        
        if sortedItems.count > 1 && firstItem.subject.id == sortedItems[1].subject.id {
            let taskDate = Date(timeIntervalSince1970: firstItem.startTime)
            
            var task = Task(
                title: firstItem.subject.brief,
                fullTitle: firstItem.subject.title,
                caption: firstItem.auditory,
                date: taskDate,
                tint: colorForType(firstItem.type),
                isCompleted: false,
                auditory: firstItem.auditory,
                type: firstItem.type,
                teacher: firstItem.groups.map { $0.name }.joined(separator: ", "),
                subTasks: []
            )
            
            task.subTasks = sortedItems.map { item in
                SubTask(
                    title: item.subject.brief,
                    fullTitle: item.subject.title,
                    caption: item.auditory,
                    group: item.groups.map { $0.name }.joined(separator: ", "),
                    auditory: item.auditory,
                    type: item.type,
                    teacher: item.groups.map { $0.name }.joined(separator: ", ")
                )
            }
            
            tasks.append(task)
        } else {
            let taskDate = Date(timeIntervalSince1970: firstItem.startTime)
            
            let task = Task(
                title: firstItem.subject.brief,
                fullTitle: firstItem.subject.title,
                caption: firstItem.auditory,
                date: taskDate,
                tint: colorForType(firstItem.type),
                isCompleted: false,
                auditory: firstItem.auditory,
                type: firstItem.type,
                teacher: firstItem.groups.map { $0.name }.joined(separator: ", "),
                subTasks: []
            )
            
            tasks.append(task)
        }
    }
    
    let sortedTasks = tasks.sorted { $0.date < $1.date }
    var tasksWithBreaks: [Task] = []
    
    for i in 0..<sortedTasks.count {
        tasksWithBreaks.append(sortedTasks[i])
        
        if i < sortedTasks.count - 1 {
            let currentEndTime = TimeInterval(sortedTasks[i].date.timeIntervalSince1970)
            let nextStartTime = TimeInterval(sortedTasks[i + 1].date.timeIntervalSince1970)
            
            if nextStartTime > currentEndTime {
                // Находим оригинальный TeacherAPI для текущей задачи
                if let originalItem = scheduleItems.first(where: { Date(timeIntervalSince1970: $0.startTime) == sortedTasks[i].date }) {
                    let breakTask = Task(
                        title: "Break",
                        fullTitle: "",
                        caption: "",
                        date: Date(timeIntervalSince1970: originalItem.endTime),
                        tint: .gray,
                        isCompleted: false,
                        auditory: "",
                        type: "Перерва",
                        teacher: "",
                        subTasks: []
                    )
                    tasksWithBreaks.append(breakTask)
                }
            }
        }
    }
    
    return tasksWithBreaks
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
