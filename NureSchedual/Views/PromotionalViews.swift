import SwiftUI

// Структура для рекламы новой функции статистики
struct StatisticsPromotionView: View {
    @Binding var isPresented: Bool
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Затемнений фон
            Color.black.opacity(0.75)
                .edgesIgnoringSafeArea(.all)
            
            // Основний контент
            VStack(spacing: 25) {
                // Іконка з анімацією
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .opacity(isAnimating ? 0.8 : 0.4)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                    
                    Image(systemName: "chart.bar.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.white)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                }
                
                Text("Нова функція!")
                    .font(.custom("Inter", size: 28).weight(.bold))
                    .foregroundColor(.white)
                
                VStack(spacing: 15) {
                    Text("Статистика предметів")
                        .font(.custom("Inter", size: 24).weight(.semibold))
                        .foregroundColor(.white)
                    
                    Text("Тепер ви можете відстежувати свій прогрес по кожному предмету! Аналізуйте відвідуваність, слідкуйте за розкладом лабораторних та практичних робіт.")
                        .font(.custom("Inter", size: 16))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal)
                }
                
                Text("Увімкніть цю функцію в налаштуваннях додатку")
                    .font(.custom("Inter", size: 14))
                    .foregroundColor(.white.opacity(0.7))
                
                Button(action: {
                    withAnimation(.spring()) {
                        isPresented = false
                    }
                }) {
                    Text("Зрозуміло")
                        .font(.custom("Inter", size: 16).weight(.semibold))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.2))
                    .shadow(color: .blue.opacity(0.3), radius: 20)
            )
            .padding(.horizontal, 20)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// Структура для рекламы Telegram канала
struct TelegramPromotionView: View {
    @Binding var isPresented: Bool
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Затемнений фон
            Color.black.opacity(0.75)
                .edgesIgnoringSafeArea(.all)
            
            // Основний контент
            VStack(spacing: 25) {
                // Анімована іконка Telegram
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color(hex: "#34AADF")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .opacity(isAnimating ? 0.8 : 0.4)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                    
                    Image(systemName: "paperplane.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isAnimating ? 10 : -10))
                }
                
                VStack(spacing: 15) {
                    Text("Приєднуйтесь до нас!")
                        .font(.custom("Inter", size: 24).weight(.bold))
                        .foregroundColor(.white)
                    
                    Text("Хочете дізнаватися про оновлення першими?")
                        .font(.custom("Inter", size: 18).weight(.semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    Text("Підписуйтесь на наш Telegram канал, де ми розповідаємо про розробку цього та інших додатків.")
                        .font(.custom("Inter", size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text("Ми ще не співпрацюємо з університетом офіційно, але дуже хотіли б! Поки що підтримайте нас своєю підпискою 😊")
                        .font(.custom("Inter", size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                HStack(spacing: 15) {
                    Button(action: {
                        if let url = URL(string: "https://t.me/xjdevelop") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("Підписатися")
                            .font(.custom("Inter", size: 16).weight(.semibold))
                            .foregroundColor(.white)
                            .frame(width: 140, height: 50)
                            .background(Color.blue)
                            .cornerRadius(25)
                    }
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            isPresented = false
                        }
                    }) {
                        Text("Пізніше")
                            .font(.custom("Inter", size: 16).weight(.semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 140, height: 50)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(25)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.2))
                    .shadow(color: .blue.opacity(0.3), radius: 20)
            )
            .padding(.horizontal, 20)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// Менеджер для управления показом рекламы
class PromotionalManager: ObservableObject {
    static let shared = PromotionalManager()
    
    @Published var shouldShowStatisticsPromo = false
    @Published var shouldShowTelegramPromo = false
    
    @AppStorage("appOpenCount") private var appOpenCount = 0
    @AppStorage("hasSeenStatisticsPromo") private var hasSeenStatisticsPromo = false
    @AppStorage("lastVersionPromoted") private var lastVersionPromoted = ""
    
    private let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    
    private init() {}
    
    func checkAndShowPromos() {
        appOpenCount += 1
        
        // Показываем промо статистики только один раз для новой версии
        if !hasSeenStatisticsPromo || lastVersionPromoted != currentVersion {
            shouldShowStatisticsPromo = true
            hasSeenStatisticsPromo = true
            lastVersionPromoted = currentVersion
        }
        
        // Показываем промо Telegram каждые 5 открытий
        if appOpenCount % 5 == 0 {
            shouldShowTelegramPromo = true
        }
    }
} 