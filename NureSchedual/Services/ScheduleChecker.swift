import Foundation
import UserNotifications

// Модель для отслеживания изменений (перемещаем в начало файла)
public struct ScheduleChange {
    public enum ChangeType {
        case added
        case removed
        case modified
    }
    
    public let type: ChangeType
    public let subject: String
    public let oldValue: String?
    public let newValue: String?
    public let date: Date
    
    public init(type: ChangeType, subject: String, oldValue: String?, newValue: String?, date: Date) {
        self.type = type
        self.subject = subject
        self.oldValue = oldValue
        self.newValue = newValue
        self.date = date
    }
}

public class ScheduleChecker {
    public init() {}
    
    public func checkScheduleChanges(groupId: Int, completion: @escaping () -> Void = {}) {
        guard let url = URL(string: "https://api.mindenit.org/schedule/groups/\(groupId)") else {
            completion()
            return
        }
        
        // Загружаем текущее расписание из кэша
        let cachedSchedule = CacheManager.load(filename: "schedule_group_\(groupId).json")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let newData = data else {
                completion()
                return
            }
            
            // Если есть кэшированное расписание, сравниваем с новым
            if let cachedData = cachedSchedule {
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    
                    let oldSchedule = try decoder.decode([ScheduleItem].self, from: cachedData)
                    let newSchedule = try decoder.decode([ScheduleItem].self, from: newData)
                    
                    // Сравниваем расписания
                    let changes = self.findScheduleChanges(old: oldSchedule, new: newSchedule)
                    
                    if !changes.isEmpty {
                        // Если есть изменения, отправляем уведомление
                        self.sendScheduleChangeNotification(changes: changes)
                        
                        // Обновляем кэш
                        CacheManager.save(data: newData, filename: "schedule_group_\(groupId).json")
                    }
                } catch {
                    print("Ошибка при сравнении расписаний: \(error)")
                }
            }
            completion()
        }.resume()
    }
    
    private func findScheduleChanges(old: [ScheduleItem], new: [ScheduleItem]) -> [ScheduleChange] {
        var changes: [ScheduleChange] = []
        
        // Создаем словари для быстрого поиска
        let oldDict = Dictionary(grouping: old, by: { "\($0.startTime)_\($0.subject.id)" })
        let newDict = Dictionary(grouping: new, by: { "\($0.startTime)_\($0.subject.id)" })
        
        // Ищем измененные и удаленные пары
        for (key, oldItems) in oldDict {
            if let newItems = newDict[key] {
                // Пара существует в обоих расписаниях, проверяем изменения
                let oldItem = oldItems[0]
                let newItem = newItems[0]
                
                if oldItem.auditory != newItem.auditory {
                    changes.append(.init(
                        type: .modified,
                        subject: newItem.subject.title,
                        oldValue: oldItem.auditory,
                        newValue: newItem.auditory,
                        date: Date(timeIntervalSince1970: newItem.startTime)
                    ))
                }
            } else {
                // Пара была удалена
                let oldItem = oldItems[0]
                changes.append(.init(
                    type: .removed,
                    subject: oldItem.subject.title,
                    oldValue: oldItem.auditory,
                    newValue: nil,
                    date: Date(timeIntervalSince1970: oldItem.startTime)
                ))
            }
        }
        
        // Ищем новые пары
        for (key, newItems) in newDict {
            if oldDict[key] == nil {
                let newItem = newItems[0]
                changes.append(.init(
                    type: .added,
                    subject: newItem.subject.title,
                    oldValue: nil,
                    newValue: newItem.auditory,
                    date: Date(timeIntervalSince1970: newItem.startTime)
                ))
            }
        }
        
        return changes
    }
    
    private func sendScheduleChangeNotification(changes: [ScheduleChange]) {
        NotificationManager.shared.scheduleScheduleChangeNotification(changes: changes)
    }
    
    // Вспомогательная функция для форматирования времени
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
} 