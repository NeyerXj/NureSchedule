import SwiftUI
import AVFoundation
import Network
import UserNotifications

// MARK: - Модель данных для групп
struct Group: Identifiable, Decodable {
    let id: Int
    let name: String
}

// MARK: - Модель данных для преподавателей
struct Teacher: Identifiable, Decodable {
    let id: Int
    let name: String
    let fullName: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name = "shortName"
        case fullName = "fullName"
    }
}
// MARK: - AcademicProgressBar
struct AcademicProgressBar: View {
    @AppStorage("progressEndDate") private var progressEndDate: Double = Date().timeIntervalSince1970
    @State private var animatedProgress: Double = 0
    @State private var animatedPercentage: Int = 0

    /// Определяет дату начала отсчета (1 сентября прошлого или текущего года)
    private var startOfAcademicYear: Date {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)

        let academicYearStart: DateComponents

        if (10...12).contains(currentMonth) {
            // Если сейчас октябрь-декабрь, начало от 1 сентября этого года
            academicYearStart = DateComponents(year: currentYear, month: 9, day: 1)
        } else {
            // Если сейчас январь-май, начало от 1 сентября прошлого года
            academicYearStart = DateComponents(year: currentYear - 1, month: 9, day: 1)
        }

        return calendar.date(from: academicYearStart) ?? now
    }

    /// Проверяет `progressEndDate` и ограничивает его маем или июнем
    private var validatedEndDate: Date {
        let calendar = Calendar.current
        let now = Date()
        var endDate = Date(timeIntervalSince1970: progressEndDate)

        let components = calendar.dateComponents([.year, .month, .day], from: endDate)
        let year = components.year ?? calendar.component(.year, from: now)
        let month = components.month ?? 5
        let day = components.day ?? 31

        var correctedDate: Date?

        if month < 5 {
            correctedDate = calendar.date(from: DateComponents(year: year, month: 5, day: 1)) // 1 мая
        } else if month > 6 {
            correctedDate = calendar.date(from: DateComponents(year: year, month: 6, day: 30)) // 30 июня
        } else {
            correctedDate = calendar.date(from: DateComponents(year: year, month: month, day: day))
        }

        if let finalDate = correctedDate, finalDate != endDate {
            progressEndDate = finalDate.timeIntervalSince1970
            return finalDate
        }

        return endDate
    }

    /// Вычисляет прогресс от начала учебного года (1 сентября) до `progressEndDate`
    var progress: Double {
        let now = Date()
        let endDate = validatedEndDate
        let totalDays = endDate.timeIntervalSince(startOfAcademicYear) / (60 * 60 * 24)
        let passedDays = now.timeIntervalSince(startOfAcademicYear) / (60 * 60 * 24)

        return min(max(passedDays / totalDays, 0), 1)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .frame(height: 6)
                        .foregroundColor(Color.gray.opacity(0.3))

                    RoundedRectangle(cornerRadius: 5)
                        .frame(width: geometry.size.width * CGFloat(animatedProgress), height: 6)
                        .foregroundColor(Color(red: 1 - animatedProgress, green: animatedProgress, blue: 0))
                }
                .animation(.easeInOut(duration: 1), value: animatedProgress)
            }
            .frame(height: 6)

            Text("\(animatedPercentage) %")
                .font(Font.custom("Inter", size: 14).weight(.semibold))
                .foregroundColor(.white)
                .animation(.easeInOut(duration: 1), value: animatedPercentage)
        }
        .onAppear {
            animatedProgress = 0
            animatedPercentage = 0

            withAnimation(.easeInOut(duration: 1)) {
                animatedProgress = progress
            }

            DispatchQueue.global(qos: .userInteractive).async {
                for i in 0...Int(progress * 100) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + (Double(i) / 100.0)) {
                        animatedPercentage = i
                    }
                }
            }
        }
    }
}


// MARK: - NetworkMonitor для отслеживания интернет-соединения
class NetworkMonitor: ObservableObject {
    @Published var isConnected: Bool = true
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    init() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isConnected = (path.status == .satisfied)
            }
        }
        monitor.start(queue: queue)
    }
}

// MARK: - CacheManager для сохранения/загрузки данных
struct CacheManager {
    static func cacheURL(for filename: String) -> URL? {
        let fm = FileManager.default
        if let cachesDirectory = fm.urls(for: .cachesDirectory, in: .userDomainMask).first {
            return cachesDirectory.appendingPathComponent(filename)
        }
        return nil
    }
    
    static func save(data: Data, filename: String) {
        guard let url = cacheURL(for: filename) else { return }
        do {
            try data.write(to: url)
        } catch {
            print("Ошибка сохранения кэша: \(error)")
        }
    }
    
    static func load(filename: String) -> Data? {
        guard let url = cacheURL(for: filename) else { return nil }
        return try? Data(contentsOf: url)
    }
}
struct RotatingLoaderView: View {
    @State private var isRotating = false
    @State private var opacity: Double = 0 // Добавляем состояние для прозрачности
    var isFetchingSchedule: Bool

    var body: some View {
        if isFetchingSchedule {
            Image(systemName: "arrow.triangle.2.circlepath")
                .resizable()
                .frame(width: 24, height: 20)
                .foregroundStyle(.red)
                .rotationEffect(.degrees(isRotating ? 360 : 0))
                .opacity(opacity) // Применяем прозрачность
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isRotating)
                .onAppear { 
                    // Запускаем обе анимации при появлении
                    withAnimation(.easeIn(duration: 0.3)) {
                        opacity = 1
                    }
                    isRotating = true 
                }
                .onDisappear { 
                    withAnimation(.easeOut(duration: 0.3)) {
                        opacity = 0
                    }
                    isRotating = false 
                }
        }
    }
    
}

// MARK: - ContentView
struct ContentView: View {
    @AppStorage("isShowSubjectStatistics") private var isShowSubjectStatistics: Bool = false
    @State private var showingStatistics = false

    var academicProgress: Double {
        let calendar = Calendar.current
        let today = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: today)
        guard let month = components.month,
              let year = components.year else { return 0 }
        
        var startDate: Date
        var endDate: Date
        if month >= 9 {
            // Если сейчас сентябрь-декабрь: академический год начинается в этом году и заканчивается в следующем мае
            startDate = calendar.date(from: DateComponents(year: year, month: 9, day: 1))!
            endDate = calendar.date(from: DateComponents(year: year + 1, month: 5, day: 31))!
        } else if month <= 5 {
            // Если сейчас январь-май: академический год начался в прошлом сентябре и заканчивается в этом мае
            startDate = calendar.date(from: DateComponents(year: year - 1, month: 9, day: 1))!
            endDate = calendar.date(from: DateComponents(year: year, month: 5, day: 31))!
        } else {
            // Для месяцев июнь-август можно вернуть 0 (или другое значение по необходимости)
            return 0
        }
        
        let total = endDate.timeIntervalSince(startDate)
        let elapsed = today.timeIntervalSince(startDate)
        return max(0, min(1, elapsed / total))
    }
    @State private var currentWindowStartIndex: Int = 0
    @State private var isWeekVievMode: Bool = false
    
    @State private var isTeacherMode: Bool = false
    @Namespace var namespaceForSett
    @AppStorage("isInfinityPlaing") private var isPlaying: Bool = false
    @AppStorage("isProgessBar") private var isProgessBar: Bool = false
    @AppStorage("isGestrue") private var isGestrue: Bool = true
    
    @State private var isOnceLoaded: Bool = false
    
    @State var currentDate: Date = .init()
    @State var weekSlider: [[Date.WeekDay]] = []
    
    @Namespace private var detailNamespace
    
    @State private var isFetchingSchedule: Bool = false
    
    @State private var selectedGroup: String = "Выберите группу" // Текущая выбранная группа
    @State private var selectedGroupId: Int? = nil // ID выбранной группы
    // Для преподавательского режима
    @State private var selectedTeacher: String = "Выберите преподавателя" // Текущая выбранный преподаватель
    @State private var selectedTeacherId: Int? = nil // ID выбранного преподавателя
    @State private var isShowingPopover: Bool = false // Для управления состоянием попапа
    @State private var searchText: String = "" // Текст поиска

    @State private var allGroups: [Group] = [] // Список групп, загруженный из API
    @State private var allTeachers: [Teacher] = [] // Список преподавателей, загруженный из API
    @State private var isLoading: Bool = false // Состояние загрузки данных с API
    @State private var play: Bool = true
    @State private var apiConnection: Bool = true
    @State private var isOnceLoadedNotif: Bool = false
    
    @State private var shouldCheckForNotificationNavigation = true

    // Фильтрованные группы
    var filteredGroups: [Group] {
        if searchText.isEmpty {
            return allGroups
        } else {
            return allGroups.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    @State var currentWeekIndex: Int = 1
    @Namespace private var animation
    @State private var createWeek: Bool = true
    @State private var timer: Timer?
    
    // Основной массив задач (пар), загружаемый из API
    @State private var tasks: [Task] = []
    
    // Сущность для мониторинга сети
    @StateObject private var networkMonitor = NetworkMonitor()

    @State private var isInitialLoadComplete: Bool = false

    // Добавляем новые состояния для контроля переключения режимов
    @State private var isModeSwitching: Bool = false
    @State private var pendingModeSwitch: Bool? = nil

    // Добавьте новое состояние для отслеживания начальной точки свайпа
    @State private var swipeStartLocation: CGFloat = 0

    // Добавьте новое состояние для отслеживания активного свайпа
    @State private var isSwipingDay: Bool = false

    // Добавьте новое состояние
    @State private var isNavigationActive: Bool = false

    // Обновите состояния в начале ContentView
    @State private var isShowingOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    @State private var isShowingFeatureTour = !UserDefaults.standard.bool(forKey: "hasSeenFeatureTour")

    @State private var cachedStatistics: [SubjectStatistics]? = nil
    @State private var lastScheduleHash: String = ""
    @State private var hasLoadedInitialStatistics = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Верхняя часть экрана (название выбранной группы и выбор недели)
                
                VStack(alignment: .leading) {
                    HStack {
                        Text(isTeacherMode ? selectedTeacher : selectedGroup)
                            .font(
                                Font.custom("Inter", size: 30)
                                    .weight(.bold)
                            )
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .foregroundColor(.white.opacity(0.94))
                        
                        // Группируем индикаторы состояния
                        HStack(spacing: 8) {
                            if !networkMonitor.isConnected {
                                Image(systemName: "wifi.slash")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(.red)
                                    .transition(.opacity)
                            }
                            
                            RotatingLoaderView(isFetchingSchedule: isFetchingSchedule)
                                .transition(.opacity) // Добавляем transition
                            
                            if !apiConnection {
                                Image("noapi")
                                    .resizable()
                                    .frame(width: 22, height: 22)
                                    .foregroundStyle(.red)
                                    .scaledToFill()
                                    .offset(y: 2)
                                    .transition(.opacity)
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
                        .animation(.easeInOut(duration: 0.3), value: isFetchingSchedule)
                        .animation(.easeInOut(duration: 0.3), value: apiConnection)
                        
                        Spacer()
                        
                        Button(action: {
    
                            if isTeacherMode {
                                fetchTeachers()
                            } else {
                                fetchGroups()
                            }
                            isShowingPopover.toggle()
                        }) {
                            Image(systemName: "person.3.fill")
                                .resizable()
                                .frame(width: 28, height: 14)
                                .foregroundColor(.black)
                                .padding()
                                .background(Color(red: 0.46, green: 0.61, blue: 0.95))
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .sheet(isPresented: $isShowingPopover) {
                            ZStack {
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.10, green: 0.14, blue: 0.24),
                                        Color(red: 0.05, green: 0.07, blue: 0.15)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .ignoresSafeArea()
                                
                                VStack(spacing: 16) {
                                    Text("Оберіть групу")
                                        .font(.custom("Inter", size: 24).weight(.bold))
                                        .foregroundColor(.white)
                                        .padding(.top, 16)
                                    
                                    CustomTextField(text: $searchText, placeholder: "Пошук групи...")
                                        .frame(height: 40)
                                        .padding()
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(12)
                                        .foregroundColor(.white)
                                        .font(.custom("Inter", size: 16))
                                        .padding(.horizontal, 16)
                                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                    
                                    if isLoading {
                                        VStack { LoadingView(isLoading:$isLoading) }
                                    } else if isTeacherMode {
                                        List {
                                            ForEach(filteredTeachers) { teacher in
                                                Button(action: {
                                                    selectTeacher(teacher: teacher)
                                                    isShowingPopover = false
                                                }) {
                                                    HStack {
                                                        Text(teacher.name)
                                                            .font(.custom("Inter", size: 16).weight(.semibold))
                                                            .foregroundColor(.white)
                                                        Spacer()
                                                        Image(systemName: "chevron.right")
                                                            .foregroundColor(.white.opacity(0.5))
                                                    }
                                                    .padding()
                                                    .background(Color(red: 0.15, green: 0.20, blue: 0.35))
                                                    .cornerRadius(12)
                                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                                }
                                                .listRowBackground(Color.clear)
                                            }
                                        }
                                        .listStyle(PlainListStyle())
                                        .scrollContentBackground(.hidden)
                                        .background(Color.clear)
                                    } else {
                                        List {
                                            ForEach(filteredGroups) { group in
                                                Button(action: {
                                                    selectGroup(group: group)
                                                    isShowingPopover = false
                                                }) {
                                                    HStack {
                                                        Text(group.name)
                                                            .font(.custom("Inter", size: 16).weight(.semibold))
                                                            .foregroundColor(.white)
                                                        Spacer()
                                                        Image(systemName: "chevron.right")
                                                            .foregroundColor(.white.opacity(0.5))
                                                    }
                                                    .padding()
                                                    .background(Color(red: 0.15, green: 0.20, blue: 0.35))
                                                    .cornerRadius(12)
                                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                                }
                                                .listRowBackground(Color.clear)
                                            }
                                        }
                                        .listStyle(PlainListStyle())
                                        .scrollContentBackground(.hidden)
                                        .background(Color.clear)
                                    }
                                }
                                .padding()
                            }
                        }
                        NavigationLink {
                            FullScreenWeeklyScheduleView(
                                tasks: tasks,
                                selectedGroup: $selectedGroup,
                                isShowingPopover: $isShowingPopover,
                                isTeacherMode: $isTeacherMode,
                                selectedTeacher: $selectedTeacher
                            )
                            .navigationTransition(.zoom(sourceID: "scheduleIcon", in: namespaceForSett))
                        } label: {
                            VStack {
                                Image(systemName: "calendar")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.black)
                                    .padding(11)
                                    .background(Color(red: 0.46, green: 0.61, blue: 0.95))
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                            }
                            .matchedTransitionSource(id: "scheduleIcon", in: namespaceForSett)
                        }
                        .padding(.leading, 0)
                        .accessibilityLabel("Розклад")

                        if isShowSubjectStatistics {
                            NavigationLink(isActive: $showingStatistics) {
                                if let statistics = cachedStatistics {
                                    SubjectStatisticsView(statistics: statistics)
                                }
                            } label: {
                                VStack {
                                    Image(systemName: "chart.bar.fill")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.black)
                                        .padding(11)
                                        .background(Color(red: 0.46, green: 0.61, blue: 0.95))
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                                }
                            }
                            .padding(.leading, 5)
                            .accessibilityLabel("Статистика")
                        }

                        NavigationLink {
                            ZStack {
                                SettingsSwiftUIView()
                                    .navigationTransition(.zoom(sourceID: "icon", in: namespaceForSett))
                            }
                        } label: {
                            VStack {
                                Image(systemName: "gearshape.fill")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.black)
                                    .padding(11)
                                    .background(Color(red: 0.46, green: 0.61, blue: 0.95))
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                            }
                            .matchedTransitionSource(id: "icon", in: namespaceForSett)
                        }
                        .padding(.leading, 5)
                        .accessibilityLabel("Настройки")
                    }
                                                    
                    if isProgessBar {
                        AcademicProgressBar()
                    }
                    // Переключение недель (TabView)
                    TabView(selection: $currentWeekIndex) {
                        ForEach(weekSlider.indices, id: \.self) { index in
                            let week = weekSlider[index]
                            weekView(week).tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 100)
                    
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background {
                    Rectangle()
                        .fill(.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                        .ignoresSafeArea()
                        .frame(height: isProgessBar ? 200 : 180)
                        .frame(maxHeight: .infinity, alignment: .top)
                }
                
                
                // Основная часть экрана: либо индикатор загрузки, либо список задач
                if isFetchingSchedule {
//                    LoadingView(isLoading:$isLoading)
                } else {
                    GeometryReader { geometry in
                        ScrollView(.vertical) {
                            VStack {
                                TaskView() // Список «пар»
                            }
                            .hSpacing(.center)
                            .vSpacing(.center)
                        }
                        .offset(y: -20)
                        .scrollIndicators(.hidden)
                        .highPriorityGesture(isGestrue ? DragGesture(minimumDistance: 30)
                            .onChanged { gesture in
                                let horizontalAmount = gesture.translation.width
                                let verticalAmount = gesture.translation.height
                                
                                // Если свайп преимущественно горизонтальный
                                if abs(horizontalAmount) > abs(verticalAmount) {
                                    isSwipingDay = true
                                    if swipeStartLocation == 0 {
                                        swipeStartLocation = gesture.location.x
                                    }
                                }
                            }
                            .onEnded { value in
                                defer { 
                                    swipeStartLocation = 0
                                    isSwipingDay = false
                                }
                                
                                let horizontalAmount = value.translation.width
                                let verticalAmount = value.translation.height
                                
                                if abs(horizontalAmount) > abs(verticalAmount) && abs(horizontalAmount) > 50 {
                                    withAnimation {
                                        if horizontalAmount > 0 {
                                            if let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) {
                                                performHapticFeedback()
                                                currentDate = previousDate
                                            }
                                        } else {
                                            if let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) {
                                                performHapticFeedback()
                                                currentDate = nextDate
                                            }
                                        }
                                    }
                                }
                            } : nil)
                    }
                }
            }.vSpacing(.top)
            .frame(maxWidth: .infinity)
            .background(Color(red:0.10,green:0.14,blue:0.24))
            .preferredColorScheme(.dark)
            .onAppear {
                // Загружаем сохраненный режим
                isTeacherMode = UserDefaults.standard.bool(forKey: "isTeacherMode")
                print("TeacherMode: \(isTeacherMode)")
                
                // Загружаем сохраненные данные в зависимости от режима
                if isTeacherMode {handleTeacherModeChange(); isOnceLoadedNotif = false} else {
                    print("TeacherMode: \(isTeacherMode)")
                    if let groupId = UserDefaults.standard.object(forKey: "selectedGroupId") as? Int,
                       let groupName = UserDefaults.standard.string(forKey: "selectedGroupName") {
                        selectedGroupId = groupId
                        selectedGroup = groupName
                        
                        fetchSchedule(forGroupId: groupId) { tasks in
                            DispatchQueue.main.async {
                                self.tasks = tasks
                            }
                        }
                        print("isOnce: \(isOnceLoadedNotif)")
                        if !isOnceLoadedNotif{
                            safeLoadingNotification(groupId: groupId)
                        }
                        isOnceLoadedNotif = true
                         
                    }
                }
                
                loadInitialData()
            }
            .onDisappear {
                NotificationCenter.default.removeObserver(self, name: .isTeacherModeChanged, object: nil)
            }.navigationBarBackButtonHidden(true)
            .overlay {
                if isShowingOnboarding {
                    OnboardingOverlayView(isShowingOnboarding: $isShowingOnboarding) {
                        // Callback после завершения онбординга
                        if !UserDefaults.standard.bool(forKey: "hasSeenFeatureTour") {
                            isShowingFeatureTour = true
                        }
                    }
                } else if isShowingFeatureTour {
                    FeatureTourView(isShowingTour: $isShowingFeatureTour)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowFeatureTour"))) { _ in
                isShowingFeatureTour = true
            }
        }
        .onChange(of: tasks) { _ in
            updateStatistics()
        }
        .onAppear {
            updateStatistics()
        }
    }
    
    private func safeLoadingNotification(groupId: Int) {
        fetchScheduleWithCache(forGroupId: groupId) { newTasks in
            DispatchQueue.main.async {
                self.tasks.removeAll()
                self.tasks = newTasks
            }
        }
    }
    
    private func handleTeacherModeChange() {
        // Очищаем текущее расписание и уведомления
        tasks = []
        NotificationManager.shared.cancelAllNotifications()
        
        // Показываем индикатор загрузки
        isFetchingSchedule = true
        
        if isTeacherMode {
            // Переключаемся на режим преподавателя
            selectedGroup = "Выберите группу"
            selectedGroupId = nil
            
            if let teacherId = UserDefaults.standard.object(forKey: "savedTeachersId") as? Int,
               let teacherName = UserDefaults.standard.string(forKey: "savedTeachersName") {
                selectedTeacherId = teacherId
                selectedTeacher = teacherName
                
                // Загружаем расписание преподавателя
                fetchTeacherScheduleWithCache(forTeacherId: teacherId) { newTasks in
                    DispatchQueue.main.async {
                        self.tasks = newTasks
                        self.isFetchingSchedule = false
                        // Обновляем уведомления после загрузки расписания
                        NotificationManager.shared.updateScheduleNotifications(force: true)
                    }
                }
            } else {
                self.isFetchingSchedule = false
            }
        } else {
            // Переключаемся на режим группы
            selectedTeacher = "Выберите преподавателя"
            selectedTeacherId = nil
            
            if let groupId = UserDefaults.standard.object(forKey: "selectedGroupId") as? Int,
               let groupName = UserDefaults.standard.string(forKey: "selectedGroupName") {
                selectedGroupId = groupId
                selectedGroup = groupName
                
                // Загружаем расписание группы
                fetchScheduleWithCache(forGroupId: groupId) { newTasks in
                    DispatchQueue.main.async {
                        self.tasks = newTasks
                        self.isFetchingSchedule = false
                        // Обновляем уведомления после загрузки расписания
                        NotificationManager.shared.updateScheduleNotifications(force: true)
                    }
                }
            } else {
                self.isFetchingSchedule = false
            }
        }
        
        // Сохраняем режим
        UserDefaults.standard.set(isTeacherMode, forKey: "isTeacherMode")
    }
    
    // MARK: - Функция для выбора группы
    func selectGroup(group: Group) {
        isShowingPopover = false
        isFetchingSchedule = true
        tasks = []
        
        // Обновляем режим преподавателя
        isTeacherMode = false
        UserDefaults.standard.set(false, forKey: "isTeacherMode")
        
        selectedGroupId = group.id
        selectedGroup = group.name
        UserDefaults.standard.set(group.id, forKey: "selectedGroupId")
        UserDefaults.standard.set(group.name, forKey: "selectedGroupName")
        
        fetchScheduleWithCache(forGroupId: group.id) { newTasks in
            DispatchQueue.main.async {
                if self.tasks != newTasks { // Проверяем, изменилось ли расписание
                    self.tasks = newTasks
                    NotificationManager.shared.updateScheduleNotifications(force: true)
                }
                self.isFetchingSchedule = false
            }
        }
    }
    
    func selectTeacher(teacher: Teacher) {
        isShowingPopover = false
        isFetchingSchedule = true
        tasks = []
        
        // Обновляем режим преподавателя
        isTeacherMode = true
        UserDefaults.standard.set(true, forKey: "isTeacherMode")
        
        selectedTeacherId = teacher.id
        selectedTeacher = teacher.fullName
        UserDefaults.standard.set(teacher.id, forKey: "savedTeachersId")
        UserDefaults.standard.set(teacher.fullName, forKey: "savedTeachersName")
        
        fetchTeacherScheduleWithCache(forTeacherId: teacher.id) { newTasks in
            DispatchQueue.main.async {
                if self.tasks != newTasks { // Проверяем, изменилось ли расписание
                    self.tasks = newTasks
                    NotificationManager.shared.updateScheduleNotifications(force: true)
                }
                self.isFetchingSchedule = false
            }
        }
    }
    
    // MARK: - Сохранение выбранных данных в UserDefaults
    func saveGroup(group: Group) {
        UserDefaults.standard.set(group.id, forKey: "selectedGroupId")
        UserDefaults.standard.set(group.name, forKey: "selectedGroupName")
    }
    
    func saveTeacher(teacher: Teacher) {
        UserDefaults.standard.set(teacher.id, forKey: "savedTeacherId")
        UserDefaults.standard.set(teacher.name, forKey: "savedTeachersName")
    }
    
    // MARK: - Загрузка сохранённых данных
    func loadSavedGroup() {
        if let savedGroupName = UserDefaults.standard.string(forKey: "selectedGroupName"),
           let savedGroupId = UserDefaults.standard.object(forKey: "selectedGroupId") as? Int {
            selectedGroup = savedGroupName
            selectedGroupId = savedGroupId
            
            fetchSchedule(forGroupId: savedGroupId) { tasks in
                DispatchQueue.main.async {
                    self.tasks = tasks
                }
            }
        }
    }
    
    func loadSavedTeachers() {
        if let savedTeachersName = UserDefaults.standard.string(forKey: "savedTeachersName"),
           let savedTeacherId = UserDefaults.standard.object(forKey: "savedTeacherId") as? Int {
            selectedTeacher = savedTeachersName
            selectedTeacherId = savedTeacherId
            
            fetchTeacherSchedual(forTeacherId: savedTeacherId) { tasks in
                DispatchQueue.main.async {
                    self.tasks = tasks
                }
            }
        }
    }
    
    // MARK: - Загрузка расписания для группы с кэшированием и повторной попыткой при отсутствии интернета
    func fetchSchedule(forGroupId groupId: Int, completion: @escaping ([Task]) -> Void) {
        DispatchQueue.main.async {
                self.isFetchingSchedule = true
            }
        guard let url = URL(string: "https://api.mindenit.org/schedule/groups/\(groupId)") else {
            print("Неверный URL")
            apiConnection = false
            DispatchQueue.main.async {
                        self.isFetchingSchedule = false
                    }
            return
        }
        isFetchingSchedule = true
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            // Если ошибка (например, отсутствие сети)
            if let error = error {
                print("Ошибка загрузки расписания: \(error.localizedDescription)")
                // Попытка загрузить данные из кэша
                if let cachedData = CacheManager.load(filename: "schedule_group_\(groupId).json") {
                    decodeAndProcessScheduleData(from: cachedData, groupId: groupId, completion: completion)
                } else {
                    DispatchQueue.main.async {
                                self.isFetchingSchedule = false
                            }
                    waitForConnection {
                        self.fetchSchedule(forGroupId: groupId, completion: completion)
                        isLoading = false
                        DispatchQueue.main.async {
                                    self.isFetchingSchedule = false
                                }
                    }
                }
                return
            }
            
            guard let data = data else {
                print("Данные отсутствуют")
                self.isFetchingSchedule = false
                return
            }
            
            // Сохраняем полученные данные в кэш
            CacheManager.save(data: data, filename: "schedule_group_\(groupId).json")
            decodeAndProcessScheduleData(from: data, groupId: groupId, completion: completion)
            apiConnection = true
            isLoading = false
//            safeLoadingNotification(groupId: groupId)
        }.resume()
    }
    
    private func decodeAndProcessScheduleData(from data: Data, groupId: Int, completion: @escaping ([Task]) -> Void) {
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let scheduleItems = try decoder.decode([ScheduleItem].self, from: data)
            let tasks = processScheduleData(scheduleItems: scheduleItems)
            DispatchQueue.main.async {
                completion(tasks)
                self.isFetchingSchedule = false
            }
        } catch {
            print("Ошибка декодирования данных расписания: \(error)")
            DispatchQueue.main.async {
                self.isFetchingSchedule = false
            }
        }
    }
    
    // MARK: - Загрузка расписания для преподавателя с кэшированием и повторной попыткой при отсутствии интернета
    func fetchTeacherSchedual(forTeacherId teacherId: Int, completion: @escaping ([Task]) -> Void) {
        DispatchQueue.main.async {
                self.isFetchingSchedule = true
            }
        guard let url = URL(string: "https://api.mindenit.org/schedule/teachers/\(teacherId)") else {
            print("Неверный URL")
            apiConnection = false
            DispatchQueue.main.async {
                self.isFetchingSchedule = false
                }
            return
        }
        isFetchingSchedule = true
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Ошибка загрузки расписания преподавателя: \(error.localizedDescription)")
                if let cachedData = CacheManager.load(filename: "schedule_teacher_\(teacherId).json") {
                    decodeAndProcessTeacherData(from: cachedData, teacherId: teacherId, completion: completion)
                } else {
                    DispatchQueue.main.async {
                            self.isFetchingSchedule = false
                        }
                    waitForConnection {
                        self.fetchTeacherSchedual(forTeacherId: teacherId, completion: completion)
                    }
                }
                return
            }
            
            guard let data = data else {
                print("Данные отсутствуют")
                DispatchQueue.main.async {
                                self.isFetchingSchedule = false
                            }
                return
            }
            apiConnection = true
            CacheManager.save(data: data, filename: "schedule_teacher_\(teacherId).json")
            decodeAndProcessTeacherData(from: data, teacherId: teacherId, completion: completion)
        }.resume()
    }
    
    private func decodeAndProcessTeacherData(from data: Data, teacherId: Int, completion: @escaping ([Task]) -> Void) {
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let scheduleItems = try decoder.decode([TeacherAPI].self, from: data)
            let tasks = processScheduleTeacherData(scheduleItems: scheduleItems)
            DispatchQueue.main.async {
                completion(tasks)
                self.isFetchingSchedule = false
            }
        } catch {
            print("Ошибка декодирования данных расписания преподавателя: \(error)")
            DispatchQueue.main.async {
                self.isFetchingSchedule = false
            }
        }
    }
    
    func waitForConnection(completion: @escaping () -> Void) {
        // Если интернет уже есть, сразу вызываем completion
        if networkMonitor.isConnected {
            print("[DEBUG] Интернет-соединение установлено. Выполняем completion.")
            completion()
        } else {
            print("[DEBUG] Интернет-соединение отсутствует. Ожидание подключения...")
            // Подписываемся на изменение состояния сети
            let cancellable = networkMonitor.$isConnected.sink { connected in
                if connected {
                    print("[DEBUG] Интернет-соединение восстановлено. Выполнение completion через 1 секунду...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        completion()
                    }
                }
            }
            // Если нужно – можно сохранить ссылку на cancellable для отмены подписки позже.
            _ = cancellable
        }
    }
    
    // MARK: - Функция для загрузки преподавателей
    func fetchTeachers() {
        DispatchQueue.main.async { self.isLoading = true }
        guard let url = URL(string: "https://api.mindenit.org/lists/teachers") else {
            print("Неверный URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            defer { DispatchQueue.main.async { self.isLoading = false } }
            if let error = error {
                print("Ошибка загрузки преподавателей: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                print("Данные отсутствуют")
                return
            }
            
            do {
                let decodedTeachers = try JSONDecoder().decode([Teacher].self, from: data)
                DispatchQueue.main.async {
                    self.allTeachers = decodedTeachers
                }
                print("Успешная загрузка преподавателей")
            } catch {
                print("Ошибка декодирования данных преподавателей: \(error)")
            }
        }.resume()
    }
    
    // MARK: - Фильтрация преподавателей
    var filteredTeachers: [Teacher] {
        if searchText.isEmpty {
            return allTeachers
        } else {
            return allTeachers.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    // MARK: - Функция для загрузки групп с API
    func fetchGroups() {
        DispatchQueue.main.async { self.isLoading = true }
        guard let url = URL(string: "https://api.mindenit.org/lists/groups") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            defer { DispatchQueue.main.async { self.isLoading = false } }
            if let error = error {
                print("Ошибка загрузки групп: \(error.localizedDescription)")
                return
            }
            guard let data = data else { return }
            do {
                let decodedGroups = try JSONDecoder().decode([Group].self, from: data)
                DispatchQueue.main.async {
                    self.allGroups = decodedGroups
                }
            } catch {
                print("Ошибка декодирования данных групп: \(error)")
            }
        }.resume()
    }
    
    // MARK: - Отображение списка «пар»
    @ViewBuilder
    func TaskView() -> some View {
        VStack(alignment: .leading) {
            if !isWeekVievMode {
                ForEach(tasks.indices.filter { isSameDay(tasks[$0].date, currentDate) }, id: \.self) { index in
                    NavigationLink(destination: DetailView(task: tasks[index], namespace: detailNamespace)
                        .navigationTransition(.zoom(sourceID: "detail", in: detailNamespace))) {
                        TaskItem(task: $tasks[index], namespace: detailNamespace)
                            .background(alignment: .leading) {
                                let filteredTasks = tasks.filter { isSameDay($0.date, currentDate) }
                                let isLastForToday = index == tasks.firstIndex(where: { $0.id == filteredTasks.last?.id })
                                
                                if !isLastForToday {
                                    ZStack(alignment: .top) {
                                        // Фоновая линия
                                        Rectangle()
                                            .frame(width: 1)
                                            .frame(height: getProgressLineHeight(from: tasks[index], to: tasks[index + 1]))
                                            .foregroundColor(.black)
                                        
                                        // Линия прогресса
                                        Rectangle()
                                            .frame(width: 1)
                                            .frame(height: progressHeight(for: tasks[index]))
                                            .foregroundColor(.green)
                                    }
                                    .offset(x: 24, y: getLineOffset(for: tasks[index]))
                                }
                            }
                    }
                }
            } else {
                // Реализуйте отображение для режима просмотра недели, если требуется
            }
        }
        .padding(.top)
    }
    
    // Обновляем функции для прогресс-бара
    private func getLineHeight(for task: Task) -> CGFloat {
        if task.title == "Break" {
            return 40
        } else if !task.subTasks.isEmpty {
            return 120 // Высота для сгруппированных задач
        } else {
            return 70 // Уменьшаем высоту для обычных пар
        }
    }

    private func getLineOffset(for task: Task) -> CGFloat {
            if task.title == "Break" {
            return 35 // Для перерыва
            } else if !task.subTasks.isEmpty {
            return 35 // Для сгруппированных задач - начинаем от верха
            } else {
            return 30 // Уменьшаем смещение для обычных пар
        }
    }

    func progressHeight(for task: Task) -> CGFloat {
        guard let nextTask = nextTask(after: task) else {
            return 0
        }
        
        let now = Date()
        let taskStart = task.date
        let taskEnd = nextTask.date
        
        // Если время еще не наступило
        if now < taskStart {
            return 0
        }
        
        // Если время уже прошло
        if now > taskEnd {
            return getProgressLineHeight(from: task, to: nextTask)
        }
        
        // Вычисляем прогресс
        let totalDuration = taskEnd.timeIntervalSince(taskStart)
        let elapsed = now.timeIntervalSince(taskStart)
        let progress = max(0, min(1, elapsed / totalDuration))
        
        return CGFloat(progress * Double(getProgressLineHeight(from: task, to: nextTask)))
    }

    // Обновляем функцию расчета высоты линии прогресса
    private func getProgressLineHeight(from currentTask: Task, to nextTask: Task) -> CGFloat {
        let currentOffset = getLineOffset(for: currentTask)
        let nextOffset = getLineOffset(for: nextTask)
        
        // Рассчитываем высоту линии между задачами
        if currentTask.title == "Break" && !nextTask.subTasks.isEmpty {
            // От перерыва до групповой пары
            return abs(nextOffset - currentOffset) + 60
        } else if !currentTask.subTasks.isEmpty && nextTask.title == "Break" {
            // От групповой пары до перерыва
            return abs(nextOffset - currentOffset) + 120
        } else if currentTask.title == "Break" {
            // От перерыва до обычной пары
            return abs(nextOffset - currentOffset) + 50
        } else if nextTask.title == "Break" {
            // От обычной пары до перерыва
            return abs(nextOffset - currentOffset) + 65
        } else if currentTask.subTasks.isEmpty && !nextTask.subTasks.isEmpty {
            // От обычной пары до групповой
            return 85
        } else if !currentTask.subTasks.isEmpty && nextTask.subTasks.isEmpty {
            // От групповой пары до обычной
            return 85
        } else if !currentTask.subTasks.isEmpty && !nextTask.subTasks.isEmpty {
            // Между групповыми парами
            return 120
            } else {
            // Между обычными парами
            return 70
        }
    }

    // Функция для определения следующей задачи
    private func nextTask(after task: Task) -> Task? {
        guard let currentIndex = tasks.firstIndex(where: { $0.id == task.id }),
              currentIndex < tasks.count - 1 else {
            return nil
        }
        return tasks[currentIndex + 1]
    }
    
    // MARK: - Отображение недели (строка дат)
    @ViewBuilder
    func weekView(_ week: [Date.WeekDay]) -> some View {
        HStack(spacing: 0) {
            let daysToShow = isWeekVievMode ? Array(week.prefix(5)) : week
            
            ForEach(daysToShow) { day in
                ZStack {
                    
                    VStack{
                        Text(day.date.format("E").uppercased())
                            .font(Font.custom("Inter", size: 16).weight(.semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    
                    VStack{
                        Text(day.date.format("dd.MM"))
                            .font(Font.custom("Inter", size: 14).weight(.semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(width: 50, height: 55)
                            .foregroundStyle(isSameDay(day.date, currentDate) ? .white : .white.opacity(0.8))
                            .background {
                                if isSameDay(day.date, currentDate) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.black)
                                        .offset(y: 3)
                                        .matchedGeometryEffect(id: "TABINDICATOR", in: animation)
                                }
                                if day.date.isToday {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 5, height: 5)
                                        .vSpacing(.bottom)
                                }
                            }
                        
                    }
                }
                .hSpacing(.center)
                .onTapGesture {
                    if !isSwipingDay {
                        withAnimation(.snappy) {
                            currentDate = day.date
                        }
                    }
                }
            }
        }
        .background {
            GeometryReader { proxy in
                let minX = proxy.frame(in: .global).minX
                Color.clear
                    .preference(key: OffsetKey.self, value: minX)
                    .onPreferenceChange(OffsetKey.self) { value in
                        if abs(value) > 50 && createWeek {
                            paginateWeek()
                        }
                    }
            }
        }
    }
    
    // Сброс флага createWeek
    func resetCreateWeekFlag() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            createWeek = true
        }
    }
    
    // Подгрузка предыдущей/следующей недели
    func paginateWeek() {
        guard weekSlider.indices.contains(currentWeekIndex) else { return }
        if currentWeekIndex == 0,
           let firstDate = weekSlider[currentWeekIndex].first?.date {
            weekSlider.insert(firstDate.createPreviousWeek(), at: 0)
            currentWeekIndex += 1
        }
        if currentWeekIndex == (weekSlider.count - 1),
           let lastDate = weekSlider[currentWeekIndex].last?.date {
            weekSlider.append(lastDate.createNextWeek())
        }
        createWeek = false
        resetCreateWeekFlag()
    }
    
    // Функция для обновления расписания при смене группы
    private func updateScheduleForGroup(_ groupId: Int, groupName: String) {
        // Отменяем все старые уведомления
        NotificationManager.shared.cancelAllNotifications()
        
        // Сохраняем новую группу
        selectedGroupId = groupId
        selectedGroup = groupName
        UserDefaults.standard.set(groupId, forKey: "selectedGroupId")
        UserDefaults.standard.set(groupName, forKey: "selectedGroupName")
        
        // Обновляем расписание и уведомления
        NotificationManager.shared.updateScheduleNotifications()
    }
    
    // Функция для обновления расписания при смене преподавателя
    private func updateScheduleForTeacher(_ teacherId: Int, teacherName: String) {
        // Отменяем все старые уведомления
        NotificationManager.shared.cancelAllNotifications()
        
        // Сохраняем нового преподавателя
        selectedTeacherId = teacherId
        selectedTeacher = teacherName
        UserDefaults.standard.set(teacherId, forKey: "savedTeachersId")
        UserDefaults.standard.set(teacherName, forKey: "savedTeachersName")
        
        // Обновляем расписание и уведомления
        NotificationManager.shared.updateScheduleNotifications()
    }

    private func loadInitialData() {
        
        // Сначала загружаем UI и основные данные
        if weekSlider.isEmpty {
            let currentWeek = Date().fetchWeek()
            if let firstDate = currentWeek.first?.date {
                weekSlider.append(firstDate.createPreviousWeek())
            }
            weekSlider.append(currentWeek)
            if let lastDate = currentWeek.last?.date {
                weekSlider.append(lastDate.createNextWeek())
            }
        }
        
        // Проверяем навигацию по уведомлениям
        if shouldCheckForNotificationNavigation && UserDefaults.standard.bool(forKey: "should_navigate_to_date") {
            if let timestamp = UserDefaults.standard.object(forKey: "notification_selected_date") as? TimeInterval {
                let date = Date(timeIntervalSince1970: timestamp)
                withAnimation {
                    currentDate = date
                }
            }
            UserDefaults.standard.set(false, forKey: "should_navigate_to_date")
            shouldCheckForNotificationNavigation = false
        }
        
        // Отложенно загружаем уведомления
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // Даем время для отрисовки UI
            loadNotifications()
        }
    }

    private func loadNotifications() {
        // Запускаем в фоновой очереди
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async {
                isInitialLoadComplete = true
            }
        }
    }

    // Обновляем функцию toggleTeacherMode
    func toggleTeacherMode() {
        // Проверяем, не выполняется ли уже переключение режима
        guard !isModeSwitching else {
            // Сохраняем ожидающее изменение режима
            pendingModeSwitch = !isTeacherMode
            return
        }
        
        isModeSwitching = true
        
        // Очищаем текущие данные и уведомления
        tasks = []
        NotificationManager.shared.cancelAllNotifications()
        
        // Показываем индикатор загрузки
        isFetchingSchedule = true
        
        // Переключаем режим
        isTeacherMode.toggle()
        
        // Добавляем небольшую задержку перед загрузкой новых данных
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if isTeacherMode {
                // Переключаемся на режим преподавателя
                selectedGroup = "Выберите группу"
                selectedGroupId = nil
                
                if let teacherId = UserDefaults.standard.object(forKey: "savedTeachersId") as? Int,
                   let teacherName = UserDefaults.standard.string(forKey: "savedTeachersName") {
                    selectedTeacherId = teacherId
                    selectedTeacher = teacherName
                    
                    // Загружаем расписание преподавателя
                    fetchTeacherScheduleWithCache(forTeacherId: teacherId) { newTasks in
                        DispatchQueue.main.async {
                            self.tasks = newTasks
                            self.isFetchingSchedule = false
                            self.isModeSwitching = false
                            
                            // Проверяем, есть ли ожидающее переключение
                            if let pendingMode = self.pendingModeSwitch {
                                self.pendingModeSwitch = nil
                                if pendingMode != self.isTeacherMode {
                                    self.toggleTeacherMode()
                                }
                            }
                        }
                    }
                }
            } else {
                // Переключаемся на режим группы
                selectedTeacher = "Выберите преподавателя"
                selectedTeacherId = nil
                
                if let groupId = UserDefaults.standard.object(forKey: "selectedGroupId") as? Int,
                   let groupName = UserDefaults.standard.string(forKey: "selectedGroupName") {
                    selectedGroupId = groupId
                    selectedGroup = groupName
                    
                    // Загружаем расписание группы
                    fetchScheduleWithCache(forGroupId: groupId) { newTasks in
                        DispatchQueue.main.async {
                            self.tasks = newTasks
                            self.isFetchingSchedule = false
                            self.isModeSwitching = false
                            
                            // Проверяем, есть ли ожидающее переключение
                            if let pendingMode = self.pendingModeSwitch {
                                self.pendingModeSwitch = nil
                                if pendingMode != self.isTeacherMode {
                                    self.toggleTeacherMode()
                                }
                            }
                        }
            }
        } else {
                    selectedGroup = "Выберите группу"
                    selectedGroupId = nil
                    isShowingPopover = true
                    isFetchingSchedule = false
                    isModeSwitching = false
                }
                
                loadSavedGroup()
                fetchGroups()
            }
            
            // Сохраняем режим
            UserDefaults.standard.set(isTeacherMode, forKey: "isTeacherMode")
        }
    }

    private func performHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    private func calculateScheduleHash() -> String {
        return tasks.map { task in
            "\(task.title)_\(task.date.timeIntervalSince1970)_\(task.type)_\(task.auditory)"
        }.sorted().joined()
    }
    
    private func updateStatistics() {
        // Проверяем, загружена ли начальная статистика
        guard !hasLoadedInitialStatistics else { return }
        
        let newHash = calculateScheduleHash()
        if newHash != lastScheduleHash {
            print("📊 Загрузка начальной статистики")
            cachedStatistics = SubjectStatistics.calculateStatistics(from: tasks)
            lastScheduleHash = newHash
            hasLoadedInitialStatistics = true
        }
    }
}

// MARK: - Превью (для Canvas)
#Preview {
    ContentView()
}

// MARK: - API Cache Manager
private extension ContentView {
    func fetchScheduleWithCache(forGroupId groupId: Int, completion: @escaping ([Task]) -> Void) {
        // Очищаем старые уведомления перед загрузкой нового расписания
        NotificationManager.shared.cancelAllNotifications()
        
        // Проверяем наличие кэша и его актуальность
        if let cachedData = CacheManager.load(filename: "schedule_group_\(groupId).json"),
           let cacheDate = UserDefaults.standard.object(forKey: "cache_date_\(groupId)") as? Date,
           Date().timeIntervalSince(cacheDate) < 300 { // Кэш валиден 5 минут
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let scheduleItems = try decoder.decode([ScheduleItem].self, from: cachedData)
                let tasks = processScheduleData(scheduleItems: scheduleItems)
                
                // Сохраняем в кэш с новым ID группы
                CacheManager.save(data: cachedData, filename: "schedule_group_\(groupId).json")
                UserDefaults.standard.set(Date(), forKey: "cache_date_\(groupId)")
                
                // Планируем новые уведомления
                tasks.forEach { task in
                    NotificationManager.shared.scheduleLessonNotification(for: task)
                }
                
                DispatchQueue.main.async {
                    apiConnection = true
                    completion(tasks)
                }
            } catch {
                print("Ошибка декодирования кэша: \(error)")
            }
        }
        
        // Если кэш отсутствует или устарел - загружаем с API
        guard let url = URL(string: "https://api.mindenit.org/schedule/groups/\(groupId)") else {
            print("Неверный URL")
            apiConnection = false
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Ошибка загрузки: \(error)")
                apiConnection = false
                return
            }
            
            guard let data = data else {
                print("Нет данных")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let scheduleItems = try decoder.decode([ScheduleItem].self, from: data)
                
                // Сохраняем в кэш с новым ID группы
                CacheManager.save(data: data, filename: "schedule_group_\(groupId).json")
                UserDefaults.standard.set(Date(), forKey: "cache_date_\(groupId)")
                
                let tasks = processScheduleData(scheduleItems: scheduleItems)
                
                // Планируем новые уведомления
                tasks.forEach { task in
                    NotificationManager.shared.scheduleLessonNotification(for: task)
                }
                
                DispatchQueue.main.async {
                    apiConnection = true
                    completion(tasks)
                }
            } catch {
                print("Ошибка декодирования: \(error)")
            }
        }
        task.resume()
    }
    
    func fetchTeacherScheduleWithCache(forTeacherId teacherId: Int, completion: @escaping ([Task]) -> Void) {
        // Проверяем кэш
        if let cachedData = CacheManager.load(filename: "schedule_teacher_\(teacherId).json"),
           let cacheDate = UserDefaults.standard.object(forKey: "cache_date_teacher_\(teacherId)") as? Date,
           Date().timeIntervalSince(cacheDate) < 300 {
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let scheduleItems = try decoder.decode([TeacherAPI].self, from: cachedData)
                let tasks = processScheduleTeacherData(scheduleItems: scheduleItems)
                completion(tasks)
                return
            } catch {
                print("Ошибка декодирования кэша преподавателя: \(error)")
            }
        }
        
        guard let url = URL(string: "https://api.mindenit.org/schedule/teachers/\(teacherId)") else {
            print("Неверный URL")
            apiConnection = false
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Ошибка загрузки: \(error)")
                apiConnection = false
                return
            }
            
            guard let data = data else {
                print("Нет данных")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let scheduleItems = try decoder.decode([TeacherAPI].self, from: data)
                
                // Сохраняем в кэш
                CacheManager.save(data: data, filename: "schedule_teacher_\(teacherId).json")
                UserDefaults.standard.set(Date(), forKey: "cache_date_teacher_\(teacherId)")
                
                let tasks = processScheduleTeacherData(scheduleItems: scheduleItems)
                completion(tasks)
            } catch {
                print("Ошибка декодирования: \(error)")
            }
        }
        task.resume()
    }
}
