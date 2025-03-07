import SwiftUI

struct FeatureTourView: View {
    @Binding var isShowingTour: Bool
    @State private var currentStep = 0
    @State private var isAnimating = false
    @Namespace private var animation
    
    private struct TourStep: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let icon: String
        let gradient: [Color]
        let arrowDirection: ArrowDirection
        let getHighlightFrame: (GeometryProxy) -> CGRect
        let getArrowPosition: (GeometryProxy) -> CGPoint
    }
    
    enum ArrowDirection {
        case up, down, left, right, none
    }
    
    // Добавьте константы для позиционирования
    private struct TourPositions {
        // Базовый отступ сверху для всех элементов
        static let baseTopOffset: CGFloat = -10 // Уменьшите это значение, чтобы поднять все элементы выше
        
        // Отступы для каждого шага
        struct GroupSelector {
            static let topOffset: CGFloat = baseTopOffset + 5
            static let height: CGFloat = 40
            static let horizontalPadding: CGFloat = 16
        }
        
        struct WeekNavigation {
            static let topOffset: CGFloat = baseTopOffset + 80
            static let height: CGFloat = 100
        }
        
        struct LessonDetails {
            static let topOffset: CGFloat = baseTopOffset + 190
            static let height: CGFloat = 80
            static let horizontalPadding: CGFloat = 16
        }
        
        struct Settings {
            static let topOffset: CGFloat = baseTopOffset + 5
            static let size: CGFloat = 44
            static let rightPadding: CGFloat = 16
        }
    }
    
    // Добавьте после структуры TourPositions
    private struct TourCoordinates {
        // Добавим функции для расчета позиций с учетом размера экрана
        static func adaptivePosition(basePosition: CGFloat, screenHeight: CGFloat) -> CGFloat {
            // Базовая высота iPhone 14 Pro
            let baseHeight: CGFloat = 852
            return basePosition * (screenHeight / baseHeight)
        }
        
        struct Highlight {
            static func groupSelector(for geometry: GeometryProxy) -> ElementPosition {
                let adaptiveY = adaptivePosition(basePosition: 70, screenHeight: geometry.size.height)
                return ElementPosition(
                    x: 10,
                    y: adaptiveY,
                    width: 0.65,
                    height: adaptiveY * 0.85 // Адаптивная высота
                )
            }
            
            static func weekNavigation(for geometry: GeometryProxy) -> ElementPosition {
                let adaptiveY = adaptivePosition(basePosition: 130, screenHeight: geometry.size.height)
                return ElementPosition(
                    x: 0,
                    y: adaptiveY,
                    width: 1.0,
                    height: 100 * (geometry.size.height / 852) // Адаптивная высота
                )
            }
            
            static func lessonDetails(for geometry: GeometryProxy) -> ElementPosition {
                let adaptiveY = adaptivePosition(basePosition: 240, screenHeight: geometry.size.height)
                return ElementPosition(
                    x: 0,
                    y: adaptiveY,
                    width: 1.0,
                    height: 80 * (geometry.size.height / 852)
                )
            }
            
            static func settings(for geometry: GeometryProxy) -> ElementPosition {
                let adaptiveY = adaptivePosition(basePosition: 75, screenHeight: geometry.size.height)
                return ElementPosition(
                    x: -40,
                    y: adaptiveY,
                    width: 50 * (geometry.size.width / 393), // Адаптивная ширина
                    height: 50 * (geometry.size.width / 393), // Адаптивная высота
                    rightPadding: 14 * (geometry.size.width / 393)
                )
            }
        }
        
        struct Arrow {
            static func groupSelector(for geometry: GeometryProxy) -> ElementPosition {
                let adaptiveY = adaptivePosition(basePosition: 145, screenHeight: geometry.size.height)
                return ElementPosition(
                    x: 0.605,
                    y: adaptiveY,
                    width: 30,
                    height: 30
                )
            }
            
            static func weekNavigation(for geometry: GeometryProxy) -> ElementPosition {
                let adaptiveY = adaptivePosition(basePosition: 270, screenHeight: geometry.size.height)
                return ElementPosition(
                    x: 0.5,
                    y: adaptiveY,
                    width: 40,
                    height: 30
                )
            }
            
            static func lessonDetails(for geometry: GeometryProxy) -> ElementPosition {
                let adaptiveY = adaptivePosition(basePosition: 360, screenHeight: geometry.size.height)
                return ElementPosition(
                    x: 0.5,
                    y: adaptiveY,
                    width: 30,
                    height: 30
                )
            }
            
            static func settings(for geometry: GeometryProxy) -> ElementPosition {
                let adaptiveY = adaptivePosition(basePosition: 160, screenHeight: geometry.size.height)
                return ElementPosition(
                    x: -60,
                    y: adaptiveY,
                    width: 30,
                    height: 30,
                    rightPadding: 10
                )
            }
        }
    }
    
    // Структура для хранения позиции элемента
    struct ElementPosition {
        var x: CGFloat
        var y: CGFloat
        var width: CGFloat
        var height: CGFloat
        var rightPadding: CGFloat = 16
    }
    
    private let steps = [
        TourStep(
            title: "Вибір групи/викладача",
            description: "Натисніть тут, щоб обрати вашу групу або викладача",
            icon: "person.2.circle.fill",
            gradient: [Color(hex: "#FF3CAC"), Color(hex: "#784BA0")],
            arrowDirection: .up,
            getHighlightFrame: { geometry in
                let coords = TourCoordinates.Highlight.groupSelector(for: geometry)
                return CGRect(
                    origin: CGPoint(
                        x: coords.x,
                        y: geometry.safeAreaInsets.top + coords.y
                    ),
                    size: CGSize(
                        width: geometry.size.width * coords.width,
                        height: coords.height
                    )
                )
            },
            getArrowPosition: { geometry in
                let coords = TourCoordinates.Arrow.groupSelector(for: geometry)
                return CGPoint(
                    x: geometry.size.width * coords.x,
                    y: geometry.safeAreaInsets.top + coords.y
                )
            }
        ),
        TourStep(
            title: "Навігація по днях",
            description: "Свайпайте вліво або вправо для переходу між днями",
            icon: "hand.draw.fill",
            gradient: [Color(hex: "#8EC5FC"), Color(hex: "#E0C3FC")],
            arrowDirection: .up,
            getHighlightFrame: { geometry in
                let coords = TourCoordinates.Highlight.weekNavigation(for: geometry)
                return CGRect(
                    origin: CGPoint(x: coords.x, y: coords.y),
                    size: CGSize(width: geometry.size.width, height: coords.height)
                )
            },
            getArrowPosition: { geometry in
                let coords = TourCoordinates.Arrow.weekNavigation(for: geometry)
                return CGPoint(
                    x: geometry.size.width * coords.x,
                    y: geometry.safeAreaInsets.top + coords.y
                )
            }
        ),
        TourStep(
            title: "Деталі пари",
            description: "Натисніть на пару для перегляду детальної інформації",
            icon: "info.circle.fill",
            gradient: [Color(hex: "#FA8BFF"), Color(hex: "#2BD2FF")],
            arrowDirection: .up,
            getHighlightFrame: { geometry in
                let coords = TourCoordinates.Highlight.lessonDetails(for: geometry)
                return CGRect(
                    origin: CGPoint(x: coords.x, y: coords.y),
                    size: CGSize(width: geometry.size.width - coords.width, height: coords.height)
                )
            },
            getArrowPosition: { geometry in
                let coords = TourCoordinates.Arrow.lessonDetails(for: geometry)
                return CGPoint(
                    x: geometry.size.width / 2,
                    y: geometry.safeAreaInsets.top + coords.y
                )
            }
        ),
        TourStep(
            title: "Налаштування",
            description: "Тут ви можете налаштувати сповіщення та інші параметри",
            icon: "gearshape.fill",
            gradient: [Color(hex: "#4158D0"), Color(hex: "#C850C0")],
            arrowDirection: .up,
            getHighlightFrame: { geometry in
                let coords = TourCoordinates.Highlight.settings(for: geometry)
                return CGRect(
                    origin: CGPoint(x: geometry.size.width - coords.width - coords.rightPadding, y: coords.y),
                    size: CGSize(width: coords.width, height: coords.width)
                )
            },
            getArrowPosition: { geometry in
                let coords = TourCoordinates.Arrow.settings(for: geometry)
                return CGPoint(
                    x: geometry.size.width - coords.width - coords.rightPadding,
                    y: geometry.safeAreaInsets.top + coords.y
                )
            }
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Затемненный фон на весь экран
                Color.black
                    .opacity(0.75)
                    .edgesIgnoringSafeArea(.all) // Изменено с .ignoresSafeArea()
                
                // Прозрачное окно для выделенного элемента
                let frame = steps[currentStep].getHighlightFrame(geometry)
                Path { path in
                    path.addRect(geometry.frame(in: .global)) // Изменено с .local
                    path.addRoundedRect(in: frame, cornerSize: .init(width: 10, height: 10))
                }
                .fill(style: FillStyle(eoFill: true))
                .foregroundColor(.black.opacity(0.75))
                
                // Анимированная стрелка
                if steps[currentStep].arrowDirection != .none {
                    Arrow(direction: steps[currentStep].arrowDirection)
                        .stroke(
                            LinearGradient(
                                colors: steps[currentStep].gradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                        )
                        .frame(width: 30, height: 30)
                        .position(steps[currentStep].getArrowPosition(geometry))
                        .offset(y: isAnimating ? -5 : 5)
                }
                
                // Информационная карточка
                VStack(spacing: 20) {
                    Spacer()
                    
                    VStack(spacing: 15) {
                        Image(systemName: steps[currentStep].icon)
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .shadow(color: steps[currentStep].gradient[0], radius: 10)
                            .scaleEffect(isAnimating ? 1.1 : 1)
                        
                        Text(steps[currentStep].title)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text(steps[currentStep].description)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .shadow(color: steps[currentStep].gradient[0].opacity(0.5), radius: 15)
                    )
                    .padding()
                    
                    // Индикаторы и кнопки
                    HStack(spacing: 12) {
                        ForEach(0..<steps.count, id: \.self) { index in
                            Circle()
                                .fill(currentStep == index ? .white : .white.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentStep == index ? 1.2 : 1)
                                .animation(.spring(), value: currentStep)
                        }
                    }
                    
                    HStack(spacing: 20) {
                        Button {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                isShowingTour = false
                                UserDefaults.standard.set(true, forKey: "hasSeenFeatureTour")
                            }
                        } label: {
                            Text("Пропустити")
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Button {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                if currentStep < steps.count - 1 {
                                    currentStep += 1
                                } else {
                                    isShowingTour = false
                                    UserDefaults.standard.set(true, forKey: "hasSeenFeatureTour")
                                }
                            }
                        } label: {
                            Text(currentStep == steps.count - 1 ? "Завершити" : "Далі")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 120)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: steps[currentStep].gradient,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever()) {
                isAnimating = true
            }
        }
    }
}

// Компонент для отрисовки стрелки
struct Arrow: Shape {
    let direction: FeatureTourView.ArrowDirection
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        switch direction {
        case .up:
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.height * 0.3))
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.3))
        case .down:
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.height * 0.7))
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.7))
        case .left:
            path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.width * 0.3, y: rect.minY))
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.width * 0.3, y: rect.maxY))
        case .right:
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.width * 0.7, y: rect.minY))
            path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.width * 0.7, y: rect.maxY))
        case .none:
            break
        }
        
        return path
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var isShowingTour = true
        
        var body: some View {
            ZStack {
                // Используем реальный ContentView как фон
                ContentView()
                    .environment(\.colorScheme, .dark) // Устанавливаем темную тему
                
                // Накладываем тур поверх
                if isShowingTour {
                    FeatureTourView(isShowingTour: $isShowingTour)
                }
            }
        }
    }
    
    return PreviewWrapper()
        .preferredColorScheme(.dark) // Устанавливаем темную тему для всего превью
}


