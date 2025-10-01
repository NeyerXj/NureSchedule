import Foundation
import EventKit

final class CalendarExportManager {
    static let shared = CalendarExportManager()
    private let eventStore = EKEventStore()
    private let calendarTitle = "NureSchedule"
    private let calendarIdKey = "calendar_identifier"

    private init() {}

    func export(tasks: [Task], contextTitle: String) {
        requestAccess { [weak self] granted in
            guard granted, let self = self else { return }
            guard let calendar = self.getOrCreateCalendar() else { return }

            // Remove previous events from this calendar in a wide range
            self.clearEvents(in: calendar, covering: tasks)

            // Add new events
            let nonBreakTasks = tasks.filter { $0.title != "Break" }
            for task in nonBreakTasks {
                let event = EKEvent(eventStore: self.eventStore)
                event.calendar = calendar
                event.title = "\(task.title) • \(task.type)"
                event.location = task.auditory.isEmpty ? nil : task.auditory
                let startDate = task.date
                // Default duration 90 minutes if we do not have explicit end time
                let endDate = startDate.addingTimeInterval(90 * 60)
                event.startDate = startDate
                event.endDate = endDate
                event.notes = "Викладач: \(task.teacher)\nКонтекст: \(contextTitle)\nЗгенеровано NureSchedule"

                do {
                    try self.eventStore.save(event, span: .thisEvent, commit: false)
                } catch {
                    print("❌ Failed to save event: \(error)")
                }
            }

            do {
                try self.eventStore.commit()
                print("✅ Календар синхронізовано")
            } catch {
                print("❌ Не вдалося застосувати зміни календаря: \(error)")
            }
        }
    }

    private func requestAccess(completion: @escaping (Bool) -> Void) {
        eventStore.requestAccess(to: .event) { granted, error in
            if let error = error { print("Calendar access error: \(error)") }
            completion(granted)
        }
    }

    private func getOrCreateCalendar() -> EKCalendar? {
        if let savedId = UserDefaults.standard.string(forKey: calendarIdKey),
           let existing = eventStore.calendar(withIdentifier: savedId) {
            return existing
        }

        // Create new
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = calendarTitle

        // Prefer iCloud if available, else local
        let sources = eventStore.sources
        if let icloud = sources.first(where: { $0.sourceType == .calDAV && $0.title.lowercased().contains("icloud") }) {
            newCalendar.source = icloud
        } else if let local = sources.first(where: { $0.sourceType == .local }) {
            newCalendar.source = local
        } else if let first = sources.first {
            newCalendar.source = first
        }

        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
            UserDefaults.standard.set(newCalendar.calendarIdentifier, forKey: calendarIdKey)
            return newCalendar
        } catch {
            print("❌ Не вдалося створити календар: \(error)")
            return nil
        }
    }

    private func clearEvents(in calendar: EKCalendar, covering tasks: [Task]) {
        let (start, end) = dateRange(for: tasks)
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: [calendar])
        let events = eventStore.events(matching: predicate)
        for event in events {
            do {
                try eventStore.remove(event, span: .thisEvent, commit: false)
            } catch {
                print("⚠️ Не вдалося видалити подію: \(error)")
            }
        }
        do { try eventStore.commit() } catch { print("Commit error while clearing: \(error)") }
    }

    private func dateRange(for tasks: [Task]) -> (Date, Date) {
        let dates = tasks.map { $0.date }
        let minDate = dates.min() ?? Date().addingTimeInterval(-60*60*24*7)
        let maxDate = dates.max() ?? Date().addingTimeInterval(60*60*24*180)
        let start = Calendar.current.date(byAdding: .day, value: -7, to: minDate) ?? minDate
        let end = Calendar.current.date(byAdding: .day, value: 7, to: maxDate) ?? maxDate
        return (start, end)
    }

    // Public: clear all exported items (delete app calendar if possible)
    func clearAllExportedData() {
        requestAccess { [weak self] granted in
            guard granted, let self = self else { return }
            guard let calendar = self.getOrCreateCalendar() else { return }

            // Try removing entire calendar
            do {
                try self.eventStore.removeCalendar(calendar, commit: true)
                UserDefaults.standard.removeObject(forKey: self.calendarIdKey)
                print("🗑 Календар NureSchedule видалено")
            } catch {
                // Fallback: clear events in a wide date range (±2 years)
                let start = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date().addingTimeInterval(-60*60*24*365*2)
                let end = Calendar.current.date(byAdding: .year, value: 2, to: Date()) ?? Date().addingTimeInterval(60*60*24*365*2)
                let predicate = self.eventStore.predicateForEvents(withStart: start, end: end, calendars: [calendar])
                let events = self.eventStore.events(matching: predicate)
                for event in events {
                    do { try self.eventStore.remove(event, span: .thisEvent, commit: false) } catch { print("⚠️ Не видалено: \(error)") }
                }
                do { try self.eventStore.commit() } catch { print("Commit error: \(error)") }
            }
        }
    }
}


