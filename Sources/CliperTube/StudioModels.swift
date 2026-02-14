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
        benchmarkCoverage: [BenchmarkFeature]
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
    case youtube
    case captions
    case timeline
    case voiceOver
    case proEditor
    case transactions
    case benchmarks

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .projects: return "Projects + Outputs"
        case .youtube: return "YouTube Hub"
        case .captions: return "Captions"
        case .timeline: return "Video/Audio Timeline"
        case .voiceOver: return "Voice Over Timeline"
        case .proEditor: return "Pro Editor"
        case .transactions: return "Transactions"
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
