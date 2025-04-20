import Foundation
import SwiftUI

struct SubjectStatistics: Identifiable {
    let id = UUID()
    let subjectName: String
    let practicalLessons: LessonCount
    let laboratoryWorks: LessonCount
    let exams: LessonCount
    let consultations: LessonCount
    let tests: LessonCount
    
    struct LessonCount {
        let completed: Int
        let total: Int
        let nextDate: Date?
        let allDates: [(start: Date, end: Date)]
        
        var progress: Double {
            guard total > 0 else { return 0 }
            return Double(completed) / Double(total)
        }
    }
    
    static func colorForType(_ type: String) -> Color {
        switch type {
        case "Лк": return .yellow
        case "Лб": return .cyan
        case "Пз": return .green
        case "Екз": return .red
        case "Конс": return .blue
        case "Зал": return .purple
        default: return .gray
        }
    }
    
    static func calculateStatistics(from tasks: [Task], startDate: Date? = nil, endDate: Date? = nil) -> [SubjectStatistics] {
        print("🚀 Начало расчета статистики")
        if let start = startDate, let end = endDate {
            print("📅 Период семестра: \(DateFormatter.localizedString(from: start, dateStyle: .medium, timeStyle: .none)) - \(DateFormatter.localizedString(from: end, dateStyle: .medium, timeStyle: .none))")
        }
        print("📚 Всего задач до фильтрации: \(tasks.count)")
        
        var subjectMap: [String: (practical: [Task], laboratory: [Task], exams: [Task], consultations: [Task], tests: [Task])] = [:]
        
        // Группируем задачи по предметам и типам
        for task in tasks {
            if task.title == "Break" { 
                print("⏭️ Пропущена задача типа Break")
                continue 
            }
            
            if !subjectMap.keys.contains(task.fullTitle) {
                print("\n📖 Новый предмет: \(task.fullTitle)")
                subjectMap[task.fullTitle] = ([], [], [], [], [])
            }
            
            switch task.type {
            case "Пз":
                subjectMap[task.fullTitle]?.practical.append(task)
                print("✓ Добавлено ПЗ: \(DateFormatter.localizedString(from: task.date, dateStyle: .short, timeStyle: .none))")
            case "Лб":
                subjectMap[task.fullTitle]?.laboratory.append(task)
                print("✓ Добавлена ЛБ: \(DateFormatter.localizedString(from: task.date, dateStyle: .short, timeStyle: .none))")
            case "Екз":
                if !subjectMap[task.fullTitle]!.exams.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: task.date) }) {
                    subjectMap[task.fullTitle]?.exams.append(task)
                    print("✓ Добавлен экзамен: \(DateFormatter.localizedString(from: task.date, dateStyle: .short, timeStyle: .none))")
                } else {
                    print("⚠️ Пропущен дубликат экзамена")
                }
            case "Конс":
                subjectMap[task.fullTitle]?.consultations.append(task)
                print("✓ Добавлена консультация: \(DateFormatter.localizedString(from: task.date, dateStyle: .short, timeStyle: .none))")
            case "Зал":
                if !subjectMap[task.fullTitle]!.tests.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: task.date) }) {
                    subjectMap[task.fullTitle]?.tests.append(task)
                    print("✓ Добавлен зачет: \(DateFormatter.localizedString(from: task.date, dateStyle: .short, timeStyle: .none))")
                } else {
                    print("⚠️ Пропущен дубликат зачета")
                }
            default:
                print("⚠️ Неизвестный тип задачи: \(task.type)")
                break
            }
        }
        
        // Функция для создания LessonCount с учетом временных интервалов
        func createLessonCount(from tasks: [Task], type: String) -> LessonCount {
            print("\n🔍 Анализ занятий типа \(type)")
            let sortedTasks = tasks.sorted { $0.date < $1.date }
            let currentDate = Date()
            let completed = tasks.filter { $0.date < currentDate }.count
            print("✓ Выполнено: \(completed) из \(tasks.count)")
            
            var intervals: [(start: Date, end: Date)] = []
            var currentDayTasks: [Task] = []
            
            for task in sortedTasks {
                if currentDayTasks.isEmpty || Calendar.current.isDate(task.date, inSameDayAs: currentDayTasks[0].date) {
                    currentDayTasks.append(task)
                } else {
                    if let firstTask = currentDayTasks.first, let lastTask = currentDayTasks.last {
                        intervals.append((start: firstTask.date, end: lastTask.date))
                        print("📅 Добавлен интервал: \(DateFormatter.localizedString(from: firstTask.date, dateStyle: .short, timeStyle: .short)) - \(DateFormatter.localizedString(from: lastTask.date, dateStyle: .none, timeStyle: .short))")
                    }
                    currentDayTasks = [task]
                }
            }
            
            if let firstTask = currentDayTasks.first, let lastTask = currentDayTasks.last {
                intervals.append((start: firstTask.date, end: lastTask.date))
                print("📅 Добавлен последний интервал: \(DateFormatter.localizedString(from: firstTask.date, dateStyle: .short, timeStyle: .short)) - \(DateFormatter.localizedString(from: lastTask.date, dateStyle: .none, timeStyle: .short))")
            }
            
            if let start = startDate, let end = endDate {
                let originalCount = intervals.count
                intervals = intervals.filter { interval in
                    interval.start >= start && interval.end <= end
                }
                print("🔍 Отфильтровано по семестру: \(intervals.count) из \(originalCount) интервалов")
            }
            
            if let nextDate = sortedTasks.first(where: { $0.date > currentDate })?.date {
                print("⏰ Следующее занятие: \(DateFormatter.localizedString(from: nextDate, dateStyle: .short, timeStyle: .short))")
            }
            
            return LessonCount(
                completed: completed,
                total: intervals.count,
                nextDate: sortedTasks.first { $0.date > currentDate }?.date,
                allDates: intervals
            )
        }
        
        let statistics = subjectMap.map { subject, tasks in
            print("\n📊 Обработка статистики для предмета: \(subject)")
            return SubjectStatistics(
                subjectName: subject,
                practicalLessons: createLessonCount(from: tasks.practical, type: "Пз"),
                laboratoryWorks: createLessonCount(from: tasks.laboratory, type: "Лб"),
                exams: createLessonCount(from: tasks.exams, type: "Екз"),
                consultations: createLessonCount(from: tasks.consultations, type: "Конс"),
                tests: createLessonCount(from: tasks.tests, type: "Зал")
            )
        }.sorted { $0.subjectName < $1.subjectName }
        
        print("\n✅ Расчет статистики завершен. Обработано предметов: \(statistics.count)")
        return statistics
    }
} 