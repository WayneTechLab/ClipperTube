import AppKit
import SwiftUI

@main
struct CliperTubeApp: App {
    @StateObject private var store = StudioStore()
    @StateObject private var youtubeStore = YouTubeStore()
    @State private var updateInfo: UpdateChecker.UpdateInfo?
    @State private var showUpdateAlert = false

    var body: some Scene {
        WindowGroup("Cliper Tube") {
            StudioRootView()
                .environmentObject(store)
                .environmentObject(youtubeStore)
                .task {
                    await checkForUpdates()
                }
                .alert("Update Available", isPresented: $showUpdateAlert) {
                    Button("Download Update") {
                        if let info = updateInfo, let url = URL(string: info.releaseURL) {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    Button("Later", role: .cancel) { }
                } message: {
                    if let info = updateInfo {
                        Text("A new version of Cliper Tube is available!\n\nCurrent: v\(info.currentVersion)\nLatest: v\(info.latestVersion)\n\n\(info.releaseNotes ?? "See release notes on GitHub.")")
                    }
                }
        }
        .defaultSize(width: 1400, height: 900)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
    }
    
    private func checkForUpdates() async {
        guard let info = await UpdateChecker.checkForUpdates() else { return }
        
        if info.isUpdateAvailable {
            await MainActor.run {
                self.updateInfo = info
                self.showUpdateAlert = true
            }
        }
    }
}
