# 🚀 Миграция на новый API sh.mindenit.org

## 📋 Обзор изменений

Проект NureSchedule успешно мигрирован с API `https://api.mindenit.org` на новый API `https://sh.mindenit.org/api/`.

## 🔄 Основные изменения

### 1. **Новые модели данных**

#### Старые модели (удалены):
```swift
// Старая структура ScheduleItem
struct ScheduleItem {
    let startTime: TimeInterval
    let endTime: TimeInterval
    let auditory: String
    // ...
}
```

#### Новые модели:
```swift
// Новая структура ScheduleItem
struct ScheduleItem {
    let startedAt: TimeInterval
    let endedAt: TimeInterval
    let auditorium: Auditorium
    // ...
}

// Новая структура Teacher
struct Teacher {
    let fullName: String
    let shortName: String
    let departmentId: Int?
}

// Новая структура Group
struct Group {
    let directionId: Int?
    let specialityId: Int?
}
```

### 2. **Централизованный API сервис**

Создан новый файл `APIService.swift` с централизованной логикой работы с API:

```swift
class APIService: ObservableObject {
    static let shared = APIService()
    
    // Группы
    func fetchGroups() async throws -> [Group]
    func fetchGroupSchedule(groupId: Int) async throws -> [ScheduleItem]
    
    // Преподаватели
    func fetchTeachers() async throws -> [Teacher]
    func fetchTeacherSchedule(teacherId: Int) async throws -> [ScheduleItem]
    
    // Аудитории
    func fetchAuditoriums() async throws -> [Auditorium]
    func fetchAuditoriumSchedule(auditoriumId: Int) async throws -> [ScheduleItem]
}
```

### 3. **Улучшенное кэширование**

Новый `APICacheManager` с поддержкой:
- Кэширования в памяти
- Кэширования на диске
- Автоматического истечения кэша
- Комбинированного кэширования

### 4. **Обработка ошибок**

Новый `APIError` enum с детальными типами ошибок:
```swift
enum APIError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case decodingError(Error)
    case networkError(Error)
}
```

## 📁 Измененные файлы

### Основные файлы:
- ✅ `NureSchedual/AdditionalEx/Task.swift` - обновлены модели данных
- ✅ `NureSchedual/Services/APIService.swift` - новый централизованный API сервис
- ✅ `NureSchedual/Views/ContentView.swift` - обновлена логика работы с API
- ✅ `NureSchedual/Services/NotificationManager.swift` - обновлен для нового API
- ✅ `NureSchedual/Services/ScheduleChecker.swift` - обновлен для нового API
- ✅ `NureSchedual/Views/NureSchedualApp.swift` - обновлен для нового API

## 🔧 Новые возможности API

### 1. **Аудитории**
```bash
# Получить все аудитории
GET https://sh.mindenit.org/api/auditoriums

# Получить расписание аудитории
GET https://sh.mindenit.org/api/auditoriums/{id}/schedule
```

### 2. **Группы**
```bash
# Получить все группы
GET https://sh.mindenit.org/api/groups

# Получить расписание группы
GET https://sh.mindenit.org/api/groups/{id}/schedule
```

### 3. **Преподаватели**
```bash
# Получить всех преподавателей
GET https://sh.mindenit.org/api/teachers

# Получить расписание преподавателя
GET https://sh.mindenit.org/api/teachers/{id}/schedule
```

## 🚀 Преимущества нового API

1. **Единообразная структура ответов**:
   ```json
   {
     "success": true,
     "data": [...],
     "message": "string",
     "error": null
   }
   ```

2. **Более детальная информация**:
   - Аудитории с этажами и наличием электричества
   - Группы с направлениями и специальностями
   - Преподаватели с кафедрами

3. **Лучшая производительность**:
   - Async/await вместо completion handlers
   - Улучшенное кэширование
   - Централизованная обработка ошибок

## 🧪 Тестирование

### Проверка работы API:
```bash
# Тест групп
curl https://sh.mindenit.org/api/groups

# Тест преподавателей
curl https://sh.mindenit.org/api/teachers

# Тест расписания группы
curl https://sh.mindenit.org/api/groups/1/schedule
```

## ⚠️ Важные замечания

1. **Совместимость**: Старые модели оставлены для обратной совместимости
2. **Кэш**: Старый кэш будет автоматически очищен при первом запуске
3. **Уведомления**: Система уведомлений полностью совместима с новым API

## 🔮 Планы на будущее

1. **Удаление устаревшего кода**: После полного тестирования удалить старые модели
2. **Добавление новых функций**: Использование новых возможностей API
3. **Оптимизация**: Дальнейшее улучшение производительности

## 📞 Поддержка

При возникновении проблем:
1. Проверьте логи в консоли
2. Убедитесь в доступности API
3. Проверьте настройки сети

---

**Дата миграции**: Январь 2025  
**Версия API**: sh.mindenit.org  
**Статус**: ✅ Завершено

