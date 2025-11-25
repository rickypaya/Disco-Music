
import SwiftUI

@main
struct DiscoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some SwiftUI.Scene {
        WindowGroup {
            ContentView()
        }
    }
}
