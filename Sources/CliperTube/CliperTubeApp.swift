import SwiftUI

@main
struct CliperTubeApp: App {
    @StateObject private var store = StudioStore()
    @StateObject private var youtubeStore = YouTubeStore()

    var body: some Scene {
        WindowGroup("Cliper Tube") {
            StudioRootView()
                .environmentObject(store)
                .environmentObject(youtubeStore)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
    }
}
