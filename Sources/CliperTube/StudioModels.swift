import Foundation

struct StudioProject: Identifiable, Codable {
    var id: UUID
    var title: String
    var youtubeURL: String
    var videoID: String
    var status: ProjectStatus
    var createdAt: Date
    var updatedAt: Date
    var transcriptSegments: [TranscriptSegment]
    var clips: [ClipSegment]
    var captions: [CaptionSegment]
    var voiceOvers: [VoiceOverSegment]
    var editor: EditorSettings
    var primaryMediaSourceID: UUID?
    var mediaSources: [MediaSource]
    var timelineVideoClips: [TimelineVideoClip]
    var timelineAudioClips: [TimelineAudioClip]
    var exports: [ExportRecord]
    var transactions: [TransactionRecord]
    var benchmarkCoverage: [BenchmarkFeature]
    var proTools: ProToolsData

    init(
        id: UUID,
        title: String,
        youtubeURL: String,
        videoID: String,
        status: ProjectStatus,
        createdAt: Date,
        updatedAt: Date,
        transcriptSegments: [TranscriptSegment],
        clips: [ClipSegment],
        captions: [CaptionSegment],
        voiceOvers: [VoiceOverSegment],
        editor: EditorSettings,
        primaryMediaSourceID: UUID?,
        mediaSources: [MediaSource],
        timelineVideoClips: [TimelineVideoClip],
        timelineAudioClips: [TimelineAudioClip],
        exports: [ExportRecord],
        transactions: [TransactionRecord],
        benchmarkCoverage: [BenchmarkFeature],
        proTools: ProToolsData = .default
    ) {
        self.id = id
        self.title = title
        self.youtubeURL = youtubeURL
        self.videoID = videoID
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.transcriptSegments = transcriptSegments
        self.clips = clips
        self.captions = captions
        self.voiceOvers = voiceOvers
        self.editor = editor
        self.primaryMediaSourceID = primaryMediaSourceID
        self.mediaSources = mediaSources
        self.timelineVideoClips = timelineVideoClips
        self.timelineAudioClips = timelineAudioClips
        self.exports = exports
        self.transactions = transactions
        self.benchmarkCoverage = benchmarkCoverage
        self.proTools = proTools
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case youtubeURL
        case videoID
        case status
        case createdAt
        case updatedAt
        case transcriptSegments
        case clips
        case captions
        case voiceOvers
        case editor
        case primaryMediaSourceID
        case mediaSources
        case timelineVideoClips
        case timelineAudioClips
        case exports
        case transactions
        case benchmarkCoverage
        case proTools
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        youtubeURL = try container.decode(String.self, forKey: .youtubeURL)
        videoID = try container.decode(String.self, forKey: .videoID)
        status = try container.decodeIfPresent(ProjectStatus.self, forKey: .status) ?? .working
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        transcriptSegments = try container.decode([TranscriptSegment].self, forKey: .transcriptSegments)
        clips = try container.decode([ClipSegment].self, forKey: .clips)
        captions = try container.decode([CaptionSegment].self, forKey: .captions)
        voiceOvers = try container.decode([VoiceOverSegment].self, forKey: .voiceOvers)
        editor = try container.decode(EditorSettings.self, forKey: .editor)
        primaryMediaSourceID = try container.decodeIfPresent(UUID.self, forKey: .primaryMediaSourceID)
        mediaSources = try container.decodeIfPresent([MediaSource].self, forKey: .mediaSources) ?? []
        timelineVideoClips = try container.decodeIfPresent([TimelineVideoClip].self, forKey: .timelineVideoClips) ?? []
        timelineAudioClips = try container.decodeIfPresent([TimelineAudioClip].self, forKey: .timelineAudioClips) ?? []
        exports = try container.decode([ExportRecord].self, forKey: .exports)
        transactions = try container.decode([TransactionRecord].self, forKey: .transactions)
        benchmarkCoverage = try container.decode([BenchmarkFeature].self, forKey: .benchmarkCoverage)
        proTools = try container.decodeIfPresent(ProToolsData.self, forKey: .proTools) ?? .default
    }
}

struct ProjectWorkspace: Codable {
    var schemaVersion: Int
    var activeProjectID: UUID?
    var projects: [StudioProject]

    static let empty = ProjectWorkspace(schemaVersion: 1, activeProjectID: nil, projects: [])
}

struct ProjectOutputItem: Identifiable {
    var id: UUID { export.id }
    var projectID: UUID
    var projectTitle: String
    var projectStatus: ProjectStatus
    var export: ExportRecord
}

struct ExportVideoCandidate: Identifiable {
    var id: UUID
    var projectTitle: String
    var exportDate: Date
    var filePath: String
    var displayName: String
}

struct MediaSource: Identifiable, Codable {
    var id: UUID
    var label: String
    var filePath: String
    var duration: TimeInterval
    var addedAt: Date
}

struct TimelineVideoClip: Identifiable, Codable {
    var id: UUID
    var sourceID: UUID
    var label: String
    var inPoint: TimeInterval
    var outPoint: TimeInterval
    var playbackRate: Double
    var muted: Bool
    var timelineStart: TimeInterval

    var sourceDuration: TimeInterval { max(0, outPoint - inPoint) }
    var timelineDuration: TimeInterval {
        let rate = max(0.1, playbackRate)
        return sourceDuration / rate
    }

    var timelineEnd: TimeInterval {
        timelineStart + timelineDuration
    }
}

struct TimelineAudioClip: Identifiable, Codable {
    var id: UUID
    var label: String
    var filePath: String
    var inPoint: TimeInterval
    var outPoint: TimeInterval
    var volume: Double
    var timelineStart: TimeInterval

    var sourceDuration: TimeInterval { max(0, outPoint - inPoint) }

    var timelineEnd: TimeInterval {
        timelineStart + sourceDuration
    }
}

struct TranscriptSegment: Identifiable, Codable {
    var id: UUID
    var start: TimeInterval
    var end: TimeInterval
    var text: String

    var duration: TimeInterval { max(0, end - start) }
}

struct ClipSegment: Identifiable, Codable {
    var id: UUID
    var title: String
    var start: TimeInterval
    var end: TimeInterval
    var confidence: Double
    var hook: String
    var tags: [String]

    var duration: TimeInterval { max(0, end - start) }
}

struct CaptionSegment: Identifiable, Codable {
    var id: UUID
    var start: TimeInterval
    var end: TimeInterval
    var text: String
    var style: CaptionStyle
}

struct VoiceOverSegment: Identifiable, Codable {
    var id: UUID
    var start: TimeInterval
    var end: TimeInterval
    var note: String
    var audioFilePath: String?
}

struct EditorSettings: Codable {
    var aspectRatio: AspectRatio
    var autoReframe: Bool
    var silenceRemoval: Bool
    var smartJumpCuts: Bool
    var smartBroll: Bool
    var noiseReduction: Bool
    var colorBoost: Bool
    var speedPreset: SpeedPreset
    var transitionStyle: TransitionStyle

    static let `default` = EditorSettings(
        aspectRatio: .vertical,
        autoReframe: true,
        silenceRemoval: true,
        smartJumpCuts: true,
        smartBroll: false,
        noiseReduction: true,
        colorBoost: true,
        speedPreset: .normal,
        transitionStyle: .snappy
    )
}

struct ExportPreset: Codable {
    var platform: ExportPlatform
    var includeCaptions: Bool
    var includeVoiceOver: Bool
    var renderQuality: RenderQuality

    static let `default` = ExportPreset(
        platform: .youtubeShorts,
        includeCaptions: true,
        includeVoiceOver: true,
        renderQuality: .high
    )
}

struct ExportRecord: Identifiable, Codable {
    var id: UUID
    var date: Date
    var preset: ExportPreset
    var outputPath: String
    var notes: String
}

struct TransactionRecord: Identifiable, Codable {
    var id: UUID
    var date: Date
    var type: TransactionType
    var status: TransactionStatus
    var amount: Double
    var currency: String
    var description: String
}

struct BenchmarkFeature: Identifiable, Codable {
    var id: UUID
    var competitor: String
    var feature: String
    var implemented: Bool
    var notes: String
}

enum StudioSection: String, CaseIterable, Identifiable {
    case dashboard
    case projects
    case fileManager
    case youtube
    case clipIntelligence
    case captions
    case timeline
    case voiceOver
    case audioStudio
    case proEditor
    case distribution
    case transactions
    case revenueClients
    case benchmarks

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .projects: return "Projects + Outputs"
        case .fileManager: return "File Manager"
        case .youtube: return "YouTube Hub"
        case .clipIntelligence: return "Clip Intelligence"
        case .captions: return "Captions"
        case .timeline: return "Video/Audio Timeline"
        case .voiceOver: return "Voice Over Timeline"
        case .audioStudio: return "Audio Studio"
        case .proEditor: return "Pro Editor"
        case .distribution: return "Distribution Center"
        case .transactions: return "Transactions"
        case .revenueClients: return "Revenue & Clients"
        case .benchmarks: return "Top Clipper Benchmarks"
        }
    }
}

enum ProjectStatus: String, Codable, CaseIterable, Identifiable {
    case current
    case working
    case past

    var id: String { rawValue }

    var label: String {
        switch self {
        case .current: return "Current"
        case .working: return "Working"
        case .past: return "Past"
        }
    }

    var sortOrder: Int {
        switch self {
        case .current: return 0
        case .working: return 1
        case .past: return 2
        }
    }
}

enum CaptionStyle: String, Codable, CaseIterable, Identifiable {
    case cinematic
    case punch
    case minimal
    case brandKit

    var id: String { rawValue }

    var label: String {
        switch self {
        case .cinematic: return "Cinematic"
        case .punch: return "Punch"
        case .minimal: return "Minimal"
        case .brandKit: return "Brand Kit"
        }
    }
}

enum AspectRatio: String, Codable, CaseIterable, Identifiable {
    case vertical = "9:16"
    case square = "1:1"
    case landscape = "16:9"

    var id: String { rawValue }
}

enum SpeedPreset: String, Codable, CaseIterable, Identifiable {
    case slower = "0.85x"
    case normal = "1.0x"
    case punchy = "1.15x"
    case fast = "1.25x"

    var id: String { rawValue }
}

enum TransitionStyle: String, Codable, CaseIterable, Identifiable {
    case none
    case snappy
    case cinematic
    case glitch

    var id: String { rawValue }

    var label: String {
        rawValue.capitalized
    }
}

enum ExportPlatform: String, Codable, CaseIterable, Identifiable {
    case youtubeShorts = "YouTube Shorts"
    case tiktok = "TikTok"
    case instagramReels = "Instagram Reels"
    case x = "X"
    case linkedin = "LinkedIn"

    var id: String { rawValue }
}

enum RenderQuality: String, Codable, CaseIterable, Identifiable {
    case standard = "1080p"
    case high = "1440p"
    case ultra = "4K"

    var id: String { rawValue }
}

enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case export
    case subscription
    case purchase
    case payout

    var id: String { rawValue }

    var label: String {
        rawValue.capitalized
    }
}

enum TransactionStatus: String, Codable, CaseIterable, Identifiable {
    case draft
    case completed
    case failed

    var id: String { rawValue }

    var label: String {
        rawValue.capitalized
    }
}

struct StudioMetrics {
    var clipCount: Int
    var averageConfidence: Double
    var captionCount: Int
    var transactionTotal: Double
}

// MARK: - App Mode

enum AppMode: String, CaseIterable, Identifiable {
    case easy = "Easy Mode"
    case pro = "Pro Mode"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .easy: return "wand.and.stars"
        case .pro: return "slider.horizontal.3"
        }
    }
    
    var description: String {
        switch self {
        case .easy: return "One-click automated workflow"
        case .pro: return "Full control over every step"
        }
    }
}

// MARK: - Easy Mode Pipeline State

enum EasyModePipelineStep: String, CaseIterable, Identifiable {
    case idle = "Ready"
    case downloading = "Downloading Video"
    case analyzing = "Analyzing Content"
    case clipping = "Creating Clips"
    case captioning = "Generating Captions"
    case stitching = "Stitching Timeline"
    case exporting = "Exporting Final"
    case complete = "Complete"
    case failed = "Failed"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .idle: return "play.circle"
        case .downloading: return "arrow.down.circle"
        case .analyzing: return "brain.head.profile"
        case .clipping: return "scissors"
        case .captioning: return "captions.bubble"
        case .stitching: return "timeline.selection"
        case .exporting: return "square.and.arrow.up"
        case .complete: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
    
    var isTerminal: Bool {
        self == .complete || self == .failed
    }
}

struct EasyModeState {
    var currentStep: EasyModePipelineStep = .idle
    var progress: Double = 0
    var statusText: String = "Paste a YouTube URL to get started"
    var outputPath: String?
    var error: String?
}

// MARK: - CMS / File Management

struct CMSFileItem: Identifiable {
    var id: UUID = UUID()
    var name: String
    var path: String
    var fileType: CMSFileType
    var size: Int64
    var createdAt: Date
    var modifiedAt: Date
    var projectID: UUID?
    var projectTitle: String?
    var thumbnailPath: String?
}

enum CMSFileType: String, CaseIterable, Identifiable {
    case video = "Video"
    case audio = "Audio"
    case image = "Image"
    case caption = "Caption"
    case project = "Project"
    case export = "Export"
    case other = "Other"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .video: return "film"
        case .audio: return "waveform"
        case .image: return "photo"
        case .caption: return "captions.bubble"
        case .project: return "folder"
        case .export: return "square.and.arrow.up"
        case .other: return "doc"
        }
    }
    
    var extensions: [String] {
        switch self {
        case .video: return ["mp4", "mov", "m4v", "mkv", "webm"]
        case .audio: return ["mp3", "m4a", "wav", "aac", "flac"]
        case .image: return ["jpg", "jpeg", "png", "heic", "gif", "webp"]
        case .caption: return ["srt", "vtt", "ass", "json"]
        case .project: return ["clipertube"]
        case .export: return []
        case .other: return []
        }
    }
}

enum CMSSortOption: String, CaseIterable, Identifiable {
    case nameAsc = "Name (A-Z)"
    case nameDesc = "Name (Z-A)"
    case dateNewest = "Newest First"
    case dateOldest = "Oldest First"
    case sizeDesc = "Largest First"
    case sizeAsc = "Smallest First"
    
    var id: String { rawValue }
}

enum CMSViewMode: String, CaseIterable, Identifiable {
    case grid = "Grid"
    case list = "List"
    case gallery = "Gallery"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .grid: return "square.grid.2x2"
        case .list: return "list.bullet"
        case .gallery: return "rectangle.grid.1x2"
        }
    }
}

struct CMSStats {
    var totalFiles: Int = 0
    var totalSize: Int64 = 0
    var videoCount: Int = 0
    var audioCount: Int = 0
    var exportCount: Int = 0
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}
