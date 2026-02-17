import AppKit
import AVFoundation
import Foundation
import SwiftUI

@MainActor
final class StudioStore: ObservableObject {
    @Published var selectedSection: StudioSection = .dashboard
    @Published var youtubeInput: String = ""
    @Published var selectedCaptionStyle: CaptionStyle = .cinematic
    @Published var exportPreset: ExportPreset = .default
    @Published var projects: [StudioProject] = []
    @Published var activeProjectID: UUID?
    @Published var isExporting: Bool = false
    @Published var statusMessage: String = "Paste a YouTube link to start a Cliper Tube project."
    @Published var lastError: String?

    // Download automation state
    @Published var isDownloading: Bool = false
    @Published var downloadProgress: Double = 0
    @Published var downloadSpeed: String = ""
    @Published var downloadETA: String = ""
    @Published var ytdlpAvailable: Bool = VideoDownloader.isYtdlpInstalled()
    @Published var selectedDownloadQuality: VideoQuality = .best
    
    // Streaming state - instant playback while downloading
    @Published var isStreamingYouTube: Bool = false
    @Published var streamingVideoID: String?
    @Published var localCopyReady: Bool = false
    
    // App Mode state - Easy Mode vs Pro Mode
    @Published var appMode: AppMode = .easy
    @Published var easyModeState: EasyModeState = EasyModeState()
    @Published var easyModeURL: String = ""
    
    // CMS / File Management state
    @Published var cmsFiles: [CMSFileItem] = []
    @Published var cmsSelectedFileID: UUID?
    @Published var cmsSortOption: CMSSortOption = .dateNewest
    @Published var cmsViewMode: CMSViewMode = .grid
    @Published var cmsFilterType: CMSFileType?
    @Published var cmsSearchQuery: String = ""
    @Published var cmsStats: CMSStats = CMSStats()

    private let persistence = ProjectPersistence()
    private let fileManager = FileManager.default

    private struct VideoSourceInput {
        var sourceURL: URL
        var persistedPath: String
        var label: String
    }

    init() {
        loadWorkspace()
        scanCMSFiles()
    }

    var activeProject: StudioProject? {
        guard let activeProjectID else {
            return preferredActiveProject
        }
        return projects.first(where: { $0.id == activeProjectID }) ?? preferredActiveProject
    }

    var activeProjectMediaSources: [MediaSource] {
        activeProject?.mediaSources ?? []
    }

    var activePrimaryMediaSourceID: UUID? {
        activeProject?.primaryMediaSourceID
    }

    var activeTimelineDuration: TimeInterval {
        timelineDuration(for: activeProject)
    }

    var sortedProjects: [StudioProject] {
        projects.sorted { lhs, rhs in
            if lhs.status.sortOrder != rhs.status.sortOrder {
                return lhs.status.sortOrder < rhs.status.sortOrder
            }
            return lhs.updatedAt > rhs.updatedAt
        }
    }

    var currentProjects: [StudioProject] {
        sortedProjects.filter { $0.status == .current }
    }

    var workingProjects: [StudioProject] {
        sortedProjects.filter { $0.status == .working }
    }

    var pastProjects: [StudioProject] {
        sortedProjects.filter { $0.status == .past }
    }

    var outputHistory: [ProjectOutputItem] {
        projects
            .flatMap { project in
                project.exports.map { export in
                    ProjectOutputItem(
                        projectID: project.id,
                        projectTitle: project.title,
                        projectStatus: project.status,
                        export: export
                    )
                }
            }
            .sorted { $0.export.date > $1.export.date }
    }

    var metrics: StudioMetrics {
        guard let project = activeProject else {
            return StudioMetrics(clipCount: 0, averageConfidence: 0, captionCount: 0, transactionTotal: 0)
        }

        let confidence = project.clips.isEmpty ? 0 : project.clips.map(\.confidence).reduce(0, +) / Double(project.clips.count)
        let total = project.transactions.reduce(0) { $0 + $1.amount }

        return StudioMetrics(
            clipCount: project.clips.count,
            averageConfidence: confidence,
            captionCount: project.captions.count,
            transactionTotal: total
        )
    }

    func createProjectFromYouTubeLink() {
        let trimmed = youtubeInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            lastError = "Enter a YouTube URL or video ID."
            return
        }

        // Auto-download flow for YouTube URLs
        if let videoID = YouTubeParser.extractID(from: trimmed) {
            // Check if yt-dlp is available for automatic download
            if ytdlpAvailable {
                startAutomatedDownload(url: trimmed, videoID: videoID)
                return
            }
            
            // Fallback: create project without download
            let project = makeProject(videoID: videoID, sourceInput: trimmed, titlePrefix: "Cliper Project \(videoID)")
            demoteCurrentProjects(excluding: project.id)
            projects.insert(project, at: 0)
            activeProjectID = project.id
            statusMessage = "Project created for video ID: \(videoID). Install yt-dlp for auto-download, or import a local video."
            persistWorkspace()
            return
        }

        guard let source = resolveVideoSourceInput(from: trimmed) else {
            if lastError == nil {
                lastError = "Input is not a valid YouTube ID/URL or direct video source."
            }
            return
        }

        let syntheticID = syntheticVideoID(from: source.persistedPath)
        let project = makeProject(
            videoID: syntheticID,
            sourceInput: trimmed,
            titlePrefix: "Cliper Project \(source.label)"
        )

        demoteCurrentProjects(excluding: project.id)
        projects.insert(project, at: 0)
        activeProjectID = project.id
        selectedSection = .timeline
        statusMessage = "Project created from source URL. Importing media into timeline..."
        persistWorkspace()

        Task { @MainActor in
            await importPrimaryVideo(into: project.id, filePath: source.persistedPath)
            if activeProjectID == project.id,
               activeProject?.timelineVideoClips.isEmpty == false {
                statusMessage = "Project ready. Timeline playback is loaded."
            }
        }
    }

    /// Automated download + project creation + import pipeline
    /// NOW: Instant streaming first, background 4K/1080p download
    func startAutomatedDownload(url: String, videoID: String) {
        guard !isDownloading else {
            lastError = "A download is already in progress."
            return
        }
        
        // INSTANT: Start streaming immediately
        streamingVideoID = videoID
        isStreamingYouTube = true
        localCopyReady = false
        
        // Create project immediately
        let project = makeProject(
            videoID: videoID,
            sourceInput: url,
            titlePrefix: "Cliper Project \(videoID)"
        )
        demoteCurrentProjects(excluding: project.id)
        projects.insert(project, at: 0)
        activeProjectID = project.id
        persistWorkspace()
        
        // Navigate to timeline immediately for streaming playback
        selectedSection = .timeline
        statusMessage = "▶ Streaming from YouTube • Downloading 4K/1080p in background..."
        
        // Start background download
        isDownloading = true
        downloadProgress = 0
        downloadSpeed = ""
        downloadETA = ""
        
        let projectID = project.id
        
        Task { @MainActor in
            do {
                // Fetch metadata for better title
                let metadata = try await VideoDownloader.fetchMetadata(url: url)
                
                // Update project title
                mutateProject(withID: projectID) { proj in
                    proj.title = metadata.title
                }
                persistWorkspace()
                
                statusMessage = "▶ Streaming • Downloading: \(metadata.title)..."
                
                // Download best quality (4K/1080p) in background
                let result = try await VideoDownloader.download(
                    url: url,
                    quality: .best  // Always download best quality
                ) { [weak self] progress in
                    Task { @MainActor in
                        self?.downloadProgress = progress.percent / 100.0
                        self?.downloadSpeed = progress.speed
                        self?.downloadETA = progress.eta
                        self?.statusMessage = String(format: "▶ Streaming • Download %.0f%% - %@ - ETA %@", progress.percent, progress.speed, progress.eta)
                    }
                }
                
                // Import the downloaded video into the project
                statusMessage = "Download complete! Importing to timeline..."
                await importPrimaryVideo(into: projectID, filePath: result.videoPath)
                
                // Switch from streaming to local playback
                isStreamingYouTube = false
                streamingVideoID = nil
                localCopyReady = true
                isDownloading = false
                downloadProgress = 0
                statusMessage = "✓ Local 4K/1080p ready: \(result.title)"
                persistWorkspace()
                
            } catch {
                isDownloading = false
                downloadProgress = 0
                // Keep streaming even if download failed
                statusMessage = "⚠ Download failed - streaming only. \(error.localizedDescription)"
            }
        }
    }
    
    /// Cancel an ongoing download
    func cancelDownload() {
        // Note: Process cancellation would need task tracking - for now just reset state
        isDownloading = false
        downloadProgress = 0
        downloadSpeed = ""
        downloadETA = ""
        statusMessage = "Download cancelled."
    }
    
    /// Re-check yt-dlp availability
    func refreshYtdlpStatus() {
        ytdlpAvailable = VideoDownloader.isYtdlpInstalled()
        if ytdlpAvailable {
            statusMessage = "yt-dlp detected. Automatic YouTube downloads enabled."
        } else {
            statusMessage = "yt-dlp not found. Install via: brew install yt-dlp"
        }
    }

    func selectProject(_ projectID: UUID) {
        guard let project = projects.first(where: { $0.id == projectID }) else {
            lastError = "Project not found."
            return
        }

        activeProjectID = projectID
        youtubeInput = project.youtubeURL
        selectedCaptionStyle = project.captions.first?.style ?? .cinematic
        statusMessage = "Opened project: \(project.title)."
        persistWorkspace()
    }

    func setProjectStatus(_ projectID: UUID, status: ProjectStatus) {
        guard let index = projects.firstIndex(where: { $0.id == projectID }) else {
            lastError = "Project not found."
            return
        }

        if status == .current {
            demoteCurrentProjects(excluding: projectID)
            activeProjectID = projectID
        }

        projects[index].status = status
        projects[index].updatedAt = Date()

        if status == .past && activeProjectID == projectID {
            activeProjectID = preferredActiveProject?.id
        }

        statusMessage = "\(projects[index].title) marked as \(status.label)."
        persistWorkspace()
    }

    func deleteProject(_ projectID: UUID) {
        guard let index = projects.firstIndex(where: { $0.id == projectID }) else {
            lastError = "Project not found."
            return
        }

        let title = projects[index].title
        projects.remove(at: index)

        if activeProjectID == projectID {
            activeProjectID = preferredActiveProject?.id
        }

        statusMessage = "Deleted project: \(title)."
        persistWorkspace()
    }

    func runAutoClipAndStitch(maxClips: Int = 6) {
        mutateActiveProject { project in
            project.clips = ClipEngine.autoStitch(from: project.transcriptSegments, maxClips: maxClips)
            project.voiceOvers = VoiceOverPlanner.plan(for: project.clips)

            if let primarySource = primaryMediaSource(for: project) {
                project.timelineVideoClips = makeTimelineFromAutoClips(project: project, primarySource: primarySource)
                recalculateTimelineVideoStarts(&project)
            }
        }
        statusMessage = "Auto Clip + Stitch refreshed."
    }

    func regenerateCaptions() {
        mutateActiveProject { project in
            project.captions = CaptionEngine.generate(from: project.transcriptSegments, style: selectedCaptionStyle)
        }
        statusMessage = "Captions regenerated with style: \(selectedCaptionStyle.label)."
    }

    func moveClip(_ clipID: UUID, direction: Int) {
        mutateActiveProject { project in
            guard let index = project.clips.firstIndex(where: { $0.id == clipID }) else { return }
            let target = index + direction
            guard target >= 0 && target < project.clips.count else { return }
            project.clips.swapAt(index, target)
        }
    }

    func updateVoiceOverNote(_ segmentID: UUID, note: String) {
        mutateActiveProject { project in
            guard let index = project.voiceOvers.firstIndex(where: { $0.id == segmentID }) else { return }
            project.voiceOvers[index].note = note
        }
    }

    func attachVoiceOverAudio(_ segmentID: UUID, filePath: String) {
        mutateActiveProject { project in
            guard let index = project.voiceOvers.firstIndex(where: { $0.id == segmentID }) else { return }
            project.voiceOvers[index].audioFilePath = filePath
        }
        statusMessage = "Voice over attached."
    }

    func importPrimaryVideo(filePath: String) async {
        await importVideoAsync(filePath: filePath, makePrimary: true)
    }

    func importSecondaryVideo(filePath: String) async {
        await importVideoAsync(filePath: filePath, makePrimary: false)
    }

    func importPrimaryVideo(into projectID: UUID, filePath: String) async {
        await importVideoAsync(filePath: filePath, makePrimary: true, projectID: projectID)
    }

    func setPrimaryMediaSource(_ sourceID: UUID) {
        mutateActiveProject { project in
            guard project.mediaSources.contains(where: { $0.id == sourceID }) else { return }
            project.primaryMediaSourceID = sourceID

            if project.timelineVideoClips.isEmpty,
               let source = project.mediaSources.first(where: { $0.id == sourceID }) {
                project.timelineVideoClips = [makeFullTimelineClip(from: source, label: "Primary Full Clip")]
                recalculateTimelineVideoStarts(&project)
            }
        }
        statusMessage = "Primary source updated."
    }

    func buildTimelineFromAutoClips() {
        mutateActiveProject { project in
            guard let source = primaryMediaSource(for: project) else { return }
            project.timelineVideoClips = makeTimelineFromAutoClips(project: project, primarySource: source)
            recalculateTimelineVideoStarts(&project)
        }

        if activeProject?.primaryMediaSourceID == nil {
            lastError = "Import a source video first."
        } else {
            statusMessage = "Timeline generated from AI clip suggestions."
        }
    }

    func addFullPrimaryClip() {
        mutateActiveProject { project in
            guard let source = primaryMediaSource(for: project) else { return }
            project.timelineVideoClips.append(makeFullTimelineClip(from: source, label: "Manual Full Clip"))
            recalculateTimelineVideoStarts(&project)
        }

        if activeProject?.primaryMediaSourceID == nil {
            lastError = "Import a primary video first."
        }
    }

    func moveTimelineVideoClip(_ clipID: UUID, direction: Int) {
        mutateActiveProject { project in
            guard let index = project.timelineVideoClips.firstIndex(where: { $0.id == clipID }) else { return }
            let target = index + direction
            guard target >= 0 && target < project.timelineVideoClips.count else { return }
            project.timelineVideoClips.swapAt(index, target)
            recalculateTimelineVideoStarts(&project)
        }
    }

    func removeTimelineVideoClip(_ clipID: UUID) {
        mutateActiveProject { project in
            project.timelineVideoClips.removeAll(where: { $0.id == clipID })
            recalculateTimelineVideoStarts(&project)
        }
    }

    func nudgeTimelineVideoInPoint(_ clipID: UUID, delta: TimeInterval) {
        mutateActiveProject { project in
            guard let index = project.timelineVideoClips.firstIndex(where: { $0.id == clipID }) else { return }
            let sourceDuration = sourceDuration(for: project.timelineVideoClips[index].sourceID, in: project)
            guard sourceDuration > 0 else { return }

            let outPoint = project.timelineVideoClips[index].outPoint
            let maxIn = max(0, outPoint - 0.1)
            let newIn = clamp(project.timelineVideoClips[index].inPoint + delta, lower: 0, upper: maxIn)
            project.timelineVideoClips[index].inPoint = newIn
            recalculateTimelineVideoStarts(&project)
        }
    }

    func nudgeTimelineVideoOutPoint(_ clipID: UUID, delta: TimeInterval) {
        mutateActiveProject { project in
            guard let index = project.timelineVideoClips.firstIndex(where: { $0.id == clipID }) else { return }
            let sourceDuration = sourceDuration(for: project.timelineVideoClips[index].sourceID, in: project)
            guard sourceDuration > 0 else { return }

            let inPoint = project.timelineVideoClips[index].inPoint
            let minOut = inPoint + 0.1
            let newOut = clamp(project.timelineVideoClips[index].outPoint + delta, lower: minOut, upper: sourceDuration)
            project.timelineVideoClips[index].outPoint = newOut
            recalculateTimelineVideoStarts(&project)
        }
    }

    func adjustTimelineVideoSpeed(_ clipID: UUID, delta: Double) {
        mutateActiveProject { project in
            guard let index = project.timelineVideoClips.firstIndex(where: { $0.id == clipID }) else { return }
            let updated = clamp(project.timelineVideoClips[index].playbackRate + delta, lower: 0.25, upper: 3.0)
            project.timelineVideoClips[index].playbackRate = updated
            recalculateTimelineVideoStarts(&project)
        }
    }

    func toggleTimelineVideoMute(_ clipID: UUID) {
        mutateActiveProject { project in
            guard let index = project.timelineVideoClips.firstIndex(where: { $0.id == clipID }) else { return }
            project.timelineVideoClips[index].muted.toggle()
        }
    }

    func importTimelineAudio(filePath: String) async {
        await importTimelineAudioAsync(filePath: filePath)
    }

    private func importTimelineAudioAsync(filePath: String) async {
        let cleanPath = filePath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanPath.isEmpty == false else {
            lastError = "Audio file path cannot be empty."
            return
        }

        let fileURL = URL(fileURLWithPath: cleanPath)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            lastError = "Audio file does not exist: \(cleanPath)"
            return
        }

        let asset = AVURLAsset(url: fileURL)
        let duration: TimeInterval
        do {
            let audioTracks = try await asset.loadTracks(withMediaType: .audio)
            guard audioTracks.isEmpty == false else {
                lastError = "Selected file has no audio track."
                return
            }

            duration = safeSeconds(try await asset.load(.duration))
            guard duration > 0 else {
                lastError = "Could not read audio duration."
                return
            }
        } catch {
            lastError = "Failed to read audio file: \(error.localizedDescription)"
            return
        }

        mutateActiveProject { project in
            project.timelineAudioClips.append(
                TimelineAudioClip(
                    id: UUID(),
                    label: fileURL.lastPathComponent,
                    filePath: cleanPath,
                    inPoint: 0,
                    outPoint: duration,
                    volume: 1.0,
                    timelineStart: 0
                )
            )
        }

        statusMessage = "Added audio track: \(fileURL.lastPathComponent)."
    }

    func nudgeTimelineAudioStart(_ clipID: UUID, delta: TimeInterval) {
        mutateActiveProject { project in
            guard let index = project.timelineAudioClips.firstIndex(where: { $0.id == clipID }) else { return }
            project.timelineAudioClips[index].timelineStart = max(0, project.timelineAudioClips[index].timelineStart + delta)
        }
    }

    func setTimelineAudioVolume(_ clipID: UUID, value: Double) {
        mutateActiveProject { project in
            guard let index = project.timelineAudioClips.firstIndex(where: { $0.id == clipID }) else { return }
            project.timelineAudioClips[index].volume = clamp(value, lower: 0, upper: 2.0)
        }
    }

    func removeTimelineAudioClip(_ clipID: UUID) {
        mutateActiveProject { project in
            project.timelineAudioClips.removeAll(where: { $0.id == clipID })
        }
    }

    func makeTimelinePreviewItem() async -> AVPlayerItem? {
        guard let project = activeProject else { return nil }
        guard project.timelineVideoClips.isEmpty == false else { return nil }

        do {
            let result = try await TimelineComposer.build(project: project)
            let item = AVPlayerItem(asset: result.composition)
            item.audioMix = result.audioMix
            item.videoComposition = result.videoComposition
            return item
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }

    func editorBinding<T>(for keyPath: WritableKeyPath<EditorSettings, T>, fallback: T) -> Binding<T> {
        Binding(
            get: { self.activeProject?.editor[keyPath: keyPath] ?? fallback },
            set: { newValue in
                self.mutateActiveProject { project in
                    project.editor[keyPath: keyPath] = newValue
                }
            }
        )
    }

    func toggleBenchmark(_ featureID: UUID, implemented: Bool) {
        mutateActiveProject { project in
            guard let index = project.benchmarkCoverage.firstIndex(where: { $0.id == featureID }) else { return }
            project.benchmarkCoverage[index].implemented = implemented
        }
    }

    func addTransaction(type: TransactionType, amount: Double, description: String) {
        guard amount >= 0 else {
            lastError = "Amount must be positive."
            return
        }

        let cleanDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanDescription.isEmpty else {
            lastError = "Transaction description is required."
            return
        }

        mutateActiveProject { project in
            project.transactions.insert(
                TransactionRecord(
                    id: UUID(),
                    date: Date(),
                    type: type,
                    status: .completed,
                    amount: amount,
                    currency: "USD",
                    description: cleanDescription
                ),
                at: 0
            )
        }
    }

    func exportCurrentProject() {
        guard isExporting == false else {
            lastError = "An export is already running."
            return
        }
        Task {
            await performExportCurrentProject()
        }
    }

    func revealOutput(path: String) {
        let url = URL(fileURLWithPath: path)
        guard fileManager.fileExists(atPath: url.path) else {
            lastError = "Output path not found: \(path)"
            return
        }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func revealLatestOutput(for projectID: UUID) {
        guard let project = projects.first(where: { $0.id == projectID }) else {
            lastError = "Project not found."
            return
        }
        guard let latest = project.exports.sorted(by: { $0.date > $1.date }).first else {
            lastError = "No outputs available for this project yet."
            return
        }
        revealOutput(path: latest.outputPath)
    }

    func availableVideoExports() -> [ExportVideoCandidate] {
        outputHistory.compactMap { item in
            guard let filePath = resolveVideoFilePath(from: item.export.outputPath) else {
                return nil
            }

            return ExportVideoCandidate(
                id: item.export.id,
                projectTitle: item.projectTitle,
                exportDate: item.export.date,
                filePath: filePath,
                displayName: "\(item.projectTitle) · \(URL(fileURLWithPath: filePath).lastPathComponent)"
            )
        }
    }

    func clearError() {
        lastError = nil
    }

    // MARK: - Pro Tools Methods

    func runViralAnalysis() {
        mutateActiveProject { project in
            project.proTools.viralScoreReports = ViralScoreEngine.analyze(clips: project.clips, transcript: project.transcriptSegments)
        }
        statusMessage = "Viral score analysis complete."
    }

    func runHookAnalysis() {
        mutateActiveProject { project in
            project.proTools.hookAnalyses = HookAnalyzer.analyze(clips: project.clips)
        }
        statusMessage = "Hook strength analysis complete."
    }

    func runTrendingMatch() {
        mutateActiveProject { project in
            project.proTools.trendingMatches = TrendingMatcher.match(transcript: project.transcriptSegments)
        }
        statusMessage = "Trending keyword scan complete."
    }

    func runRetentionEstimate() {
        mutateActiveProject { project in
            let duration = project.timelineVideoClips.map(\.timelineEnd).max() ?? project.clips.map(\.end).max() ?? 60
            project.proTools.retentionCurve = RetentionEstimator.estimate(clips: project.clips, totalDuration: duration)
        }
        statusMessage = "Retention curve estimated."
    }

    func runABHookGeneration() {
        mutateActiveProject { project in
            project.proTools.abHookVariants = ABHookGenerator.generate(clips: project.clips)
        }
        statusMessage = "A/B hook variants generated."
    }

    func runOptimalLengthCalc() {
        guard let project = activeProject else {
            lastError = "Open a project first."
            return
        }
        let duration = project.timelineVideoClips.map(\.timelineEnd).max() ?? project.clips.map(\.end).max() ?? 0
        mutateActiveProject { project in
            project.proTools.platformLengthRecs = OptimalLengthCalculator.calculate(currentDuration: duration)
        }
        statusMessage = "Platform length recommendations ready."
    }

    func runEngagementMapping() {
        mutateActiveProject { project in
            let duration = project.timelineVideoClips.map(\.timelineEnd).max() ?? project.clips.map(\.end).max() ?? 60
            project.proTools.engagementZones = EngagementMapper.map(clips: project.clips, totalDuration: duration)
        }
        statusMessage = "Engagement heatmap generated."
    }

    func duplicateProjectForReClip() {
        guard let source = activeProject else {
            lastError = "Open a project first."
            return
        }
        var copy = source
        copy.id = UUID()
        copy.title = "\(source.title) (Re-Clip)"
        copy.createdAt = Date()
        copy.updatedAt = Date()
        copy.status = .working
        copy.exports = []
        copy.proTools = .default
        projects.insert(copy, at: 0)
        persistWorkspace()
        statusMessage = "Re-clip project created: \(copy.title)."
    }

    func detectPowerWords() {
        mutateActiveProject { project in
            project.proTools.powerWords = PowerWordDetector.detect(captions: project.captions)
        }
        statusMessage = "Power words detected."
    }

    func runVoiceActivityDetection() {
        mutateActiveProject { project in
            let duration = project.timelineVideoClips.map(\.timelineEnd).max() ?? project.clips.map(\.end).max() ?? 60
            project.proTools.voiceActivitySegments = VoiceActivityDetector.detect(transcript: project.transcriptSegments, totalDuration: duration)
        }
        statusMessage = "Voice activity segments detected."
    }

    func addSFXTrigger(at timestamp: TimeInterval, type: SFXType) {
        mutateActiveProject { project in
            project.proTools.sfxTriggers.append(SFXTrigger(
                id: UUID(),
                timestamp: timestamp,
                sfxType: type,
                volume: 0.8,
                label: type.rawValue
            ))
            project.proTools.sfxTriggers.sort { $0.timestamp < $1.timestamp }
        }
        statusMessage = "SFX trigger added."
    }

    func removeSFXTrigger(_ triggerID: UUID) {
        mutateActiveProject { project in
            project.proTools.sfxTriggers.removeAll { $0.id == triggerID }
        }
    }

    func addZoomRegion(start: TimeInterval, end: TimeInterval, factor: Double) {
        mutateActiveProject { project in
            project.proTools.zoomRegions.append(ZoomRegion(
                id: UUID(),
                start: start,
                end: end,
                zoomFactor: factor,
                focusX: 0.5,
                focusY: 0.5
            ))
        }
        statusMessage = "Zoom region added."
    }

    func removeZoomRegion(_ regionID: UUID) {
        mutateActiveProject { project in
            project.proTools.zoomRegions.removeAll { $0.id == regionID }
        }
    }

    func addSpeedRampPoint(at timestamp: TimeInterval, speed: Double) {
        mutateActiveProject { project in
            project.proTools.speedRampPoints.append(SpeedRampPoint(
                id: UUID(),
                timestamp: timestamp,
                targetSpeed: speed,
                rampDuration: 0.5
            ))
            project.proTools.speedRampPoints.sort { $0.timestamp < $1.timestamp }
        }
        statusMessage = "Speed ramp point added."
    }

    func removeSpeedRampPoint(_ pointID: UUID) {
        mutateActiveProject { project in
            project.proTools.speedRampPoints.removeAll { $0.id == pointID }
        }
    }

    func generateSocialCopy() {
        guard let project = activeProject else {
            lastError = "Open a project first."
            return
        }
        mutateActiveProject { proj in
            proj.proTools.socialCopies = SocialCopyGenerator.generate(project: project)
        }
        statusMessage = "Social copy generated for all platforms."
    }

    func addThumbnailCandidate(at timestamp: TimeInterval) {
        mutateActiveProject { project in
            project.proTools.thumbnailCandidates.append(ThumbnailCandidate(
                id: UUID(),
                timestamp: timestamp,
                label: "Frame at \(Int(timestamp))s",
                isSelected: project.proTools.thumbnailCandidates.isEmpty
            ))
        }
        statusMessage = "Thumbnail candidate added."
    }

    func selectThumbnailCandidate(_ candidateID: UUID) {
        mutateActiveProject { project in
            for i in project.proTools.thumbnailCandidates.indices {
                project.proTools.thumbnailCandidates[i].isSelected = (project.proTools.thumbnailCandidates[i].id == candidateID)
            }
        }
    }

    func addBatchExportItem(platform: ExportPlatform, quality: RenderQuality, aspect: AspectRatio) {
        mutateActiveProject { project in
            project.proTools.batchExportQueue.append(BatchExportItem(
                id: UUID(),
                platform: platform,
                quality: quality,
                aspectRatio: aspect,
                includeCaptions: true,
                status: .queued
            ))
        }
        statusMessage = "Added \(platform.rawValue) to batch export queue."
    }

    func removeBatchExportItem(_ itemID: UUID) {
        mutateActiveProject { project in
            project.proTools.batchExportQueue.removeAll { $0.id == itemID }
        }
    }

    func saveExportTemplate(name: String) {
        guard let project = activeProject else { return }
        mutateActiveProject { proj in
            proj.proTools.exportTemplates.append(ExportTemplate(
                id: UUID(),
                name: name,
                preset: exportPreset,
                editorSnapshot: project.editor,
                createdAt: Date()
            ))
        }
        statusMessage = "Export template '\(name)' saved."
    }

    func addScheduleEntry(platform: ExportPlatform, date: Date, title: String) {
        mutateActiveProject { project in
            project.proTools.publishSchedule.append(PublishScheduleEntry(
                id: UUID(),
                platform: platform,
                scheduledDate: date,
                title: title,
                status: .planned,
                notes: ""
            ))
            project.proTools.publishSchedule.sort { $0.scheduledDate < $1.scheduledDate }
        }
        statusMessage = "Schedule entry added."
    }

    func updateScheduleStatus(_ entryID: UUID, status: PublishStatus) {
        mutateActiveProject { project in
            guard let i = project.proTools.publishSchedule.firstIndex(where: { $0.id == entryID }) else { return }
            project.proTools.publishSchedule[i].status = status
        }
    }

    func addClipRevenue(clipTitle: String, platform: ExportPlatform, views: Int, revenue: Double) {
        mutateActiveProject { project in
            project.proTools.clipRevenue.insert(ClipRevenueEntry(
                id: UUID(),
                clipTitle: clipTitle,
                platform: platform,
                views: views,
                revenue: revenue,
                currency: "USD",
                recordedAt: Date()
            ), at: 0)
        }
        statusMessage = "Revenue entry recorded."
    }

    func addCostEntry(category: CostCategory, amount: Double, description: String) {
        mutateActiveProject { project in
            project.proTools.costs.insert(CostEntry(
                id: UUID(),
                category: category,
                amount: amount,
                currency: "USD",
                description: description,
                date: Date()
            ), at: 0)
        }
        statusMessage = "Cost entry recorded."
    }

    func addClient(name: String, email: String, notes: String) {
        mutateActiveProject { project in
            project.proTools.clients.append(ClientRecord(
                id: UUID(),
                name: name,
                contactEmail: email,
                projectCount: 0,
                totalRevenue: 0,
                notes: notes,
                createdAt: Date()
            ))
        }
        statusMessage = "Client '\(name)' added."
    }

    func addInvoice(clientName: String, items: [InvoiceLineItem], notes: String) {
        let total = items.reduce(0) { $0 + $1.total }
        let invoiceNumber = "INV-\(timestamp())"
        mutateActiveProject { project in
            project.proTools.invoices.insert(InvoiceRecord(
                id: UUID(),
                clientID: project.proTools.clients.first(where: { $0.name == clientName })?.id,
                clientName: clientName,
                invoiceNumber: invoiceNumber,
                items: items,
                totalAmount: total,
                currency: "USD",
                status: .draft,
                issuedDate: Date(),
                dueDate: Date().addingTimeInterval(30 * 86400),
                notes: notes
            ), at: 0)
        }
        statusMessage = "Invoice \(invoiceNumber) created."
    }

    func updateInvoiceStatus(_ invoiceID: UUID, status: InvoiceStatus) {
        mutateActiveProject { project in
            guard let i = project.proTools.invoices.firstIndex(where: { $0.id == invoiceID }) else { return }
            project.proTools.invoices[i].status = status
        }
    }

    func startEditingSession() {
        mutateActiveProject { project in
            project.proTools.editingSessions.insert(EditingSession(
                id: UUID(),
                projectID: project.id,
                startTime: Date(),
                endTime: nil,
                durationMinutes: 0,
                clipsProduced: 0,
                notes: ""
            ), at: 0)
        }
        statusMessage = "Editing session started."
    }

    func endEditingSession(clipsProduced: Int) {
        mutateActiveProject { project in
            guard let i = project.proTools.editingSessions.firstIndex(where: { $0.endTime == nil }) else { return }
            project.proTools.editingSessions[i].endTime = Date()
            let elapsed = Date().timeIntervalSince(project.proTools.editingSessions[i].startTime)
            project.proTools.editingSessions[i].durationMinutes = elapsed / 60
            project.proTools.editingSessions[i].clipsProduced = clipsProduced
        }
        statusMessage = "Editing session ended."
    }

    func proToolsBinding<T>(for keyPath: WritableKeyPath<ProToolsData, T>, fallback: T) -> Binding<T> {
        Binding(
            get: { self.activeProject?.proTools[keyPath: keyPath] ?? fallback },
            set: { newValue in
                self.mutateActiveProject { project in
                    project.proTools[keyPath: keyPath] = newValue
                }
            }
        )
    }

    func timelineDuration(for project: StudioProject?) -> TimeInterval {
        guard let project else { return 0 }

        let videoEnd = project.timelineVideoClips.map(\.timelineEnd).max() ?? 0
        let audioEnd = project.timelineAudioClips.map(\.timelineEnd).max() ?? 0
        let voiceOverEnd = project.voiceOvers.map(\.end).max() ?? 0
        return max(videoEnd, audioEnd, voiceOverEnd)
    }

    private func resolveVideoFilePath(from outputPath: String) -> String? {
        var isDirectory = ObjCBool(false)
        guard fileManager.fileExists(atPath: outputPath, isDirectory: &isDirectory) else {
            return nil
        }

        if isDirectory.boolValue == false {
            let ext = URL(fileURLWithPath: outputPath).pathExtension.lowercased()
            return ["mov", "mp4", "m4v"].contains(ext) ? outputPath : nil
        }

        let directory = URL(fileURLWithPath: outputPath)
        let known = ["rendered.mov", "rendered.mp4", "rendered.m4v"]
        for filename in known {
            let candidate = directory.appendingPathComponent(filename).path
            if fileManager.fileExists(atPath: candidate) {
                return candidate
            }
        }

        guard let files = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
            return nil
        }

        return files.first(where: { ["mov", "mp4", "m4v"].contains($0.pathExtension.lowercased()) })?.path
    }

    private var preferredActiveProject: StudioProject? {
        projects
            .sorted {
                if $0.status.sortOrder != $1.status.sortOrder {
                    return $0.status.sortOrder < $1.status.sortOrder
                }
                return $0.updatedAt > $1.updatedAt
            }
            .first
    }

    private func performExportCurrentProject() async {
        guard isExporting == false else {
            return
        }

        isExporting = true
        defer { isExporting = false }

        guard let snapshot = activeProject else {
            lastError = "Create a project before exporting."
            return
        }

        guard snapshot.timelineVideoClips.isEmpty == false else {
            lastError = "Timeline is empty. Import a video and add timeline clips before exporting."
            return
        }

        let selectedPreset = exportPreset
        statusMessage = "Exporting \(snapshot.title)..."

        do {
            let exportsRoot = try prepareExportsDirectory()
            let folder = exportsRoot.appendingPathComponent("\(snapshot.videoID)-\(timestamp())", isDirectory: true)
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)

            let renderedVideoURL = folder.appendingPathComponent("rendered.mov")
            try await TimelineComposer.export(
                project: snapshot,
                outputURL: renderedVideoURL,
                renderQuality: selectedPreset.renderQuality,
                includeVoiceOvers: selectedPreset.includeVoiceOver,
                includeAuxAudio: true
            )

            let manifest = ExportManifest(
                generatedAt: Date(),
                projectTitle: snapshot.title,
                videoID: snapshot.videoID,
                preset: selectedPreset,
                clipCount: snapshot.timelineVideoClips.count,
                captionCount: snapshot.captions.count,
                voiceOverCount: snapshot.voiceOvers.count,
                clips: snapshot.clips,
                captions: snapshot.captions,
                voiceOvers: snapshot.voiceOvers,
                editor: snapshot.editor
            )

            try writeManifest(manifest, to: folder)
            if selectedPreset.includeCaptions {
                try writeSRT(from: snapshot.captions, to: folder)
            }
            try writeSummary(for: snapshot, preset: selectedPreset, renderedVideoPath: renderedVideoURL.path, to: folder)

            mutateProject(withID: snapshot.id) { project in
                project.exports.insert(
                    ExportRecord(
                        id: UUID(),
                        date: Date(),
                        preset: selectedPreset,
                        outputPath: renderedVideoURL.path,
                        notes: "Rendered timeline video"
                    ),
                    at: 0
                )

                project.transactions.insert(
                    TransactionRecord(
                        id: UUID(),
                        date: Date(),
                        type: .export,
                        status: .completed,
                        amount: 0,
                        currency: "USD",
                        description: "Exported timeline render for \(selectedPreset.platform.rawValue)"
                    ),
                    at: 0
                )
            }

            statusMessage = "Export finished: \(renderedVideoURL.path)."
        } catch {
            lastError = "Export failed: \(error.localizedDescription)"
        }
    }

    private func importVideoAsync(filePath: String, makePrimary: Bool, projectID: UUID? = nil) async {
        guard var input = resolveVideoSourceInput(from: filePath) else {
            return
        }

        if input.sourceURL.isFileURL == false {
            statusMessage = "Downloading remote video for timeline editing..."
            do {
                let localURL = try await downloadRemoteVideo(from: input.sourceURL)
                input = VideoSourceInput(
                    sourceURL: localURL,
                    persistedPath: localURL.path,
                    label: localURL.lastPathComponent
                )
            } catch {
                lastError = "Failed to download remote video URL. Download it locally and import from file."
                return
            }
        }

        let asset = AVURLAsset(url: input.sourceURL)
        let duration: TimeInterval
        do {
            let videoTracks = try await asset.loadTracks(withMediaType: .video)
            guard videoTracks.isEmpty == false else {
                lastError = "Selected source has no video track."
                return
            }

            duration = safeSeconds(try await asset.load(.duration))
            guard duration > 0 else {
                lastError = "Could not read video duration."
                return
            }
        } catch {
            lastError = describeVideoImportError(error, sourceURL: input.sourceURL)
            return
        }

        let applyMutation: ((inout StudioProject) -> Void) = { project in
            if let existing = project.mediaSources.first(where: { $0.filePath == input.persistedPath || $0.label == input.label }) {
                if makePrimary || project.primaryMediaSourceID == nil {
                    project.primaryMediaSourceID = existing.id
                }
                return
            }

            let source = MediaSource(
                id: UUID(),
                label: input.label,
                filePath: input.persistedPath,
                duration: duration,
                addedAt: Date()
            )

            project.mediaSources.insert(source, at: 0)

            if makePrimary || project.primaryMediaSourceID == nil {
                project.primaryMediaSourceID = source.id
            }

            if project.timelineVideoClips.isEmpty,
               let primary = self.primaryMediaSource(for: project) {
                if project.clips.isEmpty {
                    project.timelineVideoClips = [self.makeFullTimelineClip(from: primary, label: "Primary Full Clip")]
                } else {
                    project.timelineVideoClips = self.makeTimelineFromAutoClips(project: project, primarySource: primary)
                }
                self.recalculateTimelineVideoStarts(&project)
            }
        }

        if let projectID {
            mutateProject(withID: projectID, applyMutation)
        } else {
            mutateActiveProject(applyMutation)
        }

        let mode = makePrimary ? "primary" : "additional"
        statusMessage = "Imported \(mode) source video: \(input.label)."
    }

    private func sourceDuration(for sourceID: UUID, in project: StudioProject) -> TimeInterval {
        project.mediaSources.first(where: { $0.id == sourceID })?.duration ?? 0
    }

    private func primaryMediaSource(for project: StudioProject) -> MediaSource? {
        if let primaryID = project.primaryMediaSourceID,
           let source = project.mediaSources.first(where: { $0.id == primaryID }) {
            return source
        }
        return project.mediaSources.first
    }

    private func makeFullTimelineClip(from source: MediaSource, label: String) -> TimelineVideoClip {
        TimelineVideoClip(
            id: UUID(),
            sourceID: source.id,
            label: label,
            inPoint: 0,
            outPoint: max(0.1, source.duration),
            playbackRate: 1.0,
            muted: false,
            timelineStart: 0
        )
    }

    private func makeTimelineFromAutoClips(project: StudioProject, primarySource: MediaSource) -> [TimelineVideoClip] {
        let sourceDuration = max(0.1, primarySource.duration)
        let defaultRate = playbackRate(for: project.editor.speedPreset)
        var cursor: TimeInterval = 0

        let mapped: [TimelineVideoClip] = project.clips
            .sorted(by: { $0.start < $1.start })
            .map { clip in
                let inPoint = clamp(clip.start, lower: 0, upper: max(0, sourceDuration - 0.1))
                let desiredOut = max(inPoint + 0.1, clip.end)
                let outPoint = clamp(desiredOut, lower: inPoint + 0.1, upper: sourceDuration)

                let timelineClip = TimelineVideoClip(
                    id: UUID(),
                    sourceID: primarySource.id,
                    label: clip.title,
                    inPoint: inPoint,
                    outPoint: outPoint,
                    playbackRate: defaultRate,
                    muted: false,
                    timelineStart: cursor
                )

                cursor += timelineClip.timelineDuration
                return timelineClip
            }

        if mapped.isEmpty {
            return [makeFullTimelineClip(from: primarySource, label: "Primary Full Clip")]
        }

        return mapped
    }

    private func recalculateTimelineVideoStarts(_ project: inout StudioProject) {
        var cursor: TimeInterval = 0
        for index in project.timelineVideoClips.indices {
            project.timelineVideoClips[index].timelineStart = cursor
            cursor += project.timelineVideoClips[index].timelineDuration
        }
    }

    private func playbackRate(for preset: SpeedPreset) -> Double {
        switch preset {
        case .slower:
            return 0.85
        case .normal:
            return 1.0
        case .punchy:
            return 1.15
        case .fast:
            return 1.25
        }
    }

    private func loadWorkspace() {
        do {
            var workspace = try persistence.loadWorkspace()

            if workspace.projects.contains(where: { $0.status == .current }) == false,
               let firstIndex = workspace.projects.firstIndex(where: { $0.status == .working }) {
                workspace.projects[firstIndex].status = .current
            }

            for index in workspace.projects.indices {
                if workspace.projects[index].mediaSources.isEmpty {
                    workspace.projects[index].primaryMediaSourceID = nil
                    workspace.projects[index].timelineVideoClips = []
                    workspace.projects[index].timelineAudioClips = []
                }
            }

            projects = workspace.projects
            activeProjectID = workspace.activeProjectID ?? preferredActiveProject?.id

            if let project = activeProject {
                youtubeInput = project.youtubeURL
                selectedCaptionStyle = project.captions.first?.style ?? .cinematic
                statusMessage = "Loaded workspace with \(projects.count) project(s)."
            }

            persistWorkspace()
        } catch {
            lastError = "Failed to load workspace: \(error.localizedDescription)"
        }
    }

    func mutateActiveProjectPublic(_ mutation: (inout StudioProject) -> Void) {
        mutateActiveProject(mutation)
    }

    private func mutateActiveProject(_ mutation: (inout StudioProject) -> Void) {
        guard let projectID = activeProject?.id else {
            lastError = "Create or open a project first."
            return
        }
        mutateProject(withID: projectID, mutation)
    }

    private func mutateProject(withID projectID: UUID, _ mutation: (inout StudioProject) -> Void) {
        guard let index = projects.firstIndex(where: { $0.id == projectID }) else {
            lastError = "Project not found."
            return
        }

        mutation(&projects[index])
        projects[index].updatedAt = Date()
        persistWorkspace()
    }

    private func demoteCurrentProjects(excluding projectID: UUID) {
        for index in projects.indices where projects[index].id != projectID && projects[index].status == .current {
            projects[index].status = .working
            projects[index].updatedAt = Date()
        }
    }

    private func persistWorkspace() {
        do {
            let workspace = ProjectWorkspace(
                schemaVersion: 1,
                activeProjectID: activeProject?.id,
                projects: projects
            )
            try persistence.save(workspace: workspace)
        } catch {
            lastError = "Failed to save workspace: \(error.localizedDescription)"
        }
    }

    private func prepareExportsDirectory() throws -> URL {
        let base = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Movies", isDirectory: true)
            .appendingPathComponent("CliperTubeExports", isDirectory: true)

        try fileManager.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    private func writeManifest(_ manifest: ExportManifest, to folder: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(manifest)
        try data.write(to: folder.appendingPathComponent("manifest.json"), options: [.atomic])
    }

    private func writeSRT(from captions: [CaptionSegment], to folder: URL) throws {
        let contents = captions.enumerated().map { index, caption in
            """
            \(index + 1)
            \(formatSRT(caption.start)) --> \(formatSRT(caption.end))
            \(caption.text)
            """
        }
        .joined(separator: "\n\n")

        try contents.write(
            to: folder.appendingPathComponent("captions.srt"),
            atomically: true,
            encoding: .utf8
        )
    }

    private func writeSummary(for project: StudioProject, preset: ExportPreset, renderedVideoPath: String, to folder: URL) throws {
        let summary = """
        Cliper Tube Export Summary

        Project: \(project.title)
        Source URL: \(project.youtubeURL)
        Video ID: \(project.videoID)
        Status: \(project.status.label)
        Media Sources: \(project.mediaSources.count)
        Timeline Video Clips: \(project.timelineVideoClips.count)
        Timeline Audio Clips: \(project.timelineAudioClips.count)
        Captions: \(project.captions.count)
        Voice Overs: \(project.voiceOvers.count)
        Aspect Ratio: \(project.editor.aspectRatio.rawValue)
        Transition: \(project.editor.transitionStyle.label)
        Render Quality: \(preset.renderQuality.rawValue)
        Platform: \(preset.platform.rawValue)
        Rendered Video: \(renderedVideoPath)
        """

        try summary.write(
            to: folder.appendingPathComponent("summary.txt"),
            atomically: true,
            encoding: .utf8
        )
    }

    private func formatSRT(_ value: TimeInterval) -> String {
        let clamped = max(0, value)
        let totalMilliseconds = Int((clamped * 1000).rounded())

        let hours = totalMilliseconds / 3_600_000
        let minutes = (totalMilliseconds % 3_600_000) / 60_000
        let seconds = (totalMilliseconds % 60_000) / 1000
        let milliseconds = totalMilliseconds % 1000

        return String(
            format: "%02d:%02d:%02d,%03d",
            hours,
            minutes,
            seconds,
            milliseconds
        )
    }

    private func safeSeconds(_ time: CMTime) -> TimeInterval {
        let seconds = CMTimeGetSeconds(time)
        return seconds.isFinite ? max(0, seconds) : 0
    }

    private func clamp(_ value: Double, lower: Double, upper: Double) -> Double {
        min(upper, max(lower, value))
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }

    private func resolveVideoSourceInput(from raw: String) -> VideoSourceInput? {
        let clean = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.isEmpty == false else {
            lastError = "Video source cannot be empty."
            return nil
        }

        if let url = URL(string: clean),
           let scheme = url.scheme?.lowercased(),
           ["http", "https"].contains(scheme) {
            if isYouTubeWatchURL(url) {
                lastError = "YouTube watch URLs are not direct media files. Use Create Project for link analysis, then import a local/downloaded video for editing."
                return nil
            }

            let label = url.lastPathComponent.isEmpty ? (url.host ?? "Remote Video") : url.lastPathComponent
            return VideoSourceInput(
                sourceURL: url,
                persistedPath: url.absoluteString,
                label: label
            )
        }

        if let url = URL(string: clean), url.isFileURL {
            let path = url.path
            guard fileManager.fileExists(atPath: path) else {
                lastError = "Video file does not exist: \(path)"
                return nil
            }
            return VideoSourceInput(
                sourceURL: url,
                persistedPath: path,
                label: url.lastPathComponent
            )
        }

        let fileURL = URL(fileURLWithPath: clean)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            lastError = "Video file does not exist: \(clean)"
            return nil
        }

        return VideoSourceInput(
            sourceURL: fileURL,
            persistedPath: fileURL.path,
            label: fileURL.lastPathComponent
        )
    }

    private func makeProject(videoID: String, sourceInput: String, titlePrefix: String) -> StudioProject {
        let transcript = TranscriptFactory.generate(videoID: videoID)
        let clips = ClipEngine.autoStitch(from: transcript, maxClips: 6)
        let captions = CaptionEngine.generate(from: transcript, style: selectedCaptionStyle)
        let voiceOvers = VoiceOverPlanner.plan(for: clips)
        let now = Date()
        let uniqueTitle = makeUniqueTitle(from: titlePrefix, now: now)

        return StudioProject(
            id: UUID(),
            title: uniqueTitle,
            youtubeURL: sourceInput,
            videoID: videoID,
            status: .current,
            createdAt: now,
            updatedAt: now,
            transcriptSegments: transcript,
            clips: clips,
            captions: captions,
            voiceOvers: voiceOvers,
            editor: .default,
            primaryMediaSourceID: nil,
            mediaSources: [],
            timelineVideoClips: [],
            timelineAudioClips: [],
            exports: [],
            transactions: [
                TransactionRecord(
                    id: UUID(),
                    date: now,
                    type: .subscription,
                    status: .completed,
                    amount: 0,
                    currency: "USD",
                    description: "Local Studio License"
                )
            ],
            benchmarkCoverage: BenchmarkCatalog.defaultCoverage()
        )
    }

    private func makeUniqueTitle(from titlePrefix: String, now: Date) -> String {
        let trimmed = titlePrefix.trimmingCharacters(in: .whitespacesAndNewlines)
        var baseTitle = trimmed.isEmpty ? "Cliper Project" : trimmed
        if projects.contains(where: { $0.title == baseTitle }) {
            baseTitle += " \(shortDate(now))"
        }
        return baseTitle
    }

    private func syntheticVideoID(from value: String) -> String {
        let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-")
        var hash: UInt64 = 1469598103934665603
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }

        var result: [Character] = []
        var work = hash
        for _ in 0..<11 {
            let index = Int(work % UInt64(alphabet.count))
            result.append(alphabet[index])
            work = work / UInt64(alphabet.count)
            if work == 0 {
                work = hash ^ UInt64(result.count * 977)
            }
        }
        return String(result)
    }

    private func isYouTubeWatchURL(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        if host.contains("youtube.com") || host.contains("youtu.be") {
            let ext = url.pathExtension.lowercased()
            return ["mp4", "mov", "m4v", "webm"].contains(ext) == false
        }
        return false
    }

    private func describeVideoImportError(_ error: Error, sourceURL: URL) -> String {
        if sourceURL.isFileURL {
            return "Failed to read video file: \(error.localizedDescription)"
        }

        return "Failed to read remote video URL. Use a direct MP4/MOV link that supports byte-range streaming, or download the file locally and import it."
    }

    private func downloadRemoteVideo(from remoteURL: URL) async throws -> URL {
        let importsDirectory = try prepareImportedVideosDirectory()
        var request = URLRequest(url: remoteURL)
        request.timeoutInterval = 180

        let (tempURL, response) = try await URLSession.shared.download(for: request)
        if let http = response as? HTTPURLResponse,
           (200...299).contains(http.statusCode) == false {
            throw URLError(.badServerResponse)
        }

        let fileExtension = preferredVideoExtension(remoteURL: remoteURL, response: response)
        let destinationURL = importsDirectory.appendingPathComponent(
            "remote-\(timestamp())-\(UUID().uuidString.prefix(8)).\(fileExtension)"
        )

        try? fileManager.removeItem(at: destinationURL)
        try fileManager.moveItem(at: tempURL, to: destinationURL)
        return destinationURL
    }

    private func prepareImportedVideosDirectory() throws -> URL {
        let directory = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Movies", isDirectory: true)
            .appendingPathComponent("CliperTubeImports", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func preferredVideoExtension(remoteURL: URL, response: URLResponse) -> String {
        let ext = remoteURL.pathExtension.lowercased()
        if ["mp4", "mov", "m4v", "webm"].contains(ext) {
            return ext
        }

        if let mime = response.mimeType?.lowercased() {
            if mime.contains("quicktime") { return "mov" }
            if mime.contains("mp4") { return "mp4" }
            if mime.contains("webm") { return "webm" }
        }

        return "mp4"
    }
    
    // MARK: - Easy Mode Pipeline
    
    /// Full automated pipeline: Download → Analyze → Clip → Caption → Stitch → Export
    func runEasyModePipeline(url: String) {
        guard !url.isEmpty else {
            easyModeState.error = "Please paste a YouTube URL"
            return
        }
        
        guard let videoID = YouTubeParser.extractID(from: url) else {
            easyModeState.error = "Invalid YouTube URL"
            return
        }
        
        easyModeState = EasyModeState()
        easyModeState.currentStep = .downloading
        easyModeState.statusText = "Starting automated pipeline..."
        
        Task { @MainActor in
            do {
                // Step 1: Download
                easyModeState.currentStep = .downloading
                easyModeState.statusText = "Downloading video from YouTube..."
                easyModeState.progress = 0.1
                
                let metadata = try await VideoDownloader.fetchMetadata(url: url)
                easyModeState.statusText = "Downloading: \(metadata.title)"
                
                let result = try await VideoDownloader.download(url: url, quality: .best) { [weak self] progress in
                    Task { @MainActor in
                        self?.easyModeState.progress = 0.1 + (progress.percent / 100.0) * 0.3
                        self?.easyModeState.statusText = String(format: "Downloading %.0f%% - %@", progress.percent, progress.speed)
                    }
                }
                
                // Step 2: Create Project & Import
                easyModeState.currentStep = .analyzing
                easyModeState.progress = 0.4
                easyModeState.statusText = "Creating project and importing video..."
                
                let project = makeProject(videoID: videoID, sourceInput: url, titlePrefix: metadata.title)
                demoteCurrentProjects(excluding: project.id)
                projects.insert(project, at: 0)
                activeProjectID = project.id
                persistWorkspace()
                
                await importPrimaryVideo(into: project.id, filePath: result.videoPath)
                
                // Step 3: Generate clips
                easyModeState.currentStep = .clipping
                easyModeState.progress = 0.5
                easyModeState.statusText = "Analyzing content and generating clips..."
                
                runAutoClipAndStitch(maxClips: 6)
                
                // Step 4: Generate captions
                easyModeState.currentStep = .captioning
                easyModeState.progress = 0.6
                easyModeState.statusText = "Generating captions..."
                
                regenerateCaptions()
                
                // Step 5: Stitch timeline
                easyModeState.currentStep = .stitching
                easyModeState.progress = 0.7
                easyModeState.statusText = "Building timeline..."
                
                // Timeline is already built by runAutoClipAndStitch
                try await Task.sleep(nanoseconds: 500_000_000) // Brief pause for UI
                
                // Step 6: Export
                easyModeState.currentStep = .exporting
                easyModeState.progress = 0.8
                easyModeState.statusText = "Rendering final video..."
                
                await performExportCurrentProject()
                
                // Complete
                easyModeState.currentStep = .complete
                easyModeState.progress = 1.0
                easyModeState.statusText = "✓ Your video is ready!"
                
                if let latestExport = activeProject?.exports.sorted(by: { $0.date > $1.date }).first {
                    easyModeState.outputPath = latestExport.outputPath
                }
                
                scanCMSFiles()
                
            } catch {
                easyModeState.currentStep = .failed
                easyModeState.error = error.localizedDescription
                easyModeState.statusText = "Pipeline failed: \(error.localizedDescription)"
            }
        }
    }
    
    func resetEasyMode() {
        easyModeState = EasyModeState()
        easyModeURL = ""
    }
    
    // MARK: - CMS / File Management
    
    func scanCMSFiles() {
        var files: [CMSFileItem] = []
        var stats = CMSStats()
        
        // Scan CliperTube directories
        let directories = [
            fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Movies/CliperTubeImports"),
            fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Movies/CliperTubeExports"),
            fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Documents/CliperTube")
        ]
        
        for directory in directories {
            guard fileManager.fileExists(atPath: directory.path) else { continue }
            
            if let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey, .contentModificationDateKey], options: [.skipsHiddenFiles]) {
                while let fileURL = enumerator.nextObject() as? URL {
                    guard !fileURL.hasDirectoryPath else { continue }
                    
                    do {
                        let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .creationDateKey, .contentModificationDateKey])
                        let size = Int64(resourceValues.fileSize ?? 0)
                        let created = resourceValues.creationDate ?? Date()
                        let modified = resourceValues.contentModificationDate ?? Date()
                        
                        let ext = fileURL.pathExtension.lowercased()
                        let fileType = classifyFileType(extension: ext)
                        
                        // Find associated project (simplified to avoid type-check timeout)
                        let filePath = fileURL.path
                        let associatedProject = findProjectForFile(path: filePath)
                        
                        let item = CMSFileItem(
                            name: fileURL.lastPathComponent,
                            path: filePath,
                            fileType: fileType,
                            size: size,
                            createdAt: created,
                            modifiedAt: modified,
                            projectID: associatedProject?.id,
                            projectTitle: associatedProject?.title
                        )
                        
                        files.append(item)
                        stats.totalFiles += 1
                        stats.totalSize += size
                        
                        switch fileType {
                        case .video: stats.videoCount += 1
                        case .audio: stats.audioCount += 1
                        case .export: stats.exportCount += 1
                        default: break
                        }
                        
                    } catch {
                        continue
                    }
                }
            }
        }
        
        // Also add exports from projects
        for project in projects {
            for export in project.exports {
                let url = URL(fileURLWithPath: export.outputPath)
                if !files.contains(where: { $0.path == export.outputPath }) && fileManager.fileExists(atPath: export.outputPath) {
                    do {
                        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey, .contentModificationDateKey])
                        let item = CMSFileItem(
                            name: url.lastPathComponent,
                            path: export.outputPath,
                            fileType: .export,
                            size: Int64(resourceValues.fileSize ?? 0),
                            createdAt: resourceValues.creationDate ?? export.date,
                            modifiedAt: resourceValues.contentModificationDate ?? export.date,
                            projectID: project.id,
                            projectTitle: project.title
                        )
                        files.append(item)
                        stats.totalFiles += 1
                        stats.totalSize += Int64(resourceValues.fileSize ?? 0)
                        stats.exportCount += 1
                    } catch {
                        continue
                    }
                }
            }
        }
        
        cmsFiles = files
        cmsStats = stats
        sortCMSFiles()
    }
    
    func sortCMSFiles() {
        switch cmsSortOption {
        case .nameAsc:
            cmsFiles.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDesc:
            cmsFiles.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .dateNewest:
            cmsFiles.sort { $0.modifiedAt > $1.modifiedAt }
        case .dateOldest:
            cmsFiles.sort { $0.modifiedAt < $1.modifiedAt }
        case .sizeDesc:
            cmsFiles.sort { $0.size > $1.size }
        case .sizeAsc:
            cmsFiles.sort { $0.size < $1.size }
        }
    }
    
    var filteredCMSFiles: [CMSFileItem] {
        var result = cmsFiles
        
        if let filterType = cmsFilterType {
            result = result.filter { $0.fileType == filterType }
        }
        
        if !cmsSearchQuery.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(cmsSearchQuery) ||
                $0.projectTitle?.localizedCaseInsensitiveContains(cmsSearchQuery) == true
            }
        }
        
        return result
    }
    
    func deleteCMSFile(_ item: CMSFileItem) {
        do {
            try fileManager.removeItem(atPath: item.path)
            cmsFiles.removeAll { $0.id == item.id }
            scanCMSFiles() // Refresh stats
            statusMessage = "Deleted: \(item.name)"
        } catch {
            lastError = "Failed to delete: \(error.localizedDescription)"
        }
    }
    
    func revealCMSFile(_ item: CMSFileItem) {
        let url = URL(fileURLWithPath: item.path)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    func openCMSFile(_ item: CMSFileItem) {
        let url = URL(fileURLWithPath: item.path)
        NSWorkspace.shared.open(url)
    }
    
    private func findProjectForFile(path: String) -> StudioProject? {
        for project in projects {
            for source in project.mediaSources {
                if source.filePath == path {
                    return project
                }
            }
            for export in project.exports {
                if export.outputPath == path {
                    return project
                }
            }
        }
        return nil
    }
    
    private func classifyFileType(extension ext: String) -> CMSFileType {
        for type in CMSFileType.allCases {
            if type.extensions.contains(ext) {
                return type
            }
        }
        return .other
    }
}
