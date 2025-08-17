import SwiftUI

struct SemesterSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var firstSemesterEndMonth = 1
    @State private var firstSemesterEndDay = 31
    @State private var secondSemesterStartMonth = 2
    @State private var secondSemesterStartDay = 1
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private let months = [
        (1, "Січень"),
        (2, "Лютий")
    ]
    
    private func daysInMonth(_ month: Int) -> [Int] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        let date = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        let range = calendar.range(of: .day, in: .month, for: date)!
        return Array(range)
    }
    
    var body: some View {
        NavigationView {
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
                
                VStack(spacing: 20) {
                    Text("Налаштування семестрів")
                        .font(.custom("Inter", size: 24).weight(.bold))
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    VStack(spacing: 25) {
                        // Конец первого семестра
                        DateSelectionSection(
                            title: "Кінець першого семестру",
                            selectedMonth: $firstSemesterEndMonth,
                            selectedDay: $firstSemesterEndDay,
                            months: months,
                            daysInMonth: daysInMonth
                        )
                        
                        // Начало второго семестра
                        DateSelectionSection(
                            title: "Початок другого семестру",
                            selectedMonth: $secondSemesterStartMonth,
                            selectedDay: $secondSemesterStartDay,
                            months: months,
                            daysInMonth: daysInMonth
                        )
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.1))
                    )
                    .padding(.horizontal)
                    
                    Text("Примітка: Перший семестр починається 1 вересня, другий семестр закінчується 30 червня")
                        .font(.custom("Inter", size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Button(action: saveChanges) {
                            Text("Зберегти")
                                .font(.custom("Inter", size: 16).weight(.semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                        
                        Button(action: resetToDefaults) {
                            Text("Скинути налаштування")
                                .font(.custom("Inter", size: 16).weight(.medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .alert("Помилка", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .navigationBarItems(trailing: Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            })
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadCurrentSettings()
            }
        }
    }
    
    private func loadCurrentSettings() {
        let firstEnd = Calendar.current.dateComponents([.month, .day], from: SemesterDates.shared.firstSemesterRange.end)
        let secondStart = Calendar.current.dateComponents([.month, .day], from: SemesterDates.shared.secondSemesterRange.start)
        
        firstSemesterEndMonth = firstEnd.month ?? 1
        firstSemesterEndDay = firstEnd.day ?? 31
        secondSemesterStartMonth = secondStart.month ?? 2
        secondSemesterStartDay = secondStart.day ?? 1
    }
    
    private func saveChanges() {
        // Проверка валидности дат
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        guard let firstEnd = calendar.date(from: DateComponents(year: currentYear, month: firstSemesterEndMonth, day: firstSemesterEndDay)),
              let secondStart = calendar.date(from: DateComponents(year: currentYear, month: secondSemesterStartMonth, day: secondSemesterStartDay)),
              firstEnd < secondStart else {
            showAlert = true
            alertMessage = "Кінець першого семестру має бути раніше за початок другого"
            return
        }
        
        // Сохранение настроек
        SemesterDates.shared.setFirstSemesterEnd(day: firstSemesterEndDay, month: firstSemesterEndMonth)
        SemesterDates.shared.setSecondSemesterStart(day: secondSemesterStartDay, month: secondSemesterStartMonth)
        
        dismiss()
    }
    
    private func resetToDefaults() {
        SemesterDates.shared.resetToDefaults()
        loadCurrentSettings()
    }
}

struct DateSelectionSection: View {
    let title: String
    @Binding var selectedMonth: Int
    @Binding var selectedDay: Int
    let months: [(Int, String)]
    let daysInMonth: (Int) -> [Int]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.custom("Inter", size: 16).weight(.semibold))
                .foregroundColor(.white)
            
            HStack(spacing: 15) {
                // Выбор месяца
                Picker("Місяць", selection: $selectedMonth) {
                    ForEach(months, id: \.0) { month in
                        Text(month.1).tag(month.0)
                    }
                }
                .pickerStyle(.menu)
                .accentColor(.white)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                
                // Выбор дня
                Picker("День", selection: $selectedDay) {
                    ForEach(daysInMonth(selectedMonth), id: \.self) { day in
                        Text("\(day)").tag(day)
                    }
                }
                .pickerStyle(.menu)
                .accentColor(.white)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

#Preview {
    SemesterSettingsView()
} 