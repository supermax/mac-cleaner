import SwiftUI

@main
struct DevSpaceApp: App {
    var body: some Scene {
        WindowGroup("DevSpace") {
            ContentView()
                .frame(minWidth: 860, minHeight: 610)
        }
        .windowResizability(.contentMinSize)
    }
}
