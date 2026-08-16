import SwiftUI

@main
struct PinFanApp: App {
    init() {
        // Bootstrap database (copies from bundle and runs migrations)
        _ = DatabaseManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

