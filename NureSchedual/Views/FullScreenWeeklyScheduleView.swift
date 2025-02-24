import SwiftUI

struct FullScreenWeeklyScheduleView: View {
    var tasks: [Task]
    @Binding var selectedGroup: String
    @Binding var isShowingPopover: Bool
    @Binding var isTeacherMode: Bool
    @Binding var selectedTeacher: String

    @Environment(\.dismiss) private var dismiss

    @State private var displayedDays: [Date] = []
    @State private var scrollViewProxy: ScrollViewProxy?
    @State private var isLoadingMoreDays: Bool = false
    @State private var isContentLoaded: Bool = false

    @Namespace private var animationDetail
    
    // Жёсткие границы диапазона
    private var minDate: Date
    private var maxDate: Date
    private let today: Date

    init(tasks: [Task],
         selectedGroup: Binding<String>,
         isShowingPopover: Binding<Bool>,
         isTeacherMode: Binding<Bool>,
         selectedTeacher: Binding<String>) {
        self.tasks = tasks
        self._selectedGroup = selectedGroup
        self._isShowingPopover = isShowingPopover
        self._isTeacherMode = isTeacherMode
        self._selectedTeacher = selectedTeacher

        let calendar = Calendar.current
        // Сегодняшний день, нормализованный (начало дня)
        self.today = calendar.startOfDay(for: Date())
        let currentYear = calendar.component(.year, from: Date())
        let currentMonth = calendar.component(.month, from: Date())

        // Получаем 1-е число текущего месяца (с 00:00)
        let startDate = calendar.date(from: DateComponents(timeZone: TimeZone(secondsFromGMT: 0), year: currentYear,
                                                           month: currentMonth,
                                                           day: 1,
                                                           hour: 0,
                                                           minute: 0,
                                                           second: 0))!

        // Устанавливаем границы в зависимости от месяца
        if (1...6).contains(currentMonth) {
            // Если сегодня январь – июнь: берем с сентября прошлого года по июнь текущего
            self.minDate = calendar.date(from: DateComponents(timeZone: TimeZone(secondsFromGMT: 0), year: currentYear - 1,
                                                              month: 9,
                                                              day: 1,
                                                              hour: 0,
                                                              minute: 0,
                                                              second: 0))!
            self.maxDate = calendar.date(from: DateComponents(timeZone: TimeZone(secondsFromGMT: 0), year: currentYear,
                                                              month: 6,
                                                              day: 30,
                                                              hour: 23,
                                                              minute: 59,
                                                              second: 59))!
        } else {
            // Если сегодня сентябрь – декабрь: берем с сентября текущего года по июнь следующего
            self.minDate = calendar.date(from: DateComponents(timeZone: TimeZone(secondsFromGMT: 0), year: currentYear,
                                                              month: 9,
                                                              day: 1,
                                                              hour: 0,
                                                              minute: 0,
                                                              second: 0))!
            self.maxDate = calendar.date(from: DateComponents(timeZone: TimeZone(secondsFromGMT: 0), year: currentYear + 1,
                                                              month: 6,
                                                              day: 30,
                                                              hour: 23,
                                                              minute: 59,
                                                              second: 59))!
        }

        // Отладочные выводы
//        print("Сегодня: \(self.today)")
//        print("Граница начала: \(self.minDate)")
//        print("Граница конца: \(self.maxDate)")
//        print("startDate (1-е число месяца): \(startDate)")

        // Загружаем только текущий месяц
        self._displayedDays = State(initialValue: Self.generateDisplayedDays(for: startDate))

//        print("Загруженные дни: \(self._displayedDays.wrappedValue.map { $0.formatted(date: .abbreviated, time: .omitted) })")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView
                    .padding()

                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .top, spacing: 8) {
                            ForEach(displayedDays, id: \.self) { day in
                                dayColumn(for: day)
                                    .onAppear {
                                        // Динамическая подгрузка выполняется только после начальной загрузки
                                        if isContentLoaded {
                                            if day == displayedDays.first {
                                                prependDays()
                                            }
                                            if day == displayedDays.last {
                                                appendDays()
                                            }
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)
                        .onAppear {
                            self.scrollViewProxy = proxy
                            // После появления прокручиваем к текущему дню
                            DispatchQueue.main.async {
                                scrollToToday()
                                isContentLoaded = true
                            }
                        }
                    }
                }
                .opacity(isContentLoaded ? 1 : 0)
                .padding(.top)

                Spacer()
            }
            .background(Color(red: 0.10, green: 0.14, blue: 0.24))
            .navigationBarBackButtonHidden(true)
        }
    }

    // MARK: - Генерация дней для одного месяца
    private static func generateDisplayedDays(for date: Date) -> [Date] {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let range = calendar.range(of: .day, in: .month, for: monthStart)!

        return range.map { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset - 1, to: monthStart)!
        }
    }

    // MARK: - Подгрузка предыдущего месяца
    private func prependDays() {
        guard !isLoadingMoreDays, let first = displayedDays.first, first > minDate else { return }
        isLoadingMoreDays = true
        let calendar = Calendar.current
        guard let newMonthDate = calendar.date(byAdding: .month, value: -1, to: first) else {
            isLoadingMoreDays = false
            return
        }
        // Генерируем дни для предыдущего месяца
        let newDays = Self.generateDisplayedDays(for: newMonthDate)
        print("Подгружаем предыдущий месяц: \(newDays.first?.formatted(date: .abbreviated, time: .omitted) ?? "") - \(newDays.last?.formatted(date: .abbreviated, time: .omitted) ?? "")")
        DispatchQueue.main.async {
            displayedDays.insert(contentsOf: newDays, at: 0)
            isLoadingMoreDays = false
        }
    }

    // MARK: - Подгрузка следующего месяца
    private func appendDays() {
        guard !isLoadingMoreDays, let last = displayedDays.last, last < maxDate else { return }
        isLoadingMoreDays = true
        let calendar = Calendar.current
        guard let newMonthDate = calendar.date(byAdding: .month, value: 1, to: last) else {
            isLoadingMoreDays = false
            return
        }
        // Генерируем дни для следующего месяца
        let newDays = Self.generateDisplayedDays(for: newMonthDate)
        print("Подгружаем следующий месяц: \(newDays.first?.formatted(date: .abbreviated, time: .omitted) ?? "") - \(newDays.last?.formatted(date: .abbreviated, time: .omitted) ?? "")")
        DispatchQueue.main.async {
            displayedDays.append(contentsOf: newDays)
            isLoadingMoreDays = false
        }
    }

    // MARK: - Автоскролл к текущему дню
    private func scrollToToday() {
        if let index = displayedDays.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: today) }) {
            withAnimation(.easeInOut) {
                scrollViewProxy?.scrollTo(displayedDays[index], anchor: .center)
            }
            print("Скроллим к дню: \(displayedDays[index].formatted(date: .abbreviated, time: .omitted))")
        } else {
            print("Сегодняшняя дата не найдена в displayedDays!")
        }
    }

    // MARK: - Отображение дня
    private func dayColumn(for day: Date) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(day.formatted(date: .abbreviated, time: .omitted))
                .font(.headline)
                .foregroundColor(Calendar.current.isDate(day, inSameDayAs: today) ? .yellow : .white)
                .padding(.bottom, 4)

            let dayTasks = tasks.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
            if dayTasks.isEmpty {
                Text("Немає пар")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                VStack(spacing: 4) {
                    ScrollView {
                        ForEach(dayTasks) { task in
                            NavigationLink(destination: DetailView(task: task, namespace: animationDetail)
                                .navigationTransition(.zoom(sourceID: "detail", in: animationDetail))) {
                                    TaskItemTable(task: task)
                                }
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            Spacer()
        }
        .frame(width: 130)
        .padding()
        .background(Color.blue.opacity(0.2))
        .cornerRadius(10)
        .id(day)
    }

    // MARK: - Заголовок
    private var headerView: some View {
        HStack {
            Text(isTeacherMode ? selectedTeacher : selectedGroup)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white.opacity(0.94))
                .minimumScaleFactor(0.5)

            Spacer()

            Button(action: { scrollToToday() }) {
                Image(systemName: "house.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.black)
                    .padding()
                    .background(Color(red: 0.46, green: 0.61, blue: 0.95))
                    .clipShape(Circle())
            }

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.black)
                    .padding()
                    .background(Color(red: 0.46, green: 0.61, blue: 0.95))
                    .clipShape(Circle())
            }.padding(.leading, 8)
        }
        .padding(.horizontal, 10)
        .padding(.top, 16)
    }
}

struct FullScreenWeeklyScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        let today = Date()
        let calendar = Calendar.current
        let dummyTasks: [Task] = (-3...3).map { offset in
            let taskDate = calendar.date(byAdding: .day, value: offset, to: today)!
            return Task(
                title: "Заняття \(offset)",
                fullTitle: "Повна назва \(offset)",
                caption: "Опис пари \(offset)",
                date: taskDate,
                tint: .blue,
                auditory: "Ауд 101",
                type: "Лекція",
                teacher: "Викладач \(offset)"
            )
        }
        return FullScreenWeeklyScheduleView(
            tasks: dummyTasks,
            selectedGroup: .constant("KIYKI-24-2"),
            isShowingPopover: .constant(false),
            isTeacherMode: .constant(false),
            selectedTeacher: .constant("Antonio")
        )
        .previewInterfaceOrientation(.portrait)
    }
}
