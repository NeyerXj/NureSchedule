import SwiftUI

struct DetailView: View {
    @Environment(\.presentationMode) var presentationMode
    let task: Task
    @AppStorage("isTeacherMode") private var isTeacherMode: Bool = false
    var namespace: Namespace.ID

    // Основний темний фон
    private let darkGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.15, green: 0.19, blue: 0.30),
            Color(red: 0.10, green: 0.14, blue: 0.24)
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Легкий контраст для секцій
    private let sectionBackground = Color(red: 0.15, green: 0.19, blue: 0.30)
    
    var body: some View {
        NavigationStack{
            ZStack {
                
                List {
                    // ---------- Назва предмета ----------
                    
                    Section {
                        
                        VStack(spacing: 5){
                            
                            Text("Деталі:")
                                .font(.custom("Inter", size: 24).weight(.semibold)).frame(maxWidth: .infinity, alignment: .center)
                            
                            
                            Divider()
                                .background(Color.white.opacity(0.3))
                        }.background(Color.clear)
                        HStack {
                            Spacer()
                            Text(task.fullTitle)
                                .font(.custom("Inter", size: 24))
                                .fontWeight(.semibold)
                                .foregroundColor(.white).matchedGeometryEffect(id: task.id, in: namespace)
                            Spacer()
                        }.listRowBackground(Color.clear) // Убираем фон ячейки
                            .listRowSeparator(.hidden)
                    }
                    .listRowBackground(Color.clear).listRowInsets(.init())

                    // ---------- Секція «Тип» та «Аудиторія» ----------
                    Section {
                        HStack {
                            Text("Тип")
                                .font(.custom("Inter", size: 18))
                                .foregroundColor(.white.opacity(0.85))
                            Spacer()
                            let typeDescription: String = {
                                switch task.type {
                                case "Лб":
                                    return "Лабораторна робота"
                                case "Зал":
                                    return "Залік"
                                case "Конс":
                                    return "Консультація"
                                case "Екз":
                                    return "Екзамен"
                                case "Лк":
                                    return "Лекція"
                                case "Пз":
                                    return "Практичне заняття"
                                default:
                                    return task.type
                                }
                            }()
                            Text(typeDescription)
                                .font(.custom("Inter", size: 18))
                                .foregroundColor(.white.opacity(0.85))
                        }

                        HStack {
                            Text("Аудиторія")
                                .font(.custom("Inter", size: 18))
                                .foregroundColor(.white.opacity(0.85))
                            Spacer()
                            Text(task.auditory)
                                .font(.custom("Inter", size: 18))
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                    .listRowBackground(sectionBackground)

                    // ---------- Секція «ВИКЛАДАЧ» ----------
                    if (task.type != "Перерва"){
                        Section(header: Text(isTeacherMode ? "Групи" : "ВИКЛАДАЧ")
                            .font(.custom("Inter", size: 14))
                            .foregroundColor(.white.opacity(0.9)) // Більш світлий колір заголовка
                        ) {
                            if isTeacherMode {
                                VStack(alignment: .leading, spacing: 5) {
                                    ForEach(task.teacher.split(separator: ","), id: \.self) { group in
                                        GroupView(group: group.trimmingCharacters(in: .whitespaces))
                                    }
                                }
                                .padding(.vertical, 5)
                            } else {
                                Text(task.teacher)
                                    .font(.custom("Inter", size: 18))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                        }
                        .listRowBackground(sectionBackground)
                    }

                    // ---------- Секція «ІНФОРМАЦІЯ» ----------
                    Section(header: Text("ІНФОРМАЦІЯ")
                        .font(.custom("Inter", size: 14))
                        .foregroundColor(.white.opacity(0.9)) // Более светлый цвет заголовка
                    ) {
                        Text("Очікуйте оновлення – незабаром будуть додані нові функції!")
                            .font(.custom("Inter", size: 12))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .listRowBackground(sectionBackground)
                    
                    
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden) // Прибираємо системний фон
                .background(Color.clear) // Для работы с градиентом
                .disabled(true) // Отключаем скроллинг
                .frame(height: UIScreen.main.bounds.height - 100) // Ограничиваем высоту списка
                
                // Налаштування навігації
                VStack{
                    Spacer()
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Закрити")
                            .font(.custom("Inter", size: 18).weight(.semibold))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }.padding()
                }
                
            }.background(darkGradient.edgesIgnoringSafeArea(.all)) // Градиентный фон
                .preferredColorScheme(.dark)
        }.navigationBarBackButtonHidden(true)
        }
    }

struct GroupView: View {
    let group: String
    
    var body: some View {
        Text(group)
            .font(.custom("Inter", size: 18))
            .foregroundColor(.white.opacity(0.85))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(8)
    }
}

struct DetailView_Previews: PreviewProvider {
    @Namespace static var namespace

    static var previews: some View {
        DetailView(
            task: Task(title: "IM", fullTitle: "IMZ", caption: "1", date: Date(), tint: .blue, auditory: "DL_!", type: "Екзамен", teacher: "Володька"),
            namespace: namespace
        )
    }
}
