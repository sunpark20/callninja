import SwiftUI

@main
struct CallNinjaApp: App {
    static let accentPink = Color(red: 0.894, green: 0.271, blue: 0.369)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(Self.accentPink)
        }
    }
}
