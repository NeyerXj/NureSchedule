import SwiftUI

struct CustomDateSelector: View {
    @AppStorage("progressEndDate") private var progressEndDate: Double = Date().timeIntervalSince1970

    @State private var selectedMonth: Int = 5 // По умолчанию Май
    @State private var selectedDay: Int = 1
    @State private var showMonthPicker = false
    @State private var showDayPicker = false

    private let months = ["Травень", "Червень"]
    
    /// Дни в зависимости от месяца (30 дней в июне, 31 в мае)
    private var days: [Int] {
        return selectedMonth == 5 ? Array(1...31) : Array(1...30)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Виберіть кінцеву дату прогресу")
                .font(.custom("Inter", size: 17).weight(.semibold))
                .foregroundColor(.white)

            HStack(spacing: 10) {
                // Кнопка выбора месяца
                Button(action: {
                    withAnimation { showMonthPicker.toggle()
                        if showMonthPicker { showDayPicker = false }
                    }
                }) {
                    Text(months.indices.contains(selectedMonth - 5) ? months[selectedMonth - 5] : "Невідомий")
                        .font(.custom("Inter", size: 16))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.8))
                        .cornerRadius(10)
                }
                
                // Кнопка выбора дня
                Button(action: {
                    withAnimation { showDayPicker.toggle()
                        if showDayPicker { showMonthPicker = false }
                    }
                }) {
                    Text("\(selectedDay)")
                        .font(.custom("Inter", size: 16))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple.opacity(0.8))
                        .cornerRadius(10)
                }
            }
            .frame(height: 50)
            
            if showMonthPicker {
                Picker("Оберіть місяць", selection: $selectedMonth) {
                    ForEach(5...6, id: \.self) { month in
                        Text(months[month - 5]).tag(month)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 100)
                .background(Color.black.opacity(0.8))
                .cornerRadius(10)
                .transition(.opacity)
            }
            
            if showDayPicker {
                Picker("Оберіть день", selection: $selectedDay) {
                    ForEach(days, id: \.self) { day in
                        Text("\(day)").tag(day)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 100)
                .background(Color.black.opacity(0.8))
                .cornerRadius(10)
                .transition(.opacity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.2))
        )
        .onAppear {
            loadDate()
        }
        .onChange(of: selectedMonth) { _ in saveDate() }
        .onChange(of: selectedDay) { _ in saveDate() }.preferredColorScheme(.dark)
    }

    /// Загружает дату из `AppStorage`
    private func loadDate() {
        let savedDate = Date(timeIntervalSince1970: progressEndDate)
        let calendar = Calendar.current
        selectedMonth = calendar.component(.month, from: savedDate)
        selectedDay = calendar.component(.day, from: savedDate)
    }

    /// Сохраняет выбранную дату в `AppStorage`
    private func saveDate() {
        let calendar = Calendar.current
        if let newDate = calendar.date(from: DateComponents(year: calendar.component(.year, from: Date()), month: selectedMonth, day: selectedDay)) {
            progressEndDate = newDate.timeIntervalSince1970
        }
    }
}

struct SettingsSwiftUIView: View {
    @Environment(\.presentationMode) var presentationMode

    // Используем @AppStorage для сохранения настроек
    @Namespace private var animation
    @AppStorage("progressEndDate") private var progressEndDate: Double = Date().timeIntervalSince1970
    @AppStorage("isTeacherMode") private var isTeacherMode: Bool = false
    @AppStorage("isInfinityPlaing") private var isInfinityPlaing: Bool = false
    @AppStorage("areNotificationsEnabled") private var areNotificationsEnabled: Bool = true
    @AppStorage("isProgessBar") private var isProgessBar: Bool = false
    @AppStorage("isGestrue") private var isGestrue: Bool = true
    @AppStorage("isShowSubjectStatistics") private var isShowSubjectStatistics: Bool = false
    @State private var showClearCahceView: Bool = false
    @State private var showSemesterSettings = false
    @StateObject private var networkMonitor = NetworkMonitor()
    @AppStorage("isScheduleChangesNotificationsEnabled") private var isScheduleChangesNotificationsEnabled: Bool = true
    @AppStorage("isLessonStartNotificationsEnabled") private var isLessonStartNotificationsEnabled: Bool = true
    @AppStorage("isNotificationsEnabled") private var isNotificationsEnabled: Bool = true
    @State private var showAboutView: Bool = false
    private var selectedDate: Binding<Date> {
            Binding(
                get: { Date(timeIntervalSince1970: progressEndDate) },
                set: { newDate in
                    progressEndDate = validateDate(newDate).timeIntervalSince1970
                }
            )
        }
    private func validateDate(_ date: Date) -> Date {
         let calendar = Calendar.current
         let components = calendar.dateComponents([.year, .month, .day], from: date)
         let year = components.year ?? calendar.component(.year, from: Date())
         let day = components.day ?? 1

         var month = components.month ?? 5
         if month < 5 { month = 5 }  // Если раньше мая, ставим май
         if month > 6 { month = 6 }  // Если позже июня, ставим июнь

         return calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? date
     }
    var body: some View {
        NavigationStack {
            ZStack{
                VStack {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Налаштування")
                            .font(.custom("Inter", size: 36).weight(.bold))
                            .foregroundColor(.white)
                        
                        // Раздел "Режим викладача" и прочие настройки
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle(isOn: $isTeacherMode) {
                                Text("Режим викладача")
                                    .font(.custom("Inter", size: 17).weight(.semibold))
                                    .foregroundColor(.white).strikethrough(networkMonitor.isConnected ? false : true, color: .white)
                            }.disabled(networkMonitor.isConnected ? false : true)
                            .toggleStyle(CustomToggleStyle())

                            Divider()
                                .background(Color.white.opacity(0.3))
                            Toggle(isOn: $isProgessBar) {
                                Text("Прогресу курсу ")
                                    .font(.custom("Inter", size: 17).weight(.semibold))
                                    .foregroundColor(.white).lineLimit(1).minimumScaleFactor(1)
                            }
                            .toggleStyle(CustomToggleStyle())

                            Divider()
                                .background(Color.white.opacity(0.3))
                            if isProgessBar {
                                CustomDateSelector()
                                    .matchedGeometryEffect(id: "dateSelector", in: animation)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity),
                                        removal: .move(edge: .bottom).combined(with: .opacity)
                                    ))
                                    .animation(.easeInOut(duration: 0.5), value: isProgessBar)

                                Divider()
                                    .background(Color.white.opacity(0.3))
                            }
                            
                            Toggle(isOn: $isGestrue) {
                                Text("Зміна днів свайпом")
                                    .font(.custom("Inter", size: 16).weight(.semibold))
                                    .foregroundColor(.white)
                            }
                            .toggleStyle(CustomToggleStyle())
                            
                            Divider()
                                .background(Color.white.opacity(0.3))
                            
                            Button(action: {
                                showSemesterSettings = true
                            }) {
                                HStack {
                                    Text("Налаштування семестрів")
                                        .font(.custom("Inter", size: 16).weight(.semibold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            .sheet(isPresented: $showSemesterSettings) {
                                SemesterSettingsView()
                            }
                            
                            Toggle(isOn: $isShowSubjectStatistics) {
                                Text("Статистика предметів")
                                    .font(.custom("Inter", size: 16).weight(.semibold))
                                    .foregroundColor(.white)
                            }
                            .toggleStyle(CustomToggleStyle())
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black.opacity(0.2))
                        )
                        .padding()
                        
                        // Секция уведомлений
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Сповіщення")
                                .font(.custom("Inter", size: 20).weight(.bold))
                                .foregroundColor(.white)
                                .padding(.top).offset(y:-10)
                            
                    
                            
                            Toggle(isOn: $isLessonStartNotificationsEnabled) {
                                VStack(alignment: .leading) {
                                    Text("Початок пари")
                                        .font(.custom("Inter", size: 17).weight(.semibold))
                                        .foregroundColor(.white)
                                    Text("Нагадування за 10 хвилин до початку пари")
                                        .font(.custom("Inter", size: 14))
                                        .foregroundColor(.gray)
                                }
                            }
                            .toggleStyle(CustomToggleStyle())
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black.opacity(0.2))
                        )
                        .padding()
                                                
                    }
                    
                    Spacer()
                    
                    // Кнопка "Закрити"
                    VStack(spacing: 10) {
                        
                        // 🔹 Кнопка связи с поддержкой
                        Button(action: {
                            if let url = URL(string: "https://t.me/NURE_Schedule_support_Bot") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "message.fill")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Зв'язатися з підтримкою")
                                    .font(.custom("Inter", size: 16).weight(.medium))
                            }
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.green.opacity(0.8), Color.green.opacity(0.6)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.green.opacity(0.3), radius: 4, x: 0, y: 2)
                            .foregroundColor(.white)
                        }

                        // 🗑 Кнопка очистки кеша
                        Button(action: {
                            withAnimation {
                                showClearCahceView = true
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Очистити кеш")
                                    .font(.custom("Inter", size: 16).weight(.medium))
                            }
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.red.opacity(0.8), Color.red.opacity(0.6)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.red.opacity(0.3), radius: 4, x: 0, y: 2)
                            .foregroundColor(.white)
                        }
                        Button(action: {
                            withAnimation {
                                showAboutView = true
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Про додаток")
                                    .font(.custom("Inter", size: 16).weight(.medium))
                            }
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.6)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                            .foregroundColor(.white)
                        }
                        // ❌ Кнопка закрытия
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Закрити")
                                    .font(.custom("Inter", size: 16).weight(.medium))
                            }
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                            .foregroundColor(.white)
                        }

                        

                    }
                    .padding(.horizontal, 20)
                
                }
                if showClearCahceView{
                                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                                        .onTapGesture {
                                            withAnimation {
                                                showClearCahceView = false
                                            }
                                        }.transition(.opacity)
                                    CacheSettingsView().frame(width: 300, height: 380)
                        .background(Color.white).ignoresSafeArea()
                                        .cornerRadius(15)
                                        .shadow(radius: 10)
                                        .transition(.scale)
                                }
                // В ZStack добавляем модальное окно с информацией о приложении
                if showAboutView {
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                showAboutView = false
                            }
                        }.transition(.opacity)
                    
                    VStack(spacing: 16) {
                        Text("Про додаток")
                            .font(.custom("Inter", size: 24).weight(.bold))
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("NureSchedule v1.1")
                                .font(.custom("Inter", size: 18).weight(.semibold))
                                .foregroundColor(.white)
                            
                            Text("Розроблено Костянтином Волковим")
                                .font(.custom("Inter", size: 16))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Divider()
                                .background(Color.white.opacity(0.3))
                                .padding(.vertical, 8)
                            
                            Text("Це неофіційний додаток для перегляду розкладу ХНУРЕ. Додаток використовує відкриті API університету для отримання даних розкладу.")
                                .font(.custom("Inter", size: 16))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("© 2025 Всі права захищені")
                                .font(.custom("Inter", size: 14))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.top, 8)
                        }
                        .padding(.horizontal, 20)
                        
                        Button(action: {
                            withAnimation {
                                showAboutView = false
                            }
                        }) {
                            Text("Закрити")
                                .font(.custom("Inter", size: 16).weight(.medium))
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .frame(width: 320)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(red: 0.15, green: 0.20, blue: 0.35))
                    )
                    .shadow(color: Color.black.opacity(0.5), radius: 15)
                    .transition(.scale)
                }
            }
            
            .navigationBarBackButtonHidden(true)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.10, green: 0.14, blue: 0.24),
                        Color(red: 0.05, green: 0.07, blue: 0.15)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: isTeacherMode) { newValue in
                NotificationCenter.default.post(name: .isTeacherModeChanged, object: nil)
                print("Value set \(isTeacherMode)")
            }
            
        }
        
    }
    
    // Кастомный стиль для Toggle
    struct CustomToggleStyle: ToggleStyle {
        func makeBody(configuration: Configuration) -> some View {
            HStack {
                configuration.label
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(configuration.isOn ? Color.green : Color.gray.opacity(0.5))
                        .frame(width: 50, height: 30)
                        .shadow(color: configuration.isOn ? Color.green.opacity(0.6) : Color.gray.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                }
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            }
            .padding(.horizontal)
        }
    }
}

struct SettingsSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsSwiftUIView()
            
    }
}
struct CacheSettingsView: View {
    @State private var cacheSize: String = "0 KB"
    @State private var userDefaultsSize: String = "0 KB"
    @State private var isClearing: Bool = false
    @State private var showSuccess: Bool = false
    @State private var progress: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            // Градієнтний фон
            LinearGradient(
                colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.1)],
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea().frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 16) {
                Text("Кеш додатку")
                    .font(Font.custom("Inter", size: 22).weight(.heavy))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                

                Text("Розмір кешу: \(cacheSize)")
                    .font(Font.custom("Inter", size: 16).weight(.bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("Розмір доп кешу: \(userDefaultsSize)")
                    .font(Font.custom("Inter", size: 16).weight(.bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                // Анімоване коло завантаження
                ZStack {
                    Circle()
                        .stroke(lineWidth: 10)
                        .opacity(0.2)
                        .foregroundColor(.gray)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(AngularGradient(gradient: Gradient(colors: [.red, .orange, .yellow]), center: .center),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 3), value: progress)
                    
                    if isClearing {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .transition(.opacity)
                    } else if showSuccess {
                        Text("✅")
                            .font(.system(size: 30))
                            .foregroundColor(.green)
                            .transition(.opacity)
                    }
                }
                .frame(width: 100, height: 100)
                .padding()
                VStack{
                    Text("Після очищення кешу")
                        .font(Font.custom("Inter", size: 16).weight(.medium))
                        .foregroundColor(.red)
                        .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("потрібно буде перезавантажити додаток")
                        .font(Font.custom("Inter", size: 16).weight(.medium))
                        .foregroundColor(.red)
                        .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                // Кнопка очищення
                Button(action: {
                    startCacheClearing()
                }) {
                    ZStack {
                        if isClearing {
                            Text("Очищення...")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.6))
                                .cornerRadius(12)
                        } else if showSuccess {
                            Text("Кеш очищено!")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green.opacity(0.8))
                                .cornerRadius(12)
                                .animation(.easeOut, value: showSuccess)
                        } else {
                            Text("Очистити все")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(12)
                                .shadow(radius: 5)
                                .animation(.easeOut, value: isClearing)
                        }
                    }
                }
                .padding(.horizontal, 40)
                .disabled(isClearing)
            }
            .padding()
        }
        .onAppear {
            cacheSize = getCacheSize()
            userDefaultsSize = getUserDefaultsSize()
        }
        .preferredColorScheme(.dark)
    }

    /// Функція для старту очищення з анімацією кола прогресу
    func startCacheClearing() {
        isClearing = true
        showSuccess = false
        progress = 0.0
        
        // Анімація кола з таймером (3 секунди)
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if progress < 1.0 {
                progress += 0.05
            } else {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    clearCache()
                    clearUserDefaults()
                    cacheSize = getCacheSize()
                    userDefaultsSize = getUserDefaultsSize()
                    isClearing = false
                    showSuccess = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showSuccess = false
                    }
                }
            }
        }
    }

    /// Функція для обчислення розміру кешу
    func getCacheSize() -> String {
        let cacheSize = directorySize(url: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!)
        let tmpSize = directorySize(url: URL(fileURLWithPath: NSTemporaryDirectory()))
        return formatSize(bytes: cacheSize + tmpSize)
    }

    /// Функція для обчислення розміру UserDefaults
    func getUserDefaultsSize() -> String {
        var totalSize: Int64 = 0
        for (_, value) in UserDefaults.standard.dictionaryRepresentation() {
            if let data = value as? Data {
                totalSize += Int64(data.count)
            } else if let string = value as? String {
                totalSize += Int64(string.utf8.count)
            }
        }
        return formatSize(bytes: totalSize)
    }

    /// Обчислення розміру папки
    func directorySize(url: URL) -> Int64 {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        return files.reduce(0) { size, file in
            (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { size + Int64($0 ?? 0) } ?? size
        }
    }

    /// Форматує розмір у зручний для читання вигляд
    func formatSize(bytes: Int64) -> String {
        let currentLanguage = "uk" // оскільки потрібен український текст
        
        // Визначаємо одиниці вимірювання для української мови
        let localizedUnits: [String: (String, String, String)] = [
            "uk": ("КБ", "МБ", "ГБ")
        ]
        
        // Беремо одиниці для поточної мови або використовуємо значення за замовчуванням
        let units = localizedUnits[currentLanguage] ?? ("КБ", "МБ", "ГБ")
        
        let kb: Double = 1024
        let mb: Double = kb * 1024
        let gb: Double = mb * 1024
        
        let doubleBytes = Double(bytes)
        
        if doubleBytes >= gb {
            return String(format: "%.2f \(units.2)", doubleBytes / gb)
        } else if doubleBytes >= mb {
            return String(format: "%.2f \(units.1)", doubleBytes / mb)
        } else {
            return String(format: "%.2f \(units.0)", doubleBytes / kb)
        }
    }

    /// Очищення UserDefaults
    func clearUserDefaults() {
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys {
            defaults.removeObject(forKey: key)
        }
        defaults.synchronize()
        print("🗑 UserDefaults очищено!")
    }

    /// Очищення файлового кешу
    func clearCache() {
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory())

        do {
            try FileManager.default.removeItem(at: cacheURL)
            try FileManager.default.removeItem(at: tmpURL)
            print("🗑 Кеш успішно очищено!")
        } catch {
            print("❌ Помилка очищення кешу: \(error.localizedDescription)")
        }
    }
}


extension Notification.Name {
    static let isTeacherModeChanged = Notification.Name("isTeacherModeChanged")
}
