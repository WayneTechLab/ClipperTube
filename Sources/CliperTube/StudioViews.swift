import AppKit
import AVKit
import SwiftUI
import UniformTypeIdentifiers

struct StudioRootView: View {
    @EnvironmentObject private var store: StudioStore

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            detail
        }
        .frame(minWidth: 1220, minHeight: 760)
        .overlay(alignment: .bottomLeading) {
            Text(store.statusMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
        }
        .alert("Cliper Tube", isPresented: errorPresented) {
            Button("OK") {
                store.clearError()
            }
        } message: {
            Text(store.lastError ?? "Unknown error")
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cliper Tube")
                .font(.title2.weight(.bold))
                .padding(.bottom, 6)

            Text("Wayne Tech Lab LLC")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.bottom, 12)

            ForEach(StudioSection.allCases) { section in
                Button {
                    store.selectedSection = section
                } label: {
                    HStack {
                        Image(systemName: icon(for: section))
                            .frame(width: 18)
                        Text(section.title)
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                    }
                    .padding(10)
                    .background(store.selectedSection == section ? Color.accentColor.opacity(0.16) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(width: 260)
    }

    @ViewBuilder
    private var detail: some View {
        switch store.selectedSection {
        case .dashboard:
            DashboardView()
        case .projects:
            ProjectsView()
        case .youtube:
            YouTubeHubView()
        case .captions:
            CaptionsView()
        case .timeline:
            TimelineView()
        case .voiceOver:
            VoiceOverView()
        case .proEditor:
            ProEditorView()
        case .transactions:
            TransactionsView()
        case .benchmarks:
            BenchmarksView()
        }
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { store.lastError != nil },
            set: { presented in
                if !presented {
                    store.clearError()
                }
            }
        )
    }

    private func icon(for section: StudioSection) -> String {
        switch section {
        case .dashboard: return "rectangle.3.group.bubble.left"
        case .projects: return "shippingbox"
        case .youtube: return "play.tv"
        case .captions: return "captions.bubble"
        case .timeline: return "timeline.selection"
        case .voiceOver: return "waveform"
        case .proEditor: return "slider.horizontal.3"
        case .transactions: return "creditcard"
        case .benchmarks: return "chart.bar.doc.horizontal"
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject private var store: StudioStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Creator Command Center")
                    .font(.title.weight(.bold))

                HStack(alignment: .center, spacing: 12) {
                    TextField("Paste YouTube URL/video ID or direct video URL", text: $store.youtubeInput)
                        .textFieldStyle(.roundedBorder)

                    Button("Create Project") {
                        store.createProjectFromYouTubeLink()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Auto Clip + Stitch") {
                        store.runAutoClipAndStitch()
                    }
                    .buttonStyle(.bordered)
                }

                HStack(spacing: 12) {
                    MetricCard(title: "Clips", value: "\(store.metrics.clipCount)", subtitle: "ready to edit")
                    MetricCard(
                        title: "Avg Clip Score",
                        value: String(format: "%.0f%%", store.metrics.averageConfidence * 100),
                        subtitle: "viral confidence"
                    )
                    MetricCard(title: "Captions", value: "\(store.metrics.captionCount)", subtitle: "generated")
                    MetricCard(
                        title: "Transaction Total",
                        value: String(format: "$%.2f", store.metrics.transactionTotal),
                        subtitle: "USD ledger"
                    )
                }

                if let project = store.activeProject {
                    HStack {
                        Text("Active Project: \(project.title)")
                            .font(.headline)
                        Text(project.status.label)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor(project.status).opacity(0.16))
                            .clipShape(Capsule())

                        Spacer()

                        Button("Open Projects + Outputs") {
                            store.selectedSection = .projects
                        }
                        .buttonStyle(.bordered)
                    }

                    GroupBox("Suggested Clips") {
                        VStack(spacing: 8) {
                            ForEach(project.clips.prefix(6)) { clip in
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(clip.title)
                                            .font(.headline)
                                        Text("\(timeString(clip.start)) - \(timeString(clip.end))  |  \(clip.tags.joined(separator: ", "))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(String(format: "%.0f%%", clip.confidence * 100))
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(.blue)
                                }
                                Divider()
                            }
                        }
                        .padding(2)
                    }

                    GroupBox("Transcript Timeline") {
                        VStack(spacing: 10) {
                            ForEach(project.transcriptSegments) { segment in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("\(timeString(segment.start))")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                        .frame(width: 52, alignment: .leading)
                                    Text(segment.text)
                                        .font(.body)
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                    }
                } else {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("No project loaded")
                                .font(.headline)
                            Text("Paste a YouTube link and click Create Project, then manage Current/Working/Past projects in Projects + Outputs.")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(4)
                    }
                }
            }
            .padding(22)
        }
    }

    private func timeString(_ value: TimeInterval) -> String {
        let total = Int(value.rounded())
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func statusColor(_ status: ProjectStatus) -> Color {
        switch status {
        case .current: return .blue
        case .working: return .orange
        case .past: return .gray
        }
    }
}

struct ProjectsView: View {
    @EnvironmentObject private var store: StudioStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Projects and Output History")
                    .font(.title2.weight(.bold))

                HStack(spacing: 10) {
                    TextField("Paste YouTube URL/video ID or direct video URL", text: $store.youtubeInput)
                        .textFieldStyle(.roundedBorder)

                    Button("Create Project") {
                        store.createProjectFromYouTubeLink()
                    }
                    .buttonStyle(.borderedProminent)
                }

                HStack(spacing: 12) {
                    MetricCard(title: "Current", value: "\(store.currentProjects.count)", subtitle: "active projects")
                    MetricCard(title: "Working", value: "\(store.workingProjects.count)", subtitle: "in progress")
                    MetricCard(title: "Past", value: "\(store.pastProjects.count)", subtitle: "archived")
                    MetricCard(title: "Outputs", value: "\(store.outputHistory.count)", subtitle: "export bundles")
                }

                ProjectBucketView(title: "Current Projects", projects: store.currentProjects)
                ProjectBucketView(title: "Working Projects", projects: store.workingProjects)
                ProjectBucketView(title: "Past Projects", projects: store.pastProjects)

                GroupBox("All Project Outputs") {
                    if store.outputHistory.isEmpty {
                        Text("No outputs yet. Export from Transactions to generate output bundles.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(store.outputHistory) { item in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(item.projectTitle)
                                            .font(.headline)
                                        Text(item.projectStatus.label)
                                            .font(.caption.weight(.semibold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(statusColor(item.projectStatus).opacity(0.16))
                                            .clipShape(Capsule())
                                        Spacer()
                                        Text(dateText(item.export.date))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Text("\(item.export.preset.platform.rawValue) • \(item.export.preset.renderQuality.rawValue)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Text(item.export.outputPath)
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)

                                    HStack {
                                        Button("Open Project") {
                                            store.selectProject(item.projectID)
                                        }
                                        .buttonStyle(.bordered)

                                        Button("Reveal Output") {
                                            store.revealOutput(path: item.export.outputPath)
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                                if item.id != store.outputHistory.last?.id {
                                    Divider()
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(22)
        }
    }

    private func statusColor(_ status: ProjectStatus) -> Color {
        switch status {
        case .current: return .blue
        case .working: return .orange
        case .past: return .gray
        }
    }

    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct YouTubeHubView: View {
    @EnvironmentObject private var store: StudioStore
    @EnvironmentObject private var youtube: YouTubeStore

    @State private var selectedExportID: UUID?
    @State private var uploadTitle: String = ""
    @State private var uploadDescription: String = ""
    @State private var privacy: YouTubePrivacyStatus = .privateVideo

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("YouTube Hub")
                    .font(.title2.weight(.bold))

                Text("Sign in with YouTube, manage channels/pages, review latest uploads, and publish rendered clips directly.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let error = youtube.lastError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                if let uploadedID = youtube.lastUploadedVideoID {
                    HStack(spacing: 8) {
                        Text("Last upload: \(uploadedID)")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                        Button("Open Uploaded Video") {
                            youtube.openUploadedVideo(videoID: uploadedID)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                GroupBox("OAuth Setup") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            TextField("Google OAuth Client ID", text: $youtube.clientID)
                                .textFieldStyle(.roundedBorder)

                            Button("Save Client ID") {
                                youtube.saveClientID()
                            }
                            .buttonStyle(.bordered)
                        }

                        HStack {
                            Button(youtube.isAuthenticated ? "Reconnect" : "Connect YouTube") {
                                youtube.connectYouTube()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(youtube.isBusy)

                            Button("Sign Out") {
                                youtube.signOut()
                            }
                            .buttonStyle(.bordered)
                            .disabled(youtube.isAuthenticated == false)

                            Button("Refresh Channels") {
                                Task {
                                    await youtube.refreshChannelsAndVideos()
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(youtube.isAuthenticated == false || youtube.isBusy)

                            Spacer()
                            Text(youtube.isAuthenticated ? "Connected" : "Disconnected")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background((youtube.isAuthenticated ? Color.green : Color.gray).opacity(0.18))
                                .clipShape(Capsule())
                        }

                        if let code = youtube.verificationCode {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Verification Code")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Text(code)
                                        .font(.title3.monospaced().weight(.semibold))
                                    Button("Open Verification URL") {
                                        youtube.openVerificationURL()
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }

                        Text(youtube.statusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                GroupBox("Channels / Pages") {
                    if youtube.channels.isEmpty {
                        Text("No channels loaded yet. Connect YouTube and refresh.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            Picker(
                                "Active Channel",
                                selection: Binding(
                                    get: { youtube.selectedChannelID ?? "" },
                                    set: { youtube.setSelectedChannel($0) }
                                )
                            ) {
                                ForEach(youtube.channels) { channel in
                                    Text(channel.title).tag(channel.id)
                                }
                            }
                            .pickerStyle(.menu)

                            ForEach(youtube.channels) { channel in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(channel.title)
                                            .font(.headline)
                                        Text(channel.handle ?? channel.id)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if let count = channel.subscriberCount {
                                        Text("\(count) subscribers")
                                            .font(.caption.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                    }
                                    if channel.id == youtube.selectedChannelID {
                                        Text("Active")
                                            .font(.caption.weight(.semibold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(Color.blue.opacity(0.16))
                                            .clipShape(Capsule())
                                    }
                                }
                                if channel.id != youtube.channels.last?.id {
                                    Divider()
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                GroupBox("Upload Rendered Clip") {
                    let candidates = store.availableVideoExports()

                    VStack(alignment: .leading, spacing: 10) {
                        if candidates.isEmpty {
                            Text("No rendered video exports found. Export from Transactions first.")
                                .foregroundStyle(.secondary)
                        } else {
                            Picker(
                                "Rendered File",
                                selection: Binding(
                                    get: {
                                        selectedExportID ?? candidates.first?.id ?? UUID()
                                    },
                                    set: { selectedExportID = $0 }
                                )
                            ) {
                                ForEach(candidates) { candidate in
                                    Text(candidate.displayName).tag(candidate.id)
                                }
                            }
                            .pickerStyle(.menu)

                            TextField("YouTube Title", text: $uploadTitle)
                                .textFieldStyle(.roundedBorder)

                            TextField("Description", text: $uploadDescription, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(2...6)

                            Picker("Privacy", selection: $privacy) {
                                ForEach(YouTubePrivacyStatus.allCases) { option in
                                    Text(option.label).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)

                            HStack {
                                Button("Upload to YouTube") {
                                    guard let selected = currentCandidate(from: candidates) else {
                                        return
                                    }
                                    if uploadTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        uploadTitle = selected.projectTitle
                                    }
                                    youtube.uploadVideo(
                                        filePath: selected.filePath,
                                        title: uploadTitle,
                                        description: uploadDescription,
                                        privacy: privacy
                                    )
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(youtube.isAuthenticated == false || youtube.isBusy)

                                if let selected = currentCandidate(from: candidates) {
                                    Button("Reveal File") {
                                        store.revealOutput(path: selected.filePath)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }

                GroupBox("Recent Channel Videos") {
                    if youtube.recentVideos.isEmpty {
                        Text("No videos loaded for the selected channel yet.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(youtube.recentVideos) { video in
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(video.title)
                                            .font(.headline)
                                        if let publishedAt = video.publishedAt {
                                            Text(dateText(publishedAt))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Button("Open") {
                                        youtube.openVideo(video)
                                    }
                                    .buttonStyle(.bordered)
                                }
                                if video.id != youtube.recentVideos.last?.id {
                                    Divider()
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(22)
        }
        .onAppear {
            if uploadTitle.isEmpty,
               let first = store.availableVideoExports().first {
                selectedExportID = first.id
                uploadTitle = first.projectTitle
            }
        }
    }

    private func currentCandidate(from candidates: [ExportVideoCandidate]) -> ExportVideoCandidate? {
        if let selectedExportID {
            return candidates.first(where: { $0.id == selectedExportID }) ?? candidates.first
        }
        return candidates.first
    }

    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ProjectBucketView: View {
    @EnvironmentObject private var store: StudioStore

    var title: String
    var projects: [StudioProject]

    var body: some View {
        GroupBox(title) {
            if projects.isEmpty {
                Text("No projects in this bucket.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(projects) { project in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(project.title)
                                            .font(.headline)
                                        if store.activeProjectID == project.id {
                                            Text("Active")
                                                .font(.caption.weight(.semibold))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.blue.opacity(0.16))
                                                .clipShape(Capsule())
                                        }
                                    }
                                    Text("Video ID: \(project.videoID) • Updated: \(dateText(project.updatedAt))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("Outputs: \(project.exports.count) • Clips: \(project.clips.count) • Captions: \(project.captions.count)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Picker(
                                    "Status",
                                    selection: Binding(
                                        get: { project.status },
                                        set: { store.setProjectStatus(project.id, status: $0) }
                                    )
                                ) {
                                    ForEach(ProjectStatus.allCases) { status in
                                        Text(status.label).tag(status)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                            }

                            HStack {
                                Button("Open") {
                                    store.selectProject(project.id)
                                }
                                .buttonStyle(.bordered)

                                Button("Set Current") {
                                    store.setProjectStatus(project.id, status: .current)
                                    store.selectProject(project.id)
                                }
                                .buttonStyle(.bordered)

                                if project.exports.isEmpty == false {
                                    Button("Reveal Latest Output") {
                                        store.revealLatestOutput(for: project.id)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                        if project.id != projects.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct CaptionsView: View {
    @EnvironmentObject private var store: StudioStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Captation and Subtitle Studio")
                .font(.title2.weight(.bold))

            HStack {
                Picker("Style", selection: $store.selectedCaptionStyle) {
                    ForEach(CaptionStyle.allCases) { style in
                        Text(style.label).tag(style)
                    }
                }
                .pickerStyle(.segmented)

                Button("Regenerate Captions") {
                    store.regenerateCaptions()
                }
                .buttonStyle(.borderedProminent)
            }

            if let project = store.activeProject {
                List(project.captions.prefix(80)) { caption in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("\(timeString(caption.start)) - \(timeString(caption.end))")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Text(caption.style.label)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        Text(caption.text)
                            .font(.body)
                    }
                    .padding(.vertical, 2)
                }
            } else {
                emptyProjectText
            }
        }
        .padding(22)
    }

    private var emptyProjectText: some View {
        Text("Create or open a project first to generate captions.")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func timeString(_ value: TimeInterval) -> String {
        let total = Int(value.rounded())
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct TimelineView: View {
    @EnvironmentObject private var store: StudioStore
    @State private var player = AVPlayer()
    @State private var primaryVideoImporterPresented = false
    @State private var secondaryVideoImporterPresented = false
    @State private var audioImporterPresented = false
    @State private var sourceURLInput: String = ""
    @State private var currentTime: Double = 0
    @State private var isPlaying = false
    @State private var previewTask: Task<Void, Never>?

    private let playbackTimer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Full Video/Audio Timeline Editor")
                    .font(.title2.weight(.bold))

                Text("Import source footage, trim clips, adjust speed, layer audio, preview playback, then export a rendered video.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let project = store.activeProject {
                    HStack(spacing: 8) {
                        Button("Import Primary Video") {
                            primaryVideoImporterPresented = true
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Add B-roll Video") {
                            secondaryVideoImporterPresented = true
                        }
                        .buttonStyle(.bordered)

                        Button("Add Audio Track") {
                            audioImporterPresented = true
                        }
                        .buttonStyle(.bordered)

                        Button("Build Timeline from AI Clips") {
                            store.buildTimelineFromAutoClips()
                            reloadPreview()
                        }
                        .buttonStyle(.bordered)

                        Button("Add Full Primary Clip") {
                            store.addFullPrimaryClip()
                            reloadPreview()
                        }
                        .buttonStyle(.bordered)
                    }

                    HStack(spacing: 8) {
                        TextField("Paste direct video URL (mp4/mov/m4v)", text: $sourceURLInput)
                            .textFieldStyle(.roundedBorder)

                        Button("Import URL as Primary") {
                            let candidate = sourceURLInput.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard candidate.isEmpty == false else { return }
                            Task { @MainActor in
                                await store.importPrimaryVideo(filePath: candidate)
                                reloadPreview()
                            }
                        }
                        .buttonStyle(.bordered)

                        Button("Import URL as B-roll") {
                            let candidate = sourceURLInput.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard candidate.isEmpty == false else { return }
                            Task { @MainActor in
                                await store.importSecondaryVideo(filePath: candidate)
                                reloadPreview()
                            }
                        }
                        .buttonStyle(.bordered)
                    }

                    Text("Note: YouTube watch links are not direct media files. Import local/downloaded media for timeline playback and editing.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    GroupBox("Preview Monitor") {
                        VStack(spacing: 10) {
                            VideoPlayer(player: player)
                                .frame(height: 340)
                                .background(Color.black.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            HStack(spacing: 8) {
                                Button(isPlaying ? "Pause" : "Play") {
                                    togglePlayback()
                                }
                                .buttonStyle(.borderedProminent)

                                Button("Stop") {
                                    stopPlayback()
                                }
                                .buttonStyle(.bordered)

                                Button("Refresh Preview") {
                                    reloadPreview()
                                }
                                .buttonStyle(.bordered)

                                Spacer()
                                Text("\(timeString(currentTime)) / \(timeString(playerDuration))")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }

                            Slider(
                                value: Binding(
                                    get: { currentTime },
                                    set: { newValue in
                                        currentTime = newValue
                                        seek(to: newValue)
                                    }
                                ),
                                in: 0...max(playerDuration, 0.1)
                            )
                        }
                    }

                    GroupBox("Source Media") {
                        if project.mediaSources.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("No media imported. Import a primary video to start editing.")
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                if let sourceURL = URL(string: project.youtubeURL),
                                   sourceURL.scheme?.hasPrefix("http") == true {
                                    Button("Open Project Source URL") {
                                        NSWorkspace.shared.open(sourceURL)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .padding(.vertical, 4)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(project.mediaSources) { source in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(source.label)
                                                .font(.headline)
                                            Text("Duration: \(timeString(source.duration))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if source.id == project.primaryMediaSourceID {
                                            Text("Primary")
                                                .font(.caption.weight(.semibold))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.blue.opacity(0.16))
                                                .clipShape(Capsule())
                                        } else {
                                            Button("Set Primary") {
                                                store.setPrimaryMediaSource(source.id)
                                                reloadPreview()
                                            }
                                            .buttonStyle(.bordered)
                                        }
                                    }
                                    if source.id != project.mediaSources.last?.id {
                                        Divider()
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    GroupBox("Video Timeline Clips") {
                        if project.timelineVideoClips.isEmpty {
                            Text("Timeline has no clips. Build from AI clips or add a full primary clip.")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                        } else {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(Array(project.timelineVideoClips.enumerated()), id: \.element.id) { index, clip in
                                    TimelineVideoClipRow(
                                        index: index,
                                        clip: clip,
                                        sourceLabel: project.mediaSources.first(where: { $0.id == clip.sourceID })?.label ?? "Unknown Source",
                                        sourceDuration: project.mediaSources.first(where: { $0.id == clip.sourceID })?.duration ?? 0,
                                        onMoveUp: {
                                            store.moveTimelineVideoClip(clip.id, direction: -1)
                                            reloadPreview()
                                        },
                                        onMoveDown: {
                                            store.moveTimelineVideoClip(clip.id, direction: 1)
                                            reloadPreview()
                                        },
                                        onTrimInBackward: {
                                            store.nudgeTimelineVideoInPoint(clip.id, delta: -0.25)
                                            reloadPreview()
                                        },
                                        onTrimInForward: {
                                            store.nudgeTimelineVideoInPoint(clip.id, delta: 0.25)
                                            reloadPreview()
                                        },
                                        onTrimOutBackward: {
                                            store.nudgeTimelineVideoOutPoint(clip.id, delta: -0.25)
                                            reloadPreview()
                                        },
                                        onTrimOutForward: {
                                            store.nudgeTimelineVideoOutPoint(clip.id, delta: 0.25)
                                            reloadPreview()
                                        },
                                        onSpeedDown: {
                                            store.adjustTimelineVideoSpeed(clip.id, delta: -0.05)
                                            reloadPreview()
                                        },
                                        onSpeedUp: {
                                            store.adjustTimelineVideoSpeed(clip.id, delta: 0.05)
                                            reloadPreview()
                                        },
                                        onToggleMute: {
                                            store.toggleTimelineVideoMute(clip.id)
                                            reloadPreview()
                                        },
                                        onRemove: {
                                            store.removeTimelineVideoClip(clip.id)
                                            reloadPreview()
                                        }
                                    )

                                    if clip.id != project.timelineVideoClips.last?.id {
                                        Divider()
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    GroupBox("Audio Tracks") {
                        if project.timelineAudioClips.isEmpty {
                            Text("No additional audio tracks. Add music/SFX/bed tracks from local files.")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                        } else {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(project.timelineAudioClips) { audioClip in
                                    TimelineAudioClipRow(
                                        clip: audioClip,
                                        onStartBack: {
                                            store.nudgeTimelineAudioStart(audioClip.id, delta: -0.25)
                                            reloadPreview()
                                        },
                                        onStartForward: {
                                            store.nudgeTimelineAudioStart(audioClip.id, delta: 0.25)
                                            reloadPreview()
                                        },
                                        onVolumeChange: { value in
                                            store.setTimelineAudioVolume(audioClip.id, value: value)
                                        },
                                        onRemove: {
                                            store.removeTimelineAudioClip(audioClip.id)
                                            reloadPreview()
                                        }
                                    )

                                    if audioClip.id != project.timelineAudioClips.last?.id {
                                        Divider()
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } else {
                    Text("Create or open a project first to use timeline tools.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(22)
        }
        .onAppear {
            reloadPreview()
        }
        .onChange(of: store.activeProject?.updatedAt) { _ in
            reloadPreview()
        }
        .onReceive(playbackTimer) { _ in
            syncPlaybackState()
        }
        .onDisappear {
            previewTask?.cancel()
            player.pause()
            isPlaying = false
        }
        .fileImporter(
            isPresented: $primaryVideoImporterPresented,
            allowedContentTypes: [.movie],
            allowsMultipleSelection: false
        ) { result in
            guard case .success(let urls) = result,
                  let url = urls.first else {
                return
            }
            Task { @MainActor in
                await store.importPrimaryVideo(filePath: url.path)
                reloadPreview()
            }
        }
        .fileImporter(
            isPresented: $secondaryVideoImporterPresented,
            allowedContentTypes: [.movie],
            allowsMultipleSelection: false
        ) { result in
            guard case .success(let urls) = result,
                  let url = urls.first else {
                return
            }
            Task { @MainActor in
                await store.importSecondaryVideo(filePath: url.path)
                reloadPreview()
            }
        }
        .fileImporter(
            isPresented: $audioImporterPresented,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            guard case .success(let urls) = result,
                  let url = urls.first else {
                return
            }
            Task { @MainActor in
                await store.importTimelineAudio(filePath: url.path)
                reloadPreview()
            }
        }
    }

    private var playerDuration: Double {
        guard let item = player.currentItem else {
            return max(0.1, store.activeTimelineDuration)
        }
        let duration = CMTimeGetSeconds(item.duration)
        if duration.isFinite, duration > 0 {
            return duration
        }
        return max(0.1, store.activeTimelineDuration)
    }

    private func reloadPreview(autoPlay: Bool = false) {
        previewTask?.cancel()
        isPlaying = false
        player.pause()

        previewTask = Task { @MainActor in
            let item = await store.makeTimelinePreviewItem()
            guard Task.isCancelled == false else { return }

            player.replaceCurrentItem(with: item)
            currentTime = 0

            if autoPlay, item != nil {
                player.play()
                isPlaying = true
            } else {
                isPlaying = false
            }
        }
    }

    private func togglePlayback() {
        guard player.currentItem != nil else {
            reloadPreview(autoPlay: true)
            return
        }

        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    private func stopPlayback() {
        player.pause()
        player.seek(to: .zero)
        currentTime = 0
        isPlaying = false
    }

    private func seek(to value: Double) {
        guard player.currentItem != nil else { return }
        let target = CMTime(seconds: max(0, value), preferredTimescale: 600)
        player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    private func syncPlaybackState() {
        let now = CMTimeGetSeconds(player.currentTime())
        if now.isFinite {
            currentTime = max(0, min(now, playerDuration))
        }
    }

    private func timeString(_ value: TimeInterval) -> String {
        let clamped = max(0, value)
        let total = Int(clamped.rounded())
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct TimelineVideoClipRow: View {
    var index: Int
    var clip: TimelineVideoClip
    var sourceLabel: String
    var sourceDuration: TimeInterval
    var onMoveUp: () -> Void
    var onMoveDown: () -> Void
    var onTrimInBackward: () -> Void
    var onTrimInForward: () -> Void
    var onTrimOutBackward: () -> Void
    var onTrimOutForward: () -> Void
    var onSpeedDown: () -> Void
    var onSpeedUp: () -> Void
    var onToggleMute: () -> Void
    var onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Clip \(index + 1): \(clip.label)")
                    .font(.headline)
                Spacer()
                Text(clip.muted ? "Muted" : "Audio On")
                    .font(.caption)
                    .foregroundStyle(clip.muted ? .red : .green)
            }

            Text("Source: \(sourceLabel)  •  Source Duration: \(timeString(sourceDuration))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(
                "In \(timeString(clip.inPoint))  Out \(timeString(clip.outPoint))  •  Timeline \(timeString(clip.timelineStart)) - \(timeString(clip.timelineEnd))"
            )
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Button("Move Up", action: onMoveUp).buttonStyle(.bordered)
                Button("Move Down", action: onMoveDown).buttonStyle(.bordered)
                Button("Remove", action: onRemove).buttonStyle(.bordered)
                Spacer()
            }

            HStack(spacing: 6) {
                Text("Trim In")
                    .font(.caption)
                Button("-0.25", action: onTrimInBackward).buttonStyle(.bordered)
                Button("+0.25", action: onTrimInForward).buttonStyle(.bordered)
                Text("Trim Out")
                    .font(.caption)
                Button("-0.25", action: onTrimOutBackward).buttonStyle(.bordered)
                Button("+0.25", action: onTrimOutForward).buttonStyle(.bordered)
            }

            HStack(spacing: 6) {
                Text("Speed \(String(format: "%.2fx", clip.playbackRate))")
                    .font(.caption.monospacedDigit())
                Button("-0.05", action: onSpeedDown).buttonStyle(.bordered)
                Button("+0.05", action: onSpeedUp).buttonStyle(.bordered)
                Button(clip.muted ? "Unmute Clip Audio" : "Mute Clip Audio", action: onToggleMute)
                    .buttonStyle(.bordered)
            }
        }
    }

    private func timeString(_ value: TimeInterval) -> String {
        let total = Int(max(0, value).rounded())
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct TimelineAudioClipRow: View {
    var clip: TimelineAudioClip
    var onStartBack: () -> Void
    var onStartForward: () -> Void
    var onVolumeChange: (Double) -> Void
    var onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(clip.label)
                    .font(.headline)
                Spacer()
                Button("Remove", action: onRemove)
                    .buttonStyle(.bordered)
            }

            Text("Start \(timeString(clip.timelineStart))  •  Clip Length \(timeString(clip.sourceDuration))")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Button("Start -0.25", action: onStartBack).buttonStyle(.bordered)
                Button("Start +0.25", action: onStartForward).buttonStyle(.bordered)
            }

            HStack(spacing: 10) {
                Text("Volume")
                    .font(.caption)
                Slider(
                    value: Binding(
                        get: { clip.volume },
                        set: { onVolumeChange($0) }
                    ),
                    in: 0...2
                )
                Text(String(format: "%.2fx", clip.volume))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 52, alignment: .trailing)
            }
        }
    }

    private func timeString(_ value: TimeInterval) -> String {
        let total = Int(max(0, value).rounded())
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct VoiceOverView: View {
    @EnvironmentObject private var store: StudioStore
    @State private var importerPresented = false
    @State private var selectedVoiceOverID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Voice Over Timeline")
                .font(.title2.weight(.bold))

            Text("Assign narration notes and attach audio files per stitched clip.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let project = store.activeProject {
                List(project.voiceOvers) { segment in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(timeString(segment.start)) - \(timeString(segment.end))")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Spacer()
                            if let audioPath = segment.audioFilePath {
                                Text(URL(fileURLWithPath: audioPath).lastPathComponent)
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            } else {
                                Text("No audio attached")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        TextField(
                            "Narration note",
                            text: Binding(
                                get: { segment.note },
                                set: { store.updateVoiceOverNote(segment.id, note: $0) }
                            )
                        )
                        .textFieldStyle(.roundedBorder)

                        Button("Attach Audio File") {
                            selectedVoiceOverID = segment.id
                            importerPresented = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Text("Create or open a project first to build voice-over lanes.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(22)
        .fileImporter(
            isPresented: $importerPresented,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            guard case .success(let urls) = result,
                  let selectedID = selectedVoiceOverID,
                  let url = urls.first else {
                return
            }
            store.attachVoiceOverAudio(selectedID, filePath: url.path)
        }
    }

    private func timeString(_ value: TimeInterval) -> String {
        let total = Int(value.rounded())
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct ProEditorView: View {
    @EnvironmentObject private var store: StudioStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Professional Editor Tools")
                    .font(.title2.weight(.bold))

                if store.activeProject != nil {
                    GroupBox("Output Frame") {
                        HStack {
                            Picker(
                                "Aspect Ratio",
                                selection: store.editorBinding(for: \.aspectRatio, fallback: .vertical)
                            ) {
                                ForEach(AspectRatio.allCases) { ratio in
                                    Text(ratio.rawValue).tag(ratio)
                                }
                            }

                            Picker(
                                "Playback Speed",
                                selection: store.editorBinding(for: \.speedPreset, fallback: .normal)
                            ) {
                                ForEach(SpeedPreset.allCases) { speed in
                                    Text(speed.rawValue).tag(speed)
                                }
                            }

                            Picker(
                                "Transition",
                                selection: store.editorBinding(for: \.transitionStyle, fallback: .snappy)
                            ) {
                                ForEach(TransitionStyle.allCases) { transition in
                                    Text(transition.label).tag(transition)
                                }
                            }
                        }
                    }

                    GroupBox("AI Editing Assists") {
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle("Auto Reframe", isOn: store.editorBinding(for: \.autoReframe, fallback: true))
                            Toggle("Silence Removal", isOn: store.editorBinding(for: \.silenceRemoval, fallback: true))
                            Toggle("Smart Jump Cuts", isOn: store.editorBinding(for: \.smartJumpCuts, fallback: true))
                            Toggle("Smart B-roll Suggestions", isOn: store.editorBinding(for: \.smartBroll, fallback: false))
                            Toggle("Noise Reduction", isOn: store.editorBinding(for: \.noiseReduction, fallback: true))
                            Toggle("Color Boost", isOn: store.editorBinding(for: \.colorBoost, fallback: true))
                        }
                    }
                } else {
                    Text("Create or open a project first to tune editor controls.")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(22)
        }
    }
}

struct TransactionsView: View {
    @EnvironmentObject private var store: StudioStore
    @State private var type: TransactionType = .purchase
    @State private var amount: String = ""
    @State private var description: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Transactions and Exports")
                .font(.title2.weight(.bold))

            GroupBox("Export Preset") {
                HStack {
                    Picker("Platform", selection: platformBinding) {
                        ForEach(ExportPlatform.allCases) { platform in
                            Text(platform.rawValue).tag(platform)
                        }
                    }

                    Picker("Quality", selection: qualityBinding) {
                        ForEach(RenderQuality.allCases) { quality in
                            Text(quality.rawValue).tag(quality)
                        }
                    }

                    Toggle("Captions", isOn: includeCaptionsBinding)
                    Toggle("Voice Over", isOn: includeVoiceOverBinding)

                    Button(store.isExporting ? "Exporting..." : "Export Bundle") {
                        store.exportCurrentProject()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(store.isExporting || store.activeProject == nil)
                }
            }

            GroupBox("Add Ledger Entry") {
                HStack {
                    Picker("Type", selection: $type) {
                        ForEach(TransactionType.allCases) { item in
                            Text(item.label).tag(item)
                        }
                    }

                    TextField("Amount", text: $amount)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)

                    TextField("Description", text: $description)
                        .textFieldStyle(.roundedBorder)

                    Button("Add") {
                        guard let value = Double(amount) else {
                            store.lastError = "Amount must be a number."
                            return
                        }
                        store.addTransaction(type: type, amount: value, description: description)
                        amount = ""
                        description = ""
                    }
                    .buttonStyle(.bordered)
                }
            }

            if let project = store.activeProject {
                List(project.transactions) { transaction in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(transaction.description)
                                .font(.headline)
                            Text("\(transaction.type.label) • \(transaction.status.label)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(String(format: "%@ %.2f", transaction.currency, transaction.amount))
                            .font(.body.monospacedDigit())
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Text("Create or open a project first to manage exports and transactions.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(22)
    }

    private var platformBinding: Binding<ExportPlatform> {
        Binding(
            get: { store.exportPreset.platform },
            set: { store.exportPreset.platform = $0 }
        )
    }

    private var qualityBinding: Binding<RenderQuality> {
        Binding(
            get: { store.exportPreset.renderQuality },
            set: { store.exportPreset.renderQuality = $0 }
        )
    }

    private var includeCaptionsBinding: Binding<Bool> {
        Binding(
            get: { store.exportPreset.includeCaptions },
            set: { store.exportPreset.includeCaptions = $0 }
        )
    }

    private var includeVoiceOverBinding: Binding<Bool> {
        Binding(
            get: { store.exportPreset.includeVoiceOver },
            set: { store.exportPreset.includeVoiceOver = $0 }
        )
    }
}

struct BenchmarksView: View {
    @EnvironmentObject private var store: StudioStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Top Clipper Feature Benchmark")
                .font(.title2.weight(.bold))

            Text("This matrix tracks capabilities popularized by major clipping tools and whether this local build currently covers them.")
                .foregroundStyle(.secondary)

            if let project = store.activeProject {
                List(project.benchmarkCoverage) { benchmark in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(benchmark.competitor) · \(benchmark.feature)")
                                .font(.headline)
                            Text(benchmark.notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle(
                            "Implemented",
                            isOn: Binding(
                                get: { benchmark.implemented },
                                set: { store.toggleBenchmark(benchmark.id, implemented: $0) }
                            )
                        )
                        .toggleStyle(.switch)
                        .labelsHidden()
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Text("Create or open a project first to load benchmark coverage.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(22)
    }
}

struct MetricCard: View {
    var title: String
    var value: String
    var subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.semibold))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
