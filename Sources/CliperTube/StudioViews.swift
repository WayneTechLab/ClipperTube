import AppKit
import AVKit
import SwiftUI
import UniformTypeIdentifiers
import WebKit

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
                .padding(.bottom, 2)

            Text("Wayne Tech Lab LLC")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text("v1.4.0")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 8)
            
            // Mode Switcher
            HStack(spacing: 4) {
                ForEach(AppMode.allCases) { mode in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            store.appMode = mode
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: mode.icon)
                                .font(.caption)
                            Text(mode == .easy ? "Easy" : "Pro")
                                .font(.caption.weight(.medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(store.appMode == mode ? Color.accentColor : Color.secondary.opacity(0.15))
                        .foregroundStyle(store.appMode == mode ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 12)
            
            if store.appMode == .pro {
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
            } else {
                // Easy Mode simplified nav
                ForEach(easyModeSections, id: \.self) { section in
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
            }

            Spacer(minLength: 0)

            if let project = store.activeProject {
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.title)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                    Text("\(project.timelineVideoClips.count) clips • \(project.mediaSources.count) sources")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 4)
            }
        }
        .padding(16)
        .frame(width: 260)
    }
    
    private var easyModeSections: [StudioSection] {
        [.dashboard, .projects, .fileManager, .timeline]
    }

    @ViewBuilder
    private var detail: some View {
        if store.appMode == .easy && store.selectedSection == .dashboard {
            EasyModeView()
        } else {
            switch store.selectedSection {
            case .dashboard:
                DashboardView()
            case .projects:
                ProjectsView()
            case .fileManager:
                CMSView()
            case .youtube:
                YouTubeHubView()
            case .clipIntelligence:
                ClipIntelligenceView()
            case .captions:
                CaptionsView()
            case .timeline:
                TimelineView()
            case .voiceOver:
                VoiceOverView()
            case .audioStudio:
                AudioStudioView()
            case .proEditor:
                ProEditorView()
            case .distribution:
                DistributionCenterView()
            case .transactions:
                TransactionsView()
            case .revenueClients:
                RevenueClientsView()
            case .benchmarks:
                BenchmarksView()
            }
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
        case .fileManager: return "folder.fill"
        case .youtube: return "play.tv"
        case .clipIntelligence: return "brain.head.profile"
        case .captions: return "captions.bubble"
        case .timeline: return "timeline.selection"
        case .voiceOver: return "waveform"
        case .audioStudio: return "hifispeaker.2"
        case .proEditor: return "slider.horizontal.3"
        case .distribution: return "paperplane"
        case .transactions: return "creditcard"
        case .revenueClients: return "chart.line.uptrend.xyaxis"
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

                // URL Input + Actions
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 12) {
                        TextField("Paste YouTube URL to auto-download and start editing", text: $store.youtubeInput)
                            .textFieldStyle(.roundedBorder)
                            .disabled(store.isDownloading)

                        if store.ytdlpAvailable {
                            Picker("Quality", selection: $store.selectedDownloadQuality) {
                                ForEach(VideoQuality.allCases) { quality in
                                    Text(quality.rawValue).tag(quality)
                                }
                            }
                            .frame(width: 120)
                            .disabled(store.isDownloading)
                        }

                        if store.isDownloading {
                            Button("Cancel") {
                                store.cancelDownload()
                            }
                            .buttonStyle(.bordered)
                        } else {
                            Button("Create Project") {
                                store.createProjectFromYouTubeLink()
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        Button("Auto Clip + Stitch") {
                            store.runAutoClipAndStitch()
                        }
                        .buttonStyle(.bordered)
                        .disabled(store.isDownloading || store.activeProject == nil)
                    }

                    // Download Progress Bar
                    if store.isDownloading {
                        VStack(alignment: .leading, spacing: 4) {
                            ProgressView(value: store.downloadProgress)
                                .progressViewStyle(.linear)
                            HStack {
                                Text(String(format: "%.0f%%", store.downloadProgress * 100))
                                    .font(.caption.monospacedDigit())
                                if !store.downloadSpeed.isEmpty {
                                    Text("•")
                                        .foregroundStyle(.secondary)
                                    Text(store.downloadSpeed)
                                        .font(.caption)
                                }
                                if !store.downloadETA.isEmpty {
                                    Text("•")
                                        .foregroundStyle(.secondary)
                                    Text("ETA \(store.downloadETA)")
                                        .font(.caption)
                                }
                                Spacer()
                            }
                            .foregroundStyle(.secondary)
                        }
                        .padding(.top, 4)
                    }

                    // yt-dlp status indicator
                    if !store.ytdlpAvailable {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("yt-dlp not found. Install for auto-download:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("brew install yt-dlp")
                                .font(.caption.monospaced())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            Button("Refresh") {
                                store.refreshYtdlpStatus()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(.top, 4)
                    }
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

                        Button("Export") {
                            store.selectedSection = .transactions
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(project.timelineVideoClips.isEmpty || store.isExporting)

                        Button("Timeline") {
                            store.selectedSection = .timeline
                        }
                        .buttonStyle(.bordered)

                        Button("Projects + Outputs") {
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
                            if store.ytdlpAvailable {
                                Text("Paste a YouTube link above and click Create Project to auto-download and start editing immediately.")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Paste a YouTube link and click Create Project to start clipping.")
                                    .foregroundStyle(.secondary)
                            }
                            Text("You can also paste a direct MP4/MOV URL to create a project from raw footage.")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                            
                            if store.ytdlpAvailable {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text("Auto-download enabled (yt-dlp ready)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.top, 4)
                            }
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

// MARK: - Easy Mode View

struct EasyModeView: View {
    @EnvironmentObject private var store: StudioStore
    @State private var isAnimating = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                        .opacity(store.easyModeState.currentStep != .idle && !store.easyModeState.currentStep.isTerminal ? (isAnimating ? 0.6 : 1.0) : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
                    
                    Text("Easy Mode")
                        .font(.largeTitle.weight(.bold))
                    
                    Text("One-click video creation from YouTube")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                
                // URL Input
                if store.easyModeState.currentStep == .idle || store.easyModeState.currentStep.isTerminal {
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "link")
                                .foregroundStyle(.secondary)
                            TextField("Paste YouTube URL here...", text: $store.easyModeURL)
                                .textFieldStyle(.plain)
                                .font(.title3)
                        }
                        .padding(16)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .frame(maxWidth: 600)
                        
                        Button {
                            store.runEasyModePipeline(url: store.easyModeURL)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                Text("Create Video Automatically")
                                    .font(.headline)
                            }
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(store.easyModeURL.isEmpty)
                    }
                }
                
                // Pipeline Progress
                if store.easyModeState.currentStep != .idle {
                    VStack(spacing: 24) {
                        // Progress Steps
                        HStack(spacing: 0) {
                            ForEach(Array(EasyModePipelineStep.allCases.dropFirst().dropLast(2).enumerated()), id: \.element) { index, step in
                                VStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(stepColor(for: step))
                                            .frame(width: 40, height: 40)
                                        
                                        if store.easyModeState.currentStep == step {
                                            Circle()
                                                .stroke(Color.accentColor, lineWidth: 3)
                                                .frame(width: 48, height: 48)
                                                .scaleEffect(isAnimating ? 1.1 : 1.0)
                                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
                                        }
                                        
                                        Image(systemName: step.icon)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(stepIconColor(for: step))
                                    }
                                    
                                    Text(step.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(isStepActive(step) ? .primary : .secondary)
                                }
                                .frame(maxWidth: .infinity)
                                
                                if index < EasyModePipelineStep.allCases.dropFirst().dropLast(2).count - 1 {
                                    Rectangle()
                                        .fill(stepConnectorColor(after: step))
                                        .frame(height: 2)
                                        .frame(maxWidth: 40)
                                }
                            }
                        }
                        .padding(.horizontal, 40)
                        
                        // Progress Bar
                        VStack(spacing: 8) {
                            ProgressView(value: store.easyModeState.progress)
                                .progressViewStyle(.linear)
                                .scaleEffect(y: 2)
                            
                            Text(store.easyModeState.statusText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: 500)
                    }
                    .padding(.vertical, 24)
                    .onAppear { isAnimating = true }
                }
                
                // Error Display
                if let error = store.easyModeState.error {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .foregroundStyle(.red)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Complete State
                if store.easyModeState.currentStep == .complete {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.green)
                        
                        Text("Your video is ready!")
                            .font(.title2.weight(.semibold))
                        
                        HStack(spacing: 12) {
                            if let outputPath = store.easyModeState.outputPath {
                                Button {
                                    store.revealOutput(path: outputPath)
                                } label: {
                                    HStack {
                                        Image(systemName: "folder")
                                        Text("Show in Finder")
                                    }
                                }
                                .buttonStyle(.bordered)
                                
                                Button {
                                    NSWorkspace.shared.open(URL(fileURLWithPath: outputPath))
                                } label: {
                                    HStack {
                                        Image(systemName: "play.fill")
                                        Text("Play Video")
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            
                            Button {
                                store.resetEasyMode()
                            } label: {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Create Another")
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 24)
                }
                
                // Recent Outputs Preview
                if store.easyModeState.currentStep == .idle {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Creations")
                            .font(.headline)
                        
                        if store.outputHistory.isEmpty {
                            Text("No videos created yet. Paste a YouTube URL above to get started!")
                                .foregroundStyle(.secondary)
                                .padding()
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
                                ForEach(store.outputHistory.prefix(6)) { item in
                                    VStack(alignment: .leading, spacing: 8) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.secondary.opacity(0.2))
                                            .frame(height: 120)
                                            .overlay {
                                                Image(systemName: "film")
                                                    .font(.largeTitle)
                                                    .foregroundStyle(.secondary)
                                            }
                                        
                                        Text(item.projectTitle)
                                            .font(.caption.weight(.medium))
                                            .lineLimit(1)
                                        
                                        Text(item.export.date, style: .relative)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .onTapGesture {
                                        store.revealOutput(path: item.export.outputPath)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 40)
                }
                
                Spacer(minLength: 40)
                
                // Switch to Pro Mode hint
                if store.easyModeState.currentStep == .idle {
                    HStack {
                        Text("Need more control?")
                            .foregroundStyle(.secondary)
                        Button("Switch to Pro Mode") {
                            store.appMode = .pro
                        }
                        .buttonStyle(.link)
                    }
                    .font(.caption)
                    .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private func stepColor(for step: EasyModePipelineStep) -> Color {
        if isStepComplete(step) { return .green }
        if store.easyModeState.currentStep == step { return .accentColor }
        return .secondary.opacity(0.3)
    }
    
    private func stepIconColor(for step: EasyModePipelineStep) -> Color {
        if isStepComplete(step) || store.easyModeState.currentStep == step { return .white }
        return .secondary
    }
    
    private func stepConnectorColor(after step: EasyModePipelineStep) -> Color {
        isStepComplete(step) ? .green : .secondary.opacity(0.3)
    }
    
    private func isStepComplete(_ step: EasyModePipelineStep) -> Bool {
        guard let currentIndex = EasyModePipelineStep.allCases.firstIndex(of: store.easyModeState.currentStep),
              let stepIndex = EasyModePipelineStep.allCases.firstIndex(of: step) else { return false }
        return stepIndex < currentIndex
    }
    
    private func isStepActive(_ step: EasyModePipelineStep) -> Bool {
        isStepComplete(step) || store.easyModeState.currentStep == step
    }
}

// MARK: - CMS / File Manager View

struct CMSView: View {
    @EnvironmentObject private var store: StudioStore
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 16) {
                Text("File Manager")
                    .font(.title2.weight(.bold))
                
                Spacer()
                
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search files...", text: $store.cmsSearchQuery)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(maxWidth: 200)
                
                // Filter
                Picker("Type", selection: $store.cmsFilterType) {
                    Text("All Files").tag(CMSFileType?.none)
                    ForEach(CMSFileType.allCases) { type in
                        Label(type.rawValue, systemImage: type.icon).tag(CMSFileType?.some(type))
                    }
                }
                .frame(width: 120)
                
                // Sort
                Picker("Sort", selection: $store.cmsSortOption) {
                    ForEach(CMSSortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .frame(width: 140)
                .onChange(of: store.cmsSortOption) { _ in
                    store.sortCMSFiles()
                }
                
                // View Mode
                Picker("View", selection: $store.cmsViewMode) {
                    ForEach(CMSViewMode.allCases) { mode in
                        Image(systemName: mode.icon).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
                
                Button {
                    store.scanCMSFiles()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }
            .padding()
            
            Divider()
            
            // Stats Bar
            HStack(spacing: 24) {
                StatBadge(icon: "doc.fill", label: "Files", value: "\(store.cmsStats.totalFiles)")
                StatBadge(icon: "film", label: "Videos", value: "\(store.cmsStats.videoCount)")
                StatBadge(icon: "square.and.arrow.up", label: "Exports", value: "\(store.cmsStats.exportCount)")
                StatBadge(icon: "internaldrive", label: "Storage", value: store.cmsStats.formattedSize)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.05))
            
            // File Grid/List
            ScrollView {
                if store.filteredCMSFiles.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No files found")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("Create a video in Easy Mode or import media to get started")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                } else {
                    switch store.cmsViewMode {
                    case .grid:
                        cmsGridView
                    case .list:
                        cmsListView
                    case .gallery:
                        cmsGalleryView
                    }
                }
            }
        }
    }
    
    private var cmsGridView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 16) {
            ForEach(store.filteredCMSFiles) { file in
                CMSFileCard(file: file)
            }
        }
        .padding()
    }
    
    private var cmsListView: some View {
        LazyVStack(spacing: 1) {
            ForEach(store.filteredCMSFiles) { file in
                CMSFileRow(file: file)
            }
        }
        .padding(.horizontal)
    }
    
    private var cmsGalleryView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 280))], spacing: 20) {
            ForEach(store.filteredCMSFiles.filter { $0.fileType == .video || $0.fileType == .export }) { file in
                CMSVideoCard(file: file)
            }
        }
        .padding()
    }
}

struct StatBadge: View {
    var icon: String
    var label: String
    var value: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            Text(label)
                .foregroundStyle(.secondary)
            Text(value)
                .fontWeight(.medium)
        }
        .font(.caption)
    }
}

struct CMSFileCard: View {
    @EnvironmentObject private var store: StudioStore
    var file: CMSFileItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail/Icon
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.15))
                .frame(height: 100)
                .overlay {
                    Image(systemName: file.fileType.icon)
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                
                HStack {
                    Text(file.fileType.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                if let projectTitle = file.projectTitle {
                    Text(projectTitle)
                        .font(.caption2)
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                }
            }
        }
        .padding(8)
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contextMenu {
            Button { store.openCMSFile(file) } label: { Label("Open", systemImage: "play") }
            Button { store.revealCMSFile(file) } label: { Label("Show in Finder", systemImage: "folder") }
            Divider()
            Button(role: .destructive) { store.deleteCMSFile(file) } label: { Label("Delete", systemImage: "trash") }
        }
    }
}

struct CMSFileRow: View {
    @EnvironmentObject private var store: StudioStore
    var file: CMSFileItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: file.fileType.icon)
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.subheadline.weight(.medium))
                if let projectTitle = file.projectTitle {
                    Text(projectTitle)
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
            
            Spacer()
            
            Text(file.fileType.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Capsule())
            
            Text(ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .trailing)
            
            Text(file.modifiedAt, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .trailing)
            
            Button { store.revealCMSFile(file) } label: { Image(systemName: "folder") }
                .buttonStyle(.borderless)
            Button { store.openCMSFile(file) } label: { Image(systemName: "play") }
                .buttonStyle(.borderless)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.secondary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct CMSVideoCard: View {
    @EnvironmentObject private var store: StudioStore
    var file: CMSFileItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Video Preview Placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black)
                    .aspectRatio(16/9, contentMode: .fit)
                
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .onTapGesture {
                store.openCMSFile(file)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
                
                HStack {
                    if let projectTitle = file.projectTitle {
                        Text(projectTitle)
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                    Text(file.modifiedAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 4)
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
                        Text("No outputs yet. Open Transactions and Exports to render your first video bundle.")
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
                            Text("No rendered video exports found. Export a video from the Transactions and Exports section first.")
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

                            if youtube.isBusy, youtube.uploadProgress > 0 {
                                VStack(alignment: .leading, spacing: 4) {
                                    ProgressView(value: youtube.uploadProgress)
                                        .progressViewStyle(.linear)
                                    Text(String(format: "%.0f%% uploaded", youtube.uploadProgress * 100))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
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

                GroupBox("YouTube Browser + Live Preview") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            TextField("Search YouTube videos", text: $youtube.browserQuery)
                                .textFieldStyle(.roundedBorder)

                            Button("Search") {
                                youtube.searchBrowserVideos()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(youtube.isAuthenticated == false || youtube.isBusy)

                            if youtube.browserVideos.isEmpty == false {
                                Button("Clear") {
                                    youtube.browserVideos = []
                                    youtube.selectedPreviewVideoID = nil
                                }
                                .buttonStyle(.bordered)
                            }
                        }

                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Results")
                                    .font(.headline)

                                let videos = youtube.browserVideos.isEmpty ? youtube.recentVideos : youtube.browserVideos

                                if videos.isEmpty {
                                    Text("Search videos or load recent channel videos to preview in-app.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                } else {
                                    ScrollView {
                                        VStack(alignment: .leading, spacing: 8) {
                                            ForEach(videos) { video in
                                                Button {
                                                    youtube.selectPreviewVideo(video.id)
                                                } label: {
                                                    HStack(alignment: .top) {
                                                        VStack(alignment: .leading, spacing: 2) {
                                                            Text(video.title)
                                                                .font(.subheadline.weight(.semibold))
                                                                .foregroundStyle(.primary)
                                                                .multilineTextAlignment(.leading)
                                                            Text(video.id)
                                                                .font(.caption.monospaced())
                                                                .foregroundStyle(.secondary)
                                                        }
                                                        Spacer(minLength: 0)
                                                        if video.id == youtube.selectedPreviewVideo?.id {
                                                            Text("Preview")
                                                                .font(.caption.weight(.semibold))
                                                                .padding(.horizontal, 6)
                                                                .padding(.vertical, 3)
                                                                .background(Color.blue.opacity(0.16))
                                                                .clipShape(Capsule())
                                                        }
                                                    }
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .padding(8)
                                                    .background(Color.secondary.opacity(0.08))
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                    .frame(maxHeight: 220)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Player")
                                    .font(.headline)

                                if let selected = youtube.selectedPreviewVideo,
                                   let embedURL = youtube.embedURL(for: selected.id) {
                                    YouTubeEmbedPlayerView(url: embedURL)
                                        .frame(minHeight: 220)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))

                                    HStack(spacing: 8) {
                                        Button("Use in Project") {
                                            store.youtubeInput = selected.watchURL.absoluteString
                                            store.createProjectFromYouTubeLink()
                                            store.selectedSection = .projects
                                        }
                                        .buttonStyle(.borderedProminent)

                                        Button("Open on YouTube") {
                                            youtube.openVideo(selected)
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                } else {
                                    Text("Select a video from the results to preview it here.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                        .padding(.vertical, 28)
                                        .background(Color.secondary.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
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
    @State private var projectToDelete: UUID?

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

                                Spacer()

                                Button("Delete") {
                                    projectToDelete = project.id
                                }
                                .buttonStyle(.bordered)
                                .foregroundStyle(.red)
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
        .alert("Delete Project", isPresented: Binding(
            get: { projectToDelete != nil },
            set: { if !$0 { projectToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                projectToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let id = projectToDelete {
                    store.deleteProject(id)
                }
                projectToDelete = nil
            }
        } message: {
            Text("This will permanently remove the project and all its data. Exported files on disk will not be deleted.")
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
    @State private var emojiText: String = ""
    @State private var emojiPosition: EmojiPosition = .after
    @State private var selectedCaptionIDForEmoji: UUID?
    @State private var newLanguageCode: String = ""
    @State private var newLanguageName: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Caption and Subtitle Studio")
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
                    GroupBox("Word Highlight Mode") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Control how individual words are highlighted during caption playback.")
                                .font(.caption).foregroundStyle(.secondary)
                            Picker("Highlight", selection: store.proToolsBinding(for: \.captionHighlightMode, fallback: .none)) {
                                ForEach(CaptionHighlightMode.allCases) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    GroupBox("Caption Animation Style") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Choose how captions animate onto screen during playback and export.")
                                .font(.caption).foregroundStyle(.secondary)
                            Picker("Animation", selection: store.proToolsBinding(for: \.captionAnimation, fallback: .none)) {
                                ForEach(CaptionAnimation.allCases) { anim in
                                    Text(anim.rawValue).tag(anim)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    GroupBox("Emoji Auto-Insert") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Add emoji markers to specific captions for visual emphasis.")
                                .font(.caption).foregroundStyle(.secondary)
                            HStack {
                                Picker("Caption", selection: Binding(
                                    get: { selectedCaptionIDForEmoji ?? project.captions.first?.id ?? UUID() },
                                    set: { selectedCaptionIDForEmoji = $0 }
                                )) {
                                    ForEach(project.captions.prefix(30)) { cap in
                                        Text("\(timeString(cap.start)) \(cap.text.prefix(30))").tag(cap.id)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: 280)

                                TextField("Emoji", text: $emojiText)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 60)

                                Picker("Position", selection: $emojiPosition) {
                                    ForEach(EmojiPosition.allCases) { pos in
                                        Text(pos.rawValue).tag(pos)
                                    }
                                }
                                .pickerStyle(.menu)

                                Button("Add Emoji") {
                                    let captionID = selectedCaptionIDForEmoji ?? project.captions.first?.id ?? UUID()
                                    guard emojiText.isEmpty == false else { return }
                                    store.mutateActiveProjectPublic { proj in
                                        proj.proTools.emojiInserts.append(EmojiInsertPoint(
                                            id: UUID(),
                                            captionID: captionID,
                                            emoji: emojiText,
                                            position: emojiPosition
                                        ))
                                    }
                                    emojiText = ""
                                }
                                .buttonStyle(.bordered)
                            }

                            if let inserts = store.activeProject?.proTools.emojiInserts, !inserts.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(inserts) { insert in
                                        HStack {
                                            Text("\(insert.emoji) (\(insert.position.rawValue))")
                                                .font(.caption)
                                            Spacer()
                                            Button("Remove") {
                                                store.mutateActiveProjectPublic { proj in
                                                    proj.proTools.emojiInserts.removeAll { $0.id == insert.id }
                                                }
                                            }
                                            .buttonStyle(.bordered).controlSize(.small)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    GroupBox("Multi-Language Stubs") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Track localized caption versions for international distribution.")
                                .font(.caption).foregroundStyle(.secondary)
                            HStack {
                                TextField("Code (e.g. es)", text: $newLanguageCode)
                                    .textFieldStyle(.roundedBorder).frame(width: 80)
                                TextField("Language Name", text: $newLanguageName)
                                    .textFieldStyle(.roundedBorder).frame(width: 140)
                                Button("Add Language") {
                                    let code = newLanguageCode.trimmingCharacters(in: .whitespacesAndNewlines)
                                    let name = newLanguageName.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard !code.isEmpty, !name.isEmpty else { return }
                                    store.mutateActiveProjectPublic { proj in
                                        proj.proTools.languageStubs.append(LanguageStub(
                                            id: UUID(),
                                            languageCode: code,
                                            languageName: name,
                                            captionCount: proj.captions.count,
                                            exported: false
                                        ))
                                    }
                                    newLanguageCode = ""
                                    newLanguageName = ""
                                }
                                .buttonStyle(.bordered)
                            }

                            if let stubs = store.activeProject?.proTools.languageStubs, !stubs.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(stubs) { stub in
                                        HStack {
                                            Text("\(stub.languageName) (\(stub.languageCode))")
                                                .font(.caption.weight(.medium))
                                            Text("\(stub.captionCount) captions")
                                                .font(.caption).foregroundStyle(.secondary)
                                            Text(stub.exported ? "Exported" : "Pending")
                                                .font(.caption.weight(.semibold))
                                                .padding(.horizontal, 6).padding(.vertical, 2)
                                                .background((stub.exported ? Color.green : Color.orange).opacity(0.16))
                                                .clipShape(Capsule())
                                            Spacer()
                                            Button("Mark Exported") {
                                                store.mutateActiveProjectPublic { proj in
                                                    if let i = proj.proTools.languageStubs.firstIndex(where: { $0.id == stub.id }) {
                                                        proj.proTools.languageStubs[i].exported = true
                                                    }
                                                }
                                            }
                                            .buttonStyle(.bordered).controlSize(.small)
                                            .disabled(stub.exported)
                                            Button("Remove") {
                                                store.mutateActiveProjectPublic { proj in
                                                    proj.proTools.languageStubs.removeAll { $0.id == stub.id }
                                                }
                                            }
                                            .buttonStyle(.bordered).controlSize(.small)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    GroupBox("Power Words Emphasis") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Detect high-impact words in your captions for visual emphasis during render.")
                                .font(.caption).foregroundStyle(.secondary)

                            Button("Detect Power Words") {
                                store.detectPowerWords()
                            }
                            .buttonStyle(.borderedProminent)

                            if let words = store.activeProject?.proTools.powerWords, !words.isEmpty {
                                HStack(alignment: .top, spacing: 6) {
                                    ForEach(words.prefix(15)) { pw in
                                        VStack(spacing: 2) {
                                            Text(pw.word)
                                                .font(.caption.weight(.bold))
                                            Text(String(format: "%.0f%%", pw.weight * 100))
                                                .font(.caption2.monospacedDigit())
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(.horizontal, 8).padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.08 + pw.weight * 0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                }
                            }
                        }
                    }

                    GroupBox("Caption Preview") {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(project.captions.prefix(40)) { caption in
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
                                if caption.id != project.captions.prefix(40).last?.id {
                                    Divider()
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } else {
                    emptyProjectText
                }
            }
            .padding(22)
        }
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

                    // Download progress indicator
                    if store.isDownloading {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                ProgressView(value: store.downloadProgress)
                                    .progressViewStyle(.linear)
                                Text(String(format: "%.0f%%", store.downloadProgress * 100))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            HStack {
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Downloading 4K/1080p in background")
                                    .font(.caption)
                                if !store.downloadSpeed.isEmpty {
                                    Text("•")
                                    Text(store.downloadSpeed)
                                        .font(.caption)
                                }
                                if !store.downloadETA.isEmpty {
                                    Text("• ETA \(store.downloadETA)")
                                        .font(.caption)
                                }
                                Spacer()
                            }
                            .foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(Color.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    GroupBox("Preview Monitor") {
                        VStack(spacing: 10) {
                            // Show YouTube streaming OR local playback
                            if store.isStreamingYouTube, let videoID = store.streamingVideoID {
                                // STREAMING: Instant YouTube embed player
                                VStack(spacing: 6) {
                                    if let embedURL = URL(string: "https://www.youtube.com/embed/\(videoID)?autoplay=1&rel=0&modestbranding=1") {
                                        YouTubeEmbedPlayerView(url: embedURL)
                                            .aspectRatio(16/9, contentMode: .fit)
                                            .frame(minHeight: 400, maxHeight: 600)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    HStack {
                                        Image(systemName: "play.tv.fill")
                                            .foregroundStyle(.red)
                                        Text("Streaming from YouTube")
                                            .font(.caption.weight(.medium))
                                        if store.isDownloading {
                                            Text("• Local copy downloading...")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }
                                }
                            } else {
                                // LOCAL: Native AVPlayer for editing
                                NativeVideoPlayerView(player: player)
                                    .aspectRatio(16/9, contentMode: .fit)
                                    .frame(minHeight: 400, maxHeight: 600)
                                    .background(Color.black)
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
                                    
                                    if store.localCopyReady {
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                            Text("Local 4K/1080p")
                                                .font(.caption)
                                        }
                                    }
                                    
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
            if !store.isStreamingYouTube {
                reloadPreview(autoPlay: true)
            }
        }
        .onChange(of: store.activeProjectID) { _ in
            if !store.isStreamingYouTube {
                reloadPreview(autoPlay: true)
            }
        }
        .onChange(of: store.activeProject?.timelineVideoClips.count) { _ in
            if !store.isStreamingYouTube {
                reloadPreview()
            }
        }
        .onChange(of: store.localCopyReady) { ready in
            if ready {
                // Auto-reload when local copy becomes available
                reloadPreview(autoPlay: true)
            }
        }
        .onChange(of: store.isStreamingYouTube) { streaming in
            if !streaming {
                // Switch from streaming to local - reload preview
                reloadPreview(autoPlay: true)
            }
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
            allowedContentTypes: [.movie, .mpeg4Movie, .quickTimeMovie],
            allowsMultipleSelection: false
        ) { result in
            guard case .success(let urls) = result,
                  let url = urls.first else {
                return
            }
            let accessed = url.startAccessingSecurityScopedResource()
            let path = url.path
            Task { @MainActor in
                await store.importPrimaryVideo(filePath: path)
                if accessed { url.stopAccessingSecurityScopedResource() }
                reloadPreview()
            }
        }
        .fileImporter(
            isPresented: $secondaryVideoImporterPresented,
            allowedContentTypes: [.movie, .mpeg4Movie, .quickTimeMovie],
            allowsMultipleSelection: false
        ) { result in
            guard case .success(let urls) = result,
                  let url = urls.first else {
                return
            }
            let accessed = url.startAccessingSecurityScopedResource()
            let path = url.path
            Task { @MainActor in
                await store.importSecondaryVideo(filePath: path)
                if accessed { url.stopAccessingSecurityScopedResource() }
                reloadPreview()
            }
        }
        .fileImporter(
            isPresented: $audioImporterPresented,
            allowedContentTypes: [.audio, .mp3, .mpeg4Audio, .wav, .aiff],
            allowsMultipleSelection: false
        ) { result in
            guard case .success(let urls) = result,
                  let url = urls.first else {
                return
            }
            let accessed = url.startAccessingSecurityScopedResource()
            let path = url.path
            Task { @MainActor in
                await store.importTimelineAudio(filePath: path)
                if accessed { url.stopAccessingSecurityScopedResource() }
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
            allowedContentTypes: [.audio, .mp3, .mpeg4Audio, .wav, .aiff],
            allowsMultipleSelection: false
        ) { result in
            guard case .success(let urls) = result,
                  let selectedID = selectedVoiceOverID,
                  let url = urls.first else {
                return
            }
            let accessed = url.startAccessingSecurityScopedResource()
            store.attachVoiceOverAudio(selectedID, filePath: url.path)
            if accessed { url.stopAccessingSecurityScopedResource() }
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
    @State private var rampTimestamp: String = ""
    @State private var rampSpeed: String = "1.5"
    @State private var zoomStart: String = ""
    @State private var zoomEnd: String = ""
    @State private var zoomFactor: String = "1.5"

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

                    GroupBox("Speed Ramp Editor") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Add dynamic speed changes at specific timestamps.")
                                .font(.caption).foregroundStyle(.secondary)
                            HStack {
                                TextField("Timestamp (s)", text: $rampTimestamp)
                                    .textFieldStyle(.roundedBorder).frame(width: 120)
                                TextField("Target Speed", text: $rampSpeed)
                                    .textFieldStyle(.roundedBorder).frame(width: 120)
                                Button("Add Ramp Point") {
                                    if let t = Double(rampTimestamp), let s = Double(rampSpeed) {
                                        store.addSpeedRampPoint(at: t, speed: s)
                                        rampTimestamp = ""
                                    }
                                }.buttonStyle(.bordered)
                            }
                            if let pts = store.activeProject?.proTools.speedRampPoints, !pts.isEmpty {
                                ForEach(pts) { pt in
                                    HStack {
                                        Text(String(format: "%.1fs -> %.2fx (ramp %.1fs)", pt.timestamp, pt.targetSpeed, pt.rampDuration))
                                            .font(.caption.monospacedDigit())
                                        Spacer()
                                        Button("Remove") { store.removeSpeedRampPoint(pt.id) }
                                            .buttonStyle(.bordered).controlSize(.small)
                                    }
                                }
                            }
                        }
                    }

                    GroupBox("Auto-Zoom Regions") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Define zoom-in points on your timeline for emphasis.")
                                .font(.caption).foregroundStyle(.secondary)
                            HStack {
                                TextField("Start (s)", text: $zoomStart)
                                    .textFieldStyle(.roundedBorder).frame(width: 100)
                                TextField("End (s)", text: $zoomEnd)
                                    .textFieldStyle(.roundedBorder).frame(width: 100)
                                TextField("Zoom Factor", text: $zoomFactor)
                                    .textFieldStyle(.roundedBorder).frame(width: 100)
                                Button("Add Zoom") {
                                    if let s = Double(zoomStart), let e = Double(zoomEnd), let f = Double(zoomFactor) {
                                        store.addZoomRegion(start: s, end: e, factor: f)
                                        zoomStart = ""; zoomEnd = ""
                                    }
                                }.buttonStyle(.bordered)
                            }
                            if let regions = store.activeProject?.proTools.zoomRegions, !regions.isEmpty {
                                ForEach(regions) { r in
                                    HStack {
                                        Text(String(format: "%.1fs - %.1fs @ %.1fx", r.start, r.end, r.zoomFactor))
                                            .font(.caption.monospacedDigit())
                                        Spacer()
                                        Button("Remove") { store.removeZoomRegion(r.id) }
                                            .buttonStyle(.bordered).controlSize(.small)
                                    }
                                }
                            }
                        }
                    }

                    GroupBox("Ken Burns Motion") {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Enable Ken Burns", isOn: store.proToolsBinding(for: \.kenBurns.enabled, fallback: false))
                            HStack {
                                Picker("Pan Direction", selection: store.proToolsBinding(for: \.kenBurns.panDirection, fallback: .leftToRight)) {
                                    ForEach(PanDirection.allCases) { d in Text(d.rawValue).tag(d) }
                                }
                            }
                        }
                    }

                    GroupBox("Picture-in-Picture") {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Enable PiP", isOn: store.proToolsBinding(for: \.pip.enabled, fallback: false))
                            if store.activeProject?.proTools.pip.enabled == true {
                                Picker("Position", selection: store.proToolsBinding(for: \.pip.position, fallback: .bottomRight)) {
                                    ForEach(PiPPosition.allCases) { p in Text(p.rawValue).tag(p) }
                                }
                            }
                        }
                    }

                    GroupBox("Split Screen") {
                        Picker("Layout", selection: store.proToolsBinding(for: \.splitScreen, fallback: .none)) {
                            ForEach(SplitScreenLayout.allCases) { l in Text(l.rawValue).tag(l) }
                        }
                    }

                    GroupBox("Color Grade") {
                        Picker("Preset", selection: store.proToolsBinding(for: \.colorGrade, fallback: .none)) {
                            ForEach(ColorGradePreset.allCases) { c in Text(c.rawValue).tag(c) }
                        }
                    }

                    GroupBox("Platform Safe Zones") {
                        Text("Safe zone guides overlay on export preview per platform crop.")
                            .font(.caption).foregroundStyle(.secondary)
                        HStack(spacing: 12) {
                            ForEach(ExportPlatform.allCases) { platform in
                                VStack {
                                    Text(platform.rawValue).font(.caption.weight(.medium))
                                    Text(safeZoneLabel(for: platform)).font(.caption2).foregroundStyle(.secondary)
                                }
                                .padding(8)
                                .background(Color.secondary.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
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

    private func safeZoneLabel(for platform: ExportPlatform) -> String {
        switch platform {
        case .youtubeShorts: return "Top 15% / Bottom 25% unsafe"
        case .tiktok: return "Top 10% / Bottom 30% unsafe"
        case .instagramReels: return "Top 12% / Bottom 20% unsafe"
        case .x: return "Full frame safe"
        case .linkedin: return "Full frame safe"
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
                VStack(alignment: .leading, spacing: 10) {
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

                    if store.isExporting {
                        ProgressView()
                            .progressViewStyle(.linear)
                    }
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

struct NativeVideoPlayerView: NSViewRepresentable {
    var player: AVPlayer

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .floating
        view.showsFullScreenToggleButton = true
        view.videoGravity = .resizeAspect
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        if nsView.player !== player {
            nsView.player = player
        }
    }
}

struct YouTubeEmbedPlayerView: NSViewRepresentable {
    var url: URL

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.setValue(false, forKey: "drawsBackground")
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        if nsView.url != url {
            nsView.load(URLRequest(url: url))
        }
    }
}
