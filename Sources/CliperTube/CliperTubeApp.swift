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
        .defaultSize(width: 1400, height: 900)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
    }
}
