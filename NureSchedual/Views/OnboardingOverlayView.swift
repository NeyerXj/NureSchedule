import SwiftUI

struct OnboardingOverlayView: View {
    @Binding var isShowingOnboarding: Bool
    var onComplete: () -> Void
    @State private var currentStep = 0
    @State private var animationAmount = 1.0
    @State private var isAnimating = false
    @Namespace private var animation
    
    private struct OnboardingStep: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let icon: String
        let gradient: [Color]
        let secondaryIcon: String
    }
    
    private let steps = [
        OnboardingStep(
            title: "Ласкаво просимо!",
            description: "Ваш розумний помічник для навчання в ХНУРЕ",
            icon: "sparkles",
            gradient: [Color(hex: "#4158D0"), Color(hex: "#C850C0")],
            secondaryIcon: "graduationcap.fill"
        ),
        OnboardingStep(
            title: "Режим студента/викладача",
            description: "Один додаток - подвійна функціональність.\nЗручно для всіх",
            icon: "person.2.circle.fill",
            gradient: [Color(hex: "#0093E9"), Color(hex: "#80D0C7")],
            secondaryIcon: "building.columns.fill"
        ),
        OnboardingStep(
            title: "Розумні сповіщення",
            description: "Отримуйте сповіщення про пари та миттєво дізнавайтеся про зміни в розкладі",
            icon: "bell.badge.fill",
            gradient: [Color(hex: "#8EC5FC"), Color(hex: "#E0C3FC")],
            secondaryIcon: "clock.fill"
        ),
        OnboardingStep(
            title: "Зручна навігація",
            description: "Свайпайте для переходу між днями та тижнями.\nВаш розклад на кінчиках пальців",
            icon: "hand.draw.fill",
            gradient: [Color(hex: "#4E65FF"), Color(hex: "#92EFFD")],
            secondaryIcon: "calendar"
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Затемненный фон
                Color.black
                    .opacity(0.85)
                    .ignoresSafeArea()
                
                // Анимированный градиентный фон
                LinearGradient(gradient: Gradient(colors: steps[currentStep].gradient),
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing)
                    .opacity(0.15)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.7), value: currentStep)
                
                // Фоновые элементы дизайна
                ZStack {
                    ForEach(0..<15) { index in
                        Circle()
                            .fill(steps[currentStep].gradient[index % 2])
                            .opacity(0.05)
                            .frame(width: CGFloat.random(in: 20...100))
                            .position(
                                x: CGFloat.random(in: 0...geometry.size.width),
                                y: CGFloat.random(in: 0...geometry.size.height)
                            )
                            .blur(radius: 3)
                            .animation(
                                Animation.easeInOut(duration: Double.random(in: 2...4))
                                    .repeatForever(autoreverses: true)
                                    .delay(Double.random(in: 0...2)),
                                value: animationAmount
                            )
                    }
                }
                .onAppear {
                    animationAmount = 1.2
                    withAnimation(.spring().repeatForever()) {
                        isAnimating = true
                    }
                }
                
                // Основной контент
                VStack(spacing: 35) {
                    Spacer()
                    
                    // Иконки с анимацией
                    ZStack {
                        // Второстепенная иконка
                        Image(systemName: steps[currentStep].secondaryIcon)
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.3))
                            .offset(x: -60, y: isAnimating ? -20 : 0)
                            .rotationEffect(.degrees(isAnimating ? 10 : 0))
                        
                        // Основная иконка
                        Image(systemName: steps[currentStep].icon)
                            .font(.system(size: 85))
                            .foregroundColor(.white)
                            .matchedGeometryEffect(id: "icon\(currentStep)", in: animation)
                            .shadow(color: steps[currentStep].gradient[0].opacity(0.7), radius: 15)
                            .frame(height: 100)
                            .scaleEffect(isAnimating ? 1.05 : 1)
                            
                        // Дополнительная второстепенная иконка
                        Image(systemName: steps[currentStep].secondaryIcon)
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.3))
                            .offset(x: 60, y: isAnimating ? 20 : 0)
                            .rotationEffect(.degrees(isAnimating ? -10 : 0))
                    }
                    .padding(.bottom, 20)
                    
                    // Заголовок с эффектом свечения
                    Text(steps[currentStep].title)
                        .font(.title.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .matchedGeometryEffect(id: "title\(currentStep)", in: animation)
                        .padding(.top)
                        .shadow(color: steps[currentStep].gradient[0], radius: 10)
                    
                    // Описание с градиентным текстом
                    Text(steps[currentStep].description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .matchedGeometryEffect(id: "description\(currentStep)", in: animation)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    Spacer()
                    
                    // Улучшенные индикаторы
                    HStack(spacing: 12) {
                        ForEach(0..<steps.count, id: \.self) { index in
                            Capsule()
                                .fill(currentStep == index ? .white : .white.opacity(0.3))
                                .frame(width: currentStep == index ? 20 : 10, height: 10)
                                .scaleEffect(currentStep == index ? 1.2 : 1)
                                .animation(.spring(), value: currentStep)
                        }
                    }
                    
                    // Кнопки навигации с улучшенным дизайном
                    HStack(spacing: 20) {
                        Button {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                isShowingOnboarding = false
                                UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                                onComplete()
                            }
                        } label: {
                            Text("Пропустити")
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial)
                                .cornerRadius(20)
                                .padding(.horizontal, 10)
                        }
                        
                        Button {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                if currentStep < steps.count - 1 {
                                    currentStep += 1
                                } else {
                                    isShowingOnboarding = false
                                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                                    onComplete()
                                }
                            }
                        } label: {
                            Text(currentStep == steps.count - 1 ? "Почати" : "Далі")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 130)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: steps[currentStep].gradient,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                                .shadow(color: steps[currentStep].gradient[0].opacity(0.5), radius: 10, x: 0, y: 5)
                        }
                    }
                    .padding(.bottom, 50)
                }
                .padding()
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.7), value: isAnimating)
    }
}

// Расширение для работы с HEX цветами
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 