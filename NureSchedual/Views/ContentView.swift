import SwiftUI
import AVFoundation
import Network

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

// MARK: - ContentView
struct ContentView: View {
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
    @AppStorage("isProgessBar") private var isProgessBar: Bool = true
    @AppStorage("isGestrue") private var isGestrue: Bool = false
    
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
                            ).multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .foregroundColor(.white.opacity(0.94))
                        if !networkMonitor.isConnected{
                            Image(systemName: "wifi.slash").resizable().frame(width: 20, height: 20).foregroundStyle(.red)
                        }
                        if !apiConnection{
                            Image("noapi").resizable().frame(width: 22, height: 22).foregroundStyle(.red).scaledToFill().offset(y: 2)
                        }
                        
//                        GIFView(gifName: "animation", isPlaying: $play)
//                            .frame(width: 40, height: 40)
//                            .scaledToFit()
//                            .opacity(isPlaying ? 1 : 0)
//                            .animation(.easeInOut(duration: 0.3), value: isPlaying)
                        
                        
                        Spacer()
                        NavigationLink {
                            FullScreenWeeklyScheduleView(tasks: tasks, selectedGroup: $selectedGroup, isShowingPopover: $isShowingPopover, isTeacherMode: $isTeacherMode, selectedTeacher: $selectedTeacher)
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
                        .padding(.leading, 8)
                        .accessibilityLabel("Розклад")
                        
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
                        .padding(.leading, -2)
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
                    LoadingView(isLoading:$isLoading)
                } else {
                    ScrollView(.vertical) {
                        VStack {
                            TaskView() // Список «пар»
                        }
                        .hSpacing(.center)
                        .vSpacing(.center)
                    }.offset(y: -20)
                    .scrollIndicators(.hidden)
                }
            }.gesture(
                DragGesture()
                    .onEnded { value in
                        let calendar = Calendar.current

                        if value.translation.width > 50 && isGestrue {
                            // Свайп влево (следующий день)
                            if let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                                DispatchQueue.main.async {
                                    withAnimation {
                                        currentDate = nextDay
                                    }
                                }
                            }
                        } else if value.translation.width < -50 && isGestrue {
                            // Свайп вправо (предыдущий день)
                            if let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) {
                                DispatchQueue.main.async {
                                    withAnimation {
                                        currentDate = previousDay
                                    }
                                }
                            }
                        }
                    }
            )
            .vSpacing(.top)
            .frame(maxWidth: .infinity)
            .background(Color(red:0.10,green:0.14,blue:0.24))
            .preferredColorScheme(.dark)
            .onAppear {
                isTeacherMode = UserDefaults.standard.bool(forKey: "isTeacherMode")
                
                NotificationCenter.default.addObserver(forName: .isTeacherModeChanged, object: nil, queue: .main) { _ in
                    self.handleTeacherModeChange()
                }
                if !isOnceLoaded {
                    if isTeacherMode {
                        loadSavedTeachers()
                        fetchTeachers()
                    } else {
                        loadSavedGroup()
                        fetchGroups()
                    }
                    isOnceLoaded = true
                }
                
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
            }
            .onDisappear {
                NotificationCenter.default.removeObserver(self, name: .isTeacherModeChanged, object: nil)
            }.navigationBarBackButtonHidden(true)
        }
    }
    
    private func handleTeacherModeChange() {
        isTeacherMode = UserDefaults.standard.bool(forKey: "isTeacherMode")
        print("isTeacherMode \(isTeacherMode)")
        if isTeacherMode {
            loadSavedTeachers()
            fetchTeachers()
        } else {
            loadSavedGroup()
            fetchGroups()
        }
    }
    
    // MARK: - Функция для выбора группы
    func selectGroup(group: Group) {
        selectedGroup = group.name
        selectedGroupId = group.id
        saveGroup(group: group)
        
        if let groupId = selectedGroupId {
            fetchSchedule(forGroupId: groupId) { fetchedTasks in
                DispatchQueue.main.async {
                    self.tasks = fetchedTasks
                }
            }
        }
    }
    
    func selectTeacher(teacher: Teacher) {
        selectedTeacher = teacher.name
        selectedTeacherId = teacher.id
        saveTeacher(teacher: teacher)
        if let teacherId = selectedTeacherId {
            fetchTeacherSchedual(forTeacherId: teacherId) { fetchedTasks in
                DispatchQueue.main.async {
                    self.tasks = fetchedTasks
                }
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
                                        Rectangle()
                                            .frame(width: 1, height: 70)
                                            .foregroundColor(.black)
                                        Rectangle()
                                            .frame(width: 1, height: progressHeight(for: tasks[index]))
                                            .foregroundColor(.green)
                                    }
                                    .offset(x: 24, y: 45)
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
    
    // MARK: - Расчёт высоты прогресса между задачами
    func progressHeight(for task: Task) -> CGFloat {
        guard let nextTask = nextTask(after: task) else {
            return 45
        }
        
        let totalInterval = nextTask.date.timeIntervalSince(task.date)
        let elapsedInterval = Date().timeIntervalSince(task.date)
        let progress = max(0, min(1, elapsedInterval / totalInterval))
        return CGFloat(progress * 70)
    }
    
    func nextTask(after currentTask: Task) -> Task? {
        let nextTask = tasks
            .filter { $0.date > currentTask.date }
            .sorted(by: { $0.date < $1.date })
            .first
        return nextTask
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
                    withAnimation(.snappy) {
                        currentDate = day.date
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
}

// MARK: - Превью (для Canvas)
#Preview {
    ContentView()
}
