import Foundation

class ScheduleViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    
    func fetchSchedule(scheduleItems: [ScheduleItem]) {
        DispatchQueue.main.async {
            self.tasks = processScheduleData(scheduleItems: scheduleItems)
        }
    }
    
    func fetchTeacherSchedule(scheduleItems: [TeacherAPI]) {
        DispatchQueue.main.async {
            self.tasks = processScheduleTeacherData(scheduleItems: scheduleItems)
        }
    }
} 
