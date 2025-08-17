import Foundation

class SemesterDates {
    static let shared = SemesterDates()
    
    private var cachedCurrentSemester: Int?
    private var cachedCurrentAcademicYear: Int?
    private var cachedFirstSemesterRange: (start: Date, end: Date)?
    private var cachedSecondSemesterRange: (start: Date, end: Date)?
    
    private init() {
        print("🔄 Инициализация SemesterDates")
    } // Приватный инициализатор для синглтона
    
    // Определяем текущий семестр
    var currentSemester: Int {
        if let cached = cachedCurrentSemester {
            return cached
        }
        
        let calendar = Calendar.current
        let currentDate = Date()
        let month = calendar.component(.month, from: currentDate)
        
        let semester: Int
        // Первый семестр: сентябрь (9) - январь (1)
        if month >= 9 || month == 1 {
            semester = 0 // Первый семестр
        } else if (2...6).contains(month) {
            semester = 1 // Второй семестр
        } else {
            semester = -1 // Каникулы (июль-август)
        }
        
        print("📊 Определение текущего семестра:")
        print("  📅 Текущий месяц: \(month)")
        print("  🎓 Семестр: \(semester == 0 ? "Первый" : semester == 1 ? "Второй" : "Каникулы")")
        
        cachedCurrentSemester = semester
        return semester
    }
    
    // Получаем текущий учебный год
    var currentAcademicYear: Int {
        if let cached = cachedCurrentAcademicYear {
            return cached
        }
        
        let calendar = Calendar.current
        let currentDate = Date()
        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)
        let academicYear = month >= 9 ? year : year - 1
        
        print("📚 Определение учебного года:")
        print("  📅 Текущая дата: \(currentDate.format("dd.MM.yyyy"))")
        print("  📆 Учебный год: \(academicYear)-\(academicYear + 1)")
        
        cachedCurrentAcademicYear = academicYear
        return academicYear
    }
    
    // Первый семестр: 1 сентября - 31 января
    var firstSemesterRange: (start: Date, end: Date) {
        if let cached = cachedFirstSemesterRange {
            return cached
        }
        
        let range = calculateFirstSemesterRange()
        cachedFirstSemesterRange = range
        return range
    }
    
    // Второй семестр: 1 февраля - 30 июня
    var secondSemesterRange: (start: Date, end: Date) {
        if let cached = cachedSecondSemesterRange {
            return cached
        }
        
        let range = calculateSecondSemesterRange()
        cachedSecondSemesterRange = range
        return range
    }
    
    private func calculateFirstSemesterRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let startYear = currentAcademicYear
        let endYear = startYear + 1
        
        let start = calendar.date(from: DateComponents(
            year: startYear,
            month: 9,
            day: 1
        ))!
        
        let defaultEnd = calendar.date(from: DateComponents(
            year: endYear,
            month: 1,
            day: 31
        ))!
        
        let savedEndDay = UserDefaults.standard.integer(forKey: "firstSemesterEndDay")
        let savedEndMonth = UserDefaults.standard.integer(forKey: "firstSemesterEndMonth")
        
        print("\n📅 Расчет периода первого семестра:")
        print("  🎯 Начало: \(start.format("dd.MM.yyyy"))")
        
        if savedEndDay > 0 && savedEndMonth > 0 {
            if let customEnd = calendar.date(from: DateComponents(
                year: endYear,
                month: savedEndMonth,
                day: savedEndDay
            )) {
                print("  ⚙️ Используются пользовательские настройки:")
                print("    📌 День: \(savedEndDay)")
                print("    📌 Месяц: \(savedEndMonth)")
                print("  🎯 Конец (пользовательский): \(customEnd.format("dd.MM.yyyy"))")
                return (start, customEnd)
            }
        }
        
        print("  🎯 Конец (по умолчанию): \(defaultEnd.format("dd.MM.yyyy"))")
        return (start, defaultEnd)
    }
    
    private func calculateSecondSemesterRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let year = currentAcademicYear + 1
        
        let defaultStart = calendar.date(from: DateComponents(
            year: year,
            month: 2,
            day: 1
        ))!
        
        let end = calendar.date(from: DateComponents(
            year: year,
            month: 6,
            day: 30
        ))!
        
        let savedStartDay = UserDefaults.standard.integer(forKey: "secondSemesterStartDay")
        let savedStartMonth = UserDefaults.standard.integer(forKey: "secondSemesterStartMonth")
        
        print("\n📅 Расчет периода второго семестра:")
        print("  🎯 Конец: \(end.format("dd.MM.yyyy"))")
        
        if savedStartDay > 0 && savedStartMonth > 0 {
            if let customStart = calendar.date(from: DateComponents(
                year: year,
                month: savedStartMonth,
                day: savedStartDay
            )) {
                print("  ⚙️ Используются пользовательские настройки:")
                print("    📌 День: \(savedStartDay)")
                print("    📌 Месяц: \(savedStartMonth)")
                print("  🎯 Начало (пользовательский): \(customStart.format("dd.MM.yyyy"))")
                return (customStart, end)
            }
        }
        
        print("  🎯 Начало (по умолчанию): \(defaultStart.format("dd.MM.yyyy"))")
        return (defaultStart, end)
    }
    
    func setFirstSemesterEnd(day: Int, month: Int) {
        print("\n⚙️ Установка даты окончания первого семестра:")
        print("  📌 День: \(day)")
        print("  📌 Месяц: \(month)")
        
        UserDefaults.standard.set(day, forKey: "firstSemesterEndDay")
        UserDefaults.standard.set(month, forKey: "firstSemesterEndMonth")
        UserDefaults.standard.synchronize()
        
        // Сбрасываем кэш при изменении настроек
        cachedFirstSemesterRange = nil
        
        print("✅ Настройки сохранены")
    }
    
    func setSecondSemesterStart(day: Int, month: Int) {
        print("\n⚙️ Установка даты начала второго семестра:")
        print("  📌 День: \(day)")
        print("  📌 Месяц: \(month)")
        
        UserDefaults.standard.set(day, forKey: "secondSemesterStartDay")
        UserDefaults.standard.set(month, forKey: "secondSemesterStartMonth")
        UserDefaults.standard.synchronize()
        
        // Сбрасываем кэш при изменении настроек
        cachedSecondSemesterRange = nil
        
        print("✅ Настройки сохранены")
    }
    
    func getSemesterDates() -> [(start: Date, end: Date)] {
        let dates = [firstSemesterRange, secondSemesterRange]
        
        print("\n📊 Получение дат семестров:")
        print("  1️⃣ Первый семестр: \(dates[0].start.format("dd.MM.yyyy")) - \(dates[0].end.format("dd.MM.yyyy"))")
        print("  2️⃣ Второй семестр: \(dates[1].start.format("dd.MM.yyyy")) - \(dates[1].end.format("dd.MM.yyyy"))")
        
        return dates
    }
    
    func isDateInFirstSemester(_ date: Date) -> Bool {
        let range = firstSemesterRange
        let result = date >= range.start && date <= range.end
        
        print("\n🔍 Проверка даты \(date.format("dd.MM.yyyy")) на первый семестр:")
        print("  📅 Период семестра: \(range.start.format("dd.MM.yyyy")) - \(range.end.format("dd.MM.yyyy"))")
        print("  ✅ Результат: \(result ? "Входит" : "Не входит")")
        
        return result
    }
    
    func isDateInSecondSemester(_ date: Date) -> Bool {
        let range = secondSemesterRange
        let result = date >= range.start && date <= range.end
        
        print("\n🔍 Проверка даты \(date.format("dd.MM.yyyy")) на второй семестр:")
        print("  📅 Период семестра: \(range.start.format("dd.MM.yyyy")) - \(range.end.format("dd.MM.yyyy"))")
        print("  ✅ Результат: \(result ? "Входит" : "Не входит")")
        
        return result
    }
    
    // Добавляем метод для сброса дат к значениям по умолчанию
    func resetToDefaults() {
        print("\n🔄 Сброс настроек семестров к значениям по умолчанию")
        
        UserDefaults.standard.removeObject(forKey: "firstSemesterEndDay")
        UserDefaults.standard.removeObject(forKey: "firstSemesterEndMonth")
        UserDefaults.standard.removeObject(forKey: "secondSemesterStartDay")
        UserDefaults.standard.removeObject(forKey: "secondSemesterStartMonth")
        UserDefaults.standard.synchronize()
        
        // Сбрасываем весь кэш при сбросе настроек
        cachedCurrentSemester = nil
        cachedCurrentAcademicYear = nil
        cachedFirstSemesterRange = nil
        cachedSecondSemesterRange = nil
        
        print("✅ Настройки сброшены")
    }
} 