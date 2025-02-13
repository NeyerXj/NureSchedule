import SwiftUI

struct Main: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView()
                .tabItem {
                    VStack {
                        Image(systemName: "house.fill")
                            
                        Text("Home")
                    }
                }
                .tag(0)

//            SettingsSwiftUIView()
//                .tabItem {
//                    VStack {
//                        Image(systemName: "gearshape.fill")
//                            .offset(y: 8)
//                        Text("Settings")
//                    }
//                }
//                .tag(1)
        }
    }
}

struct Main_Previews: PreviewProvider {
    static var previews: some View {
        Main()
    }
}

extension UIImage {
    static func from(gradient: CAGradientLayer) -> UIImage? {
        UIGraphicsBeginImageContext(gradient.bounds.size)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        gradient.render(in: context)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
