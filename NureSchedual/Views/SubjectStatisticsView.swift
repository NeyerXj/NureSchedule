import SwiftUI

struct SubjectStatisticsView: View {
    @State private var selectedSubjectID: UUID?
    @StateObject private var viewModel: SubjectStatisticsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSemester: Int
    @State private var viewMode = ViewMode.statistics
    @State private var showingDetail = false
    @State private var selectedSubject: SubjectStatistics? = nil
    
    enum ViewMode {
        case statistics
        case upcoming
    }
    
    init(statistics: [SubjectStatistics]) {
        let currentDate = Date()
        let semester = SemesterDates.shared.currentSemester
        _selectedSemester = State(initialValue: semester)
        _viewModel = StateObject(wrappedValue: SubjectStatisticsViewModel(statistics: statistics))
    }
    
    var body: some View {
        NavigationStack {
            mainContent
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
//                .navigationDestination(isPresented: $showingDetail) {
//                    if let subject = selectedSubject {
//                        SubjectDetailView(subject: subject)
//                    }
//                }
        }
    }
    
    private var mainContent: some View {
        ZStack {
            backgroundGradient
            contentView
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.10, green: 0.14, blue: 0.24),
                Color(red: 0.05, green: 0.07, blue: 0.15)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var contentView: some View {
        VStack(spacing: 20) {
            Text("Статистика предметів")
                .font(.custom("Inter", size: 28).weight(.bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top)
            
            viewModePicker
            
            if viewMode == .statistics {
                statisticsContent
            } else {
                upcomingContent
            }
        }
    }
    
    private var viewModePicker: some View {
        HStack(spacing: 0) {
            ForEach([ViewMode.statistics, ViewMode.upcoming], id: \.self) { mode in
                Button(action: {
                    withAnimation(.spring()) {
                        viewMode = mode
                        if mode == .upcoming {
                            viewModel.updateUpcomingLessons(semester: selectedSemester)
                        }
                    }
                }) {
                    Text(mode == .statistics ? "Статистика" : "Найближчі")
                        .font(.custom("Inter", size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(viewMode == mode ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(viewMode == mode ? Color.blue.opacity(0.3) : Color.clear)
                }
            }
        }
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var statisticsContent: some View {
        VStack(spacing: 15) {
            semesterPicker
            
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 15) {
                    ForEach(viewModel.filteredStatistics(for: selectedSemester)) { subject in
                        NavigationLink(
                            destination: SubjectDetailView(subject: subject),
                            tag: subject.id,
                            selection: $selectedSubjectID
                        ) {
                            SubjectCard(subject: subject, viewModel: viewModel, semester: selectedSemester)
                                .onTapGesture {
                                    selectedSubjectID = subject.id
                                }
                        }
                    }
                    
                }
                .padding()
            }
        }
    }
    
    private var semesterPicker: some View {
        HStack(spacing: 0) {
            ForEach([0, 1], id: \.self) { semester in
                Button(action: {
                    withAnimation(.spring()) {
                        selectedSemester = semester
                    }
                }) {
                    Text("\(semester + 1) семестр")
                        .font(.custom("Inter", size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(selectedSemester == semester ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedSemester == semester ? Color.purple.opacity(0.3) : Color.clear)
                }
            }
        }
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var upcomingContent: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 15) {
                ForEach(viewModel.upcomingLessons, id: \.date) { lesson in
                    UpcomingLessonCard(
                        subject: lesson.subject,
                        type: lesson.type,
                        date: lesson.date,
                        color: lesson.color
                    )
                }
            }
            .padding()
        }
    }
}

struct UpcomingLessonCard: View {
    let subject: String
    let type: String
    let date: Date
    let color: Color
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 15) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
                .padding(8)
                .background(.white.opacity(0.1))
                .clipShape(Circle())
                .scaleEffect(isAnimating ? 1.1 : 1.0)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(subject)
                    .font(.custom("Inter", size: 16).weight(.bold))
                    .foregroundColor(.white)
                
                HStack {
                    Text(type)
                        .font(.custom("Inter", size: 14))
                        .foregroundColor(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.2))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    Text(date.format("dd.MM.yyyy HH:mm"))
                        .font(.custom("Inter", size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
                .shadow(color: color.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever()) {
                isAnimating = true
            }
        }
    }
}

struct SubjectCard: View {
    let subject: SubjectStatistics
    @ObservedObject var viewModel: SubjectStatisticsViewModel
    let semester: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(subject.subjectName)
                .font(.custom("Inter", size: 18).weight(.bold))
                .foregroundColor(.white)
                .lineLimit(2)
            
            let stats = viewModel.getStatisticsForCard(subject, semester: semester)
            
            HStack(spacing: 20) {
                StatisticItem(
                    title: "ПЗ",
                    completed: stats.practical,
                    total: stats.practicalTotal,
                    color: .blue
                )
                
                StatisticItem(
                    title: "ЛБ",
                    completed: stats.lab,
                    total: stats.labTotal,
                    color: .green
                )
                
                StatisticItem(
                    title: subject.exams.total > 0 ? "Екз" : "Зал",
                    completed: stats.exam,
                    total: stats.examTotal,
                    color: subject.exams.total > 0 ? .red : .purple
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
        )
    }
}

struct StatisticItem: View {
    let title: String
    let completed: Int
    let total: Int
    let color: Color
    
    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(Double(completed) / Double(total), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom("Inter", size: 14).weight(.medium))
                .foregroundColor(.white.opacity(0.8))
            
            Text("\(min(completed, total))/\(total)")
                .font(.custom("Inter", size: 16).weight(.bold))
                .foregroundColor(.white)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(color.opacity(0.2))
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 4)
            .clipShape(RoundedRectangle(cornerRadius: 2))
        }
        .frame(maxWidth: .infinity)
    }
}

class SubjectStatisticsViewModel: ObservableObject {
    @Published private(set) var upcomingLessons: [(subject: String, type: String, date: Date, color: Color)] = []
    @Published private(set) var filteredStatsBySemester: [Int: [SubjectStatistics]] = [:]
    private let statistics: [SubjectStatistics]
    
    init(statistics: [SubjectStatistics]) {
        self.statistics = statistics
        self.filteredStatsBySemester = [
            0: filterStatistics(for: 0),
            1: filterStatistics(for: 1)
        ]
    }
    
    private func filterStatistics(for semester: Int) -> [SubjectStatistics] {
        let semesterDates = SemesterDates.shared.getSemesterDates()[semester]
        
        return statistics.map { subject in
            let filteredPractical = filterLessonsForSemester(subject.practicalLessons, in: semesterDates)
            let filteredLab = filterLessonsForSemester(subject.laboratoryWorks, in: semesterDates)
            let filteredExams = filterLessonsForSemester(subject.exams, in: semesterDates)
            let filteredTests = filterLessonsForSemester(subject.tests, in: semesterDates)
            let filteredConsultations = filterLessonsForSemester(subject.consultations, in: semesterDates)
            
            return SubjectStatistics(
                subjectName: subject.subjectName,
                practicalLessons: filteredPractical,
                laboratoryWorks: filteredLab,
                exams: filteredExams,
                consultations: filteredConsultations,
                tests: filteredTests
            )
        }.filter { subject in
            subject.practicalLessons.total > 0 ||
            subject.laboratoryWorks.total > 0 ||
            subject.exams.total > 0 ||
            subject.tests.total > 0 ||
            subject.consultations.total > 0
        }
    }
    
    private func filterLessonsForSemester(_ lessons: SubjectStatistics.LessonCount, in semesterDates: (start: Date, end: Date)) -> SubjectStatistics.LessonCount {
        let filteredDates = lessons.allDates.filter { dateInterval in
            dateInterval.start >= semesterDates.start && dateInterval.end <= semesterDates.end
        }
        
        let currentDate = Date()
        let completed = min(
            filteredDates.filter { $0.start < currentDate }.count,
            filteredDates.count
        )
        
        return SubjectStatistics.LessonCount(
            completed: completed,
            total: filteredDates.count,
            nextDate: filteredDates.first { $0.start > currentDate }?.start,
            allDates: filteredDates
        )
    }
    
    func getStatisticsForCard(_ subject: SubjectStatistics, semester: Int) -> (practical: Int, practicalTotal: Int, 
                                                                              lab: Int, labTotal: Int,
                                                                              exam: Int, examTotal: Int) {
        let semesterDates = SemesterDates.shared.getSemesterDates()[semester]
        let currentDate = Date()
        
        func filterLessons(_ lessons: SubjectStatistics.LessonCount) -> (completed: Int, total: Int) {
            let filteredDates = lessons.allDates.filter { dateInterval in
                dateInterval.start >= semesterDates.start && dateInterval.end <= semesterDates.end
            }
            let completed = filteredDates.filter { $0.start < currentDate }.count
            return (completed, filteredDates.count)
        }
        
        let practical = filterLessons(subject.practicalLessons)
        let lab = filterLessons(subject.laboratoryWorks)
        
        // Проверяем сначала экзамены, если их нет - используем зачеты
        let exam = subject.exams.total > 0 ? 
            filterLessons(subject.exams) : 
            filterLessons(subject.tests)
        
        return (practical.completed, practical.total,
                lab.completed, lab.total,
                exam.completed, exam.total)
    }
    
    func updateUpcomingLessons(semester: Int) {
        let semesterDates = SemesterDates.shared.getSemesterDates()[semester]
        let currentDate = Date()
        var lessons: [(subject: String, type: String, date: Date, color: Color)] = []
        
        for subject in filteredStatsBySemester[semester] ?? [] {
            let checkAndAddLesson = { (nextDate: Date?, type: String, color: Color) in
                if let date = nextDate,
                   date >= currentDate &&
                   date >= semesterDates.start && date <= semesterDates.end {
                    lessons.append((subject.subjectName, type, date, color))
                }
            }
            
            checkAndAddLesson(subject.practicalLessons.nextDate, "Практичне", .green)
            checkAndAddLesson(subject.laboratoryWorks.nextDate, "Лабораторна", .cyan)
            checkAndAddLesson(subject.exams.nextDate, "Екзамен", .red)
            checkAndAddLesson(subject.tests.nextDate, "Залік", .purple)
            checkAndAddLesson(subject.consultations.nextDate, "Консультація", .blue)
        }
        
        DispatchQueue.main.async {
            self.upcomingLessons = lessons.sorted { $0.date < $1.date }
        }
    }
    
    func filteredStatistics(for semester: Int) -> [SubjectStatistics] {
        return filteredStatsBySemester[semester] ?? []
    }
}

struct SubjectDetailView: View {
    let subject: SubjectStatistics
    @Environment(\.dismiss) private var dismiss
    @State private var showingTimeline = false
    @State private var selectedLessons: (title: String, lessons: SubjectStatistics.LessonCount, type: String)? = nil
    
    var body: some View {
        ZStack {
            Color(red: 0.10, green: 0.14, blue: 0.24).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Text(subject.subjectName)
                        .font(.custom("Inter", size: 24).weight(.bold))
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    if subject.practicalLessons.total > 0 {
                        DetailSection(
                            title: "Практичні заняття",
                            count: subject.practicalLessons,
                            color: .green,
                            type: "Пз"
                        ) { lessons in
                            selectedLessons = ("Практичні заняття", lessons, "Пз")
                            showingTimeline = true
                        }
                    }
                    
                    if subject.laboratoryWorks.total > 0 {
                        DetailSection(
                            title: "Лабораторні роботи",
                            count: subject.laboratoryWorks,
                            color: .cyan,
                            type: "Лб"
                        ) { lessons in
                            selectedLessons = ("Лабораторні роботи", lessons, "Лб")
                            showingTimeline = true
                        }
                    }
                    
                    if subject.exams.total > 0 {
                        DetailSection(
                            title: "Екзамени",
                            count: subject.exams,
                            color: .red,
                            type: "Екз"
                        ) { lessons in
                            selectedLessons = ("Екзамени", lessons, "Екз")
                            showingTimeline = true
                        }
                    } else if subject.tests.total > 0 {
                        DetailSection(
                            title: "Заліки",
                            count: subject.tests,
                            color: .purple,
                            type: "Зал"
                        ) { lessons in
                            selectedLessons = ("Заліки", lessons, "Зал")
                            showingTimeline = true
                        }
                    }
                    
                    if subject.consultations.total > 0 {
                        DetailSection(
                            title: "Консультації",
                            count: subject.consultations,
                            color: .blue,
                            type: "Конс"
                        ) { lessons in
                            selectedLessons = ("Консультації", lessons, "Конс")
                            showingTimeline = true
                        }
                    }
                }
                .padding()
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
        .navigationDestination(isPresented: $showingTimeline) {
            if let selected = selectedLessons {
                LessonTimelineView(
                    title: selected.title,
                    lessons: selected.lessons,
                    type: selected.type
                )
            }
        }
    }
}

struct DetailSection: View {
    let title: String
    let count: SubjectStatistics.LessonCount
    let color: Color
    let type: String
    @State private var showProgress = false
    var onTap: ((SubjectStatistics.LessonCount) -> Void)? = nil
    
    private var progress: Double {
        guard count.total > 0 else { return 0 }
        return min(Double(count.completed) / Double(count.total), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.custom("Inter", size: 18).weight(.semibold))
                .foregroundColor(.white)
            
            if count.total > 0 {
                Button(action: {
                    onTap?(count)
                }) {
                    HStack {
                        Text("Виконано: \(min(count.completed, count.total)) з \(count.total)")
                            .font(.custom("Inter", size: 16))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Spacer()
                        
                        Text("\(Int(progress * 100))%")
                            .font(.custom("Inter", size: 16).weight(.bold))
                            .foregroundColor(color)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(color.opacity(0.2))
                            
                            Rectangle()
                                .fill(color)
                                .frame(width: geometry.size.width * progress)
                        }
                    }
                    .frame(height: 8)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    if let nextDate = count.nextDate {
                        // Находим соответствующий интервал для следующей даты
                        if let nextInterval = count.allDates.first(where: { interval in
                            Calendar.current.isDate(interval.start, inSameDayAs: nextDate)
                        }) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(color)
                                Text("Наступне заняття: \(nextInterval.start.format("dd.MM.yyyy HH:mm")) - \(nextInterval.end.format("HH:mm"))")
                                    .font(.custom("Inter", size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                showProgress = true
            }
        }
    }
}

#Preview {
    SubjectStatisticsView(statistics: [
        SubjectStatistics(
            subjectName: "Програмування",
            practicalLessons: .init(
                completed: 5,
                total: 10,
                nextDate: Date().addingTimeInterval(60 * 60 * 24),
                allDates: [
                    (start: Date().addingTimeInterval(-86400 * 3), end: Date().addingTimeInterval(-86400 * 3 + 3600)),
                    (start: Date().addingTimeInterval(-86400), end: Date().addingTimeInterval(-86400 + 3600))
                ]
            ),
            laboratoryWorks: .init(
                completed: 3,
                total: 6,
                nextDate: Date().addingTimeInterval(60 * 60 * 48),
                allDates: [
                    (start: Date().addingTimeInterval(-86400 * 4), end: Date().addingTimeInterval(-86400 * 4 + 3600))
                ]
            ),
            exams: .init(
                completed: 0,
                total: 1,
                nextDate: Date().addingTimeInterval(60 * 60 * 72),
                allDates: []
            ),
            consultations: .init(
                completed: 1,
                total: 2,
                nextDate: nil,
                allDates: []
            ),
            tests: .init(
                completed: 1,
                total: 1,
                nextDate: nil,
                allDates: []
            )
        )
    ])
}
