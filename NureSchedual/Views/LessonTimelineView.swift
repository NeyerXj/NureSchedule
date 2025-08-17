import SwiftUI

// Добавляем класс для управления состоянием
class LessonTimelineViewModel: ObservableObject {
    @Published var title: String
    @Published var lessons: SubjectStatistics.LessonCount
    @Published var type: String
    @Published var isLoading = false
    @Published var showContent = true
    private let id = UUID()
    
    init(title: String, lessons: SubjectStatistics.LessonCount, type: String) {
        print("📱 LessonTimelineView: \(title)")
        self.title = title
        self.lessons = lessons
        self.type = type
        self.isLoading = false
        self.showContent = true
    }
    
    var sortedDates: [((start: Date, end: Date), Bool)] {
        let currentDate = Date()
        let calendar = Calendar.current
        
        // Группируем даты по дням для корректного подсчета
        let groupedDates = Dictionary(grouping: lessons.allDates) { interval in
            calendar.startOfDay(for: interval.start)
        }
        
        // Для каждого дня берем только одну пару
        let uniqueDates = groupedDates.map { $0.value.first! }
        
        return uniqueDates.map { dateInterval in
            (dateInterval, dateInterval.start < currentDate)
        }.sorted { $0.0.start < $1.0.start }
    }
    
    deinit {
        print("🗑 LessonTimelineView: \(title)")
    }
}

struct LessonTimelineView: View {
    @StateObject private var viewModel: LessonTimelineViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isVisible = false
    
    init(title: String, lessons: SubjectStatistics.LessonCount, type: String) {
        _viewModel = StateObject(wrappedValue: LessonTimelineViewModel(
            title: title,
            lessons: lessons,
            type: type
        ))
    }
    
    var body: some View {
        ZStack {
            // Фоновий градієнт
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.10, green: 0.14, blue: 0.24),
                    Color(red: 0.05, green: 0.07, blue: 0.15)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text(viewModel.title)
                    .font(.custom("Inter", size: 24).weight(.bold))
                    .foregroundColor(.white)
                    .padding(.top)
                    .opacity(isVisible ? 1 : 0)
                
                // Статистика
                HStack {
                    VStack(alignment: .leading) {
                        Text("Виконано")
                            .font(.custom("Inter", size: 16))
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(viewModel.sortedDates.filter { $0.1 }.count) з \(viewModel.sortedDates.count)")
                            .font(.custom("Inter", size: 24).weight(.bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    let progress = Double(viewModel.sortedDates.filter { $0.1 }.count) / Double(viewModel.sortedDates.count)
                    Text("\(Int(progress * 100))%")
                        .font(.custom("Inter", size: 32).weight(.bold))
                        .foregroundColor(SubjectStatistics.colorForType(viewModel.type))
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)
                .opacity(isVisible ? 1 : 0)
                
                // График
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.sortedDates.enumerated()), id: \.element.0.start) { index, item in
                            let (dateInterval, isCompleted) = item
                            TimelineItem(
                                dateInterval: dateInterval,
                                isCompleted: isCompleted,
                                color: SubjectStatistics.colorForType(viewModel.type)
                            )
                            .opacity(isVisible ? 1 : 0)
                            .animation(.easeIn(duration: 0.3).delay(Double(index) * 0.05), value: isVisible)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Назад")
                            .font(.custom("Inter", size: 16))
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                isVisible = true
            }
        }
        .id(UUID()) // Предотвращаем повторные обновления
    }
}

struct TimelineItem: View {
    let dateInterval: (start: Date, end: Date)
    let isCompleted: Bool
    let color: Color
    @State private var showDetails = false
    
    var body: some View {
        HStack(spacing: 15) {
            // Индикатор
            Circle()
                .fill(isCompleted ? color : .gray)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 2)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(dateInterval.start.format("dd.MM.yyyy"))
                    .font(.custom("Inter", size: 16).weight(.semibold))
                    .foregroundColor(.white)
                
                Text("\(dateInterval.start.format("HH:mm")) - \(dateInterval.end.format("HH:mm"))")
                    .font(.custom("Inter", size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? color : .gray)
                .font(.system(size: 20))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .padding(.horizontal)
    }
}

#Preview {
    let currentDate = Date()
    let futureDate = currentDate.addingTimeInterval(3600)
    let mockLessons = SubjectStatistics.LessonCount(
        completed: 3,
        total: 8,
        nextDate: Date(),
        allDates: [(start: currentDate, end: futureDate)]
    )
    
    return LessonTimelineView(
        title: "Лабораторні роботи",
        lessons: mockLessons,
        type: "Лб"
    )
} 