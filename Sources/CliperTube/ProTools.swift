import Foundation

// MARK: - Clip Intelligence Models (Tools 1-8)

struct ViralScoreReport: Identifiable, Codable {
    var id: UUID
    var clipID: UUID
    var hookScore: Double
    var pacingScore: Double
    var keywordScore: Double
    var durationScore: Double
    var overallScore: Double
    var breakdown: String
    var generatedAt: Date
}

struct HookAnalysis: Identifiable, Codable {
    var id: UUID
    var text: String
    var clarityScore: Double
    var urgencyScore: Double
    var specificityScore: Double
    var curiosityScore: Double
    var overallGrade: String
    var suggestions: [String]
}

struct TrendingMatch: Identifiable, Codable {
    var id: UUID
    var keyword: String
    var category: TrendingCategory
    var relevanceScore: Double
    var matchedText: String
}

enum TrendingCategory: String, Codable, CaseIterable, Identifiable {
    case aiTech = "AI & Tech"
    case business = "Business"
    case selfImprovement = "Self Improvement"
    case health = "Health & Fitness"
    case finance = "Finance"
    case entertainment = "Entertainment"
    case education = "Education"
    case news = "News & Current"

    var id: String { rawValue }
}

struct RetentionPoint: Identifiable, Codable {
    var id: UUID
    var timestamp: TimeInterval
    var retentionPercent: Double
    var label: String
}

struct ABHookVariant: Identifiable, Codable {
    var id: UUID
    var original: String
    var variant: String
    var style: HookStyle
    var estimatedLift: Double
}

enum HookStyle: String, Codable, CaseIterable, Identifiable {
    case question = "Question"
    case statistic = "Statistic"
    case bold = "Bold Claim"
    case curiosity = "Curiosity Gap"
    case story = "Story Open"
    case contrarian = "Contrarian"

    var id: String { rawValue }
}

struct PlatformLengthRec: Identifiable, Codable {
    var id: UUID
    var platform: ExportPlatform
    var idealMin: TimeInterval
    var idealMax: TimeInterval
    var currentDuration: TimeInterval
    var verdict: String
}

struct EngagementZone: Identifiable, Codable {
    var id: UUID
    var start: TimeInterval
    var end: TimeInterval
    var intensity: Double
    var label: String
}

// MARK: - Caption Enhancement Models (Tools 9-13)

enum CaptionHighlightMode: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case wordByWord = "Word-by-Word"
    case phrase = "Phrase"
    case karaoke = "Karaoke"

    var id: String { rawValue }
}

enum CaptionAnimation: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case bounce = "Bounce"
    case fadeUp = "Fade Up"
    case typewriter = "Typewriter"
    case pop = "Pop In"
    case slide = "Slide"
    case glitch = "Glitch"

    var id: String { rawValue }
}

struct EmojiInsertPoint: Identifiable, Codable {
    var id: UUID
    var captionID: UUID
    var emoji: String
    var position: EmojiPosition
}

enum EmojiPosition: String, Codable, CaseIterable, Identifiable {
    case before = "Before"
    case after = "After"
    case replace = "Replace Key Word"

    var id: String { rawValue }
}

struct LanguageStub: Identifiable, Codable {
    var id: UUID
    var languageCode: String
    var languageName: String
    var captionCount: Int
    var exported: Bool
}

struct PowerWord: Identifiable, Codable {
    var id: UUID
    var word: String
    var weight: Double
    var captionIDs: [UUID]
}

// MARK: - Audio Studio Models (Tools 14-19)

struct MusicBedPreset: Identifiable, Codable {
    var id: UUID
    var name: String
    var genre: MusicGenre
    var mood: MusicMood
    var bpm: Int
    var isActive: Bool
}

enum MusicGenre: String, Codable, CaseIterable, Identifiable {
    case lofi = "Lo-Fi"
    case cinematic = "Cinematic"
    case hiphop = "Hip-Hop"
    case electronic = "Electronic"
    case acoustic = "Acoustic"
    case corporate = "Corporate"
    case epic = "Epic"
    case ambient = "Ambient"

    var id: String { rawValue }
}

enum MusicMood: String, Codable, CaseIterable, Identifiable {
    case energetic = "Energetic"
    case chill = "Chill"
    case dramatic = "Dramatic"
    case uplifting = "Uplifting"
    case dark = "Dark"
    case neutral = "Neutral"
    case motivational = "Motivational"
    case suspenseful = "Suspenseful"

    var id: String { rawValue }
}

struct SFXTrigger: Identifiable, Codable {
    var id: UUID
    var timestamp: TimeInterval
    var sfxType: SFXType
    var volume: Double
    var label: String
}

enum SFXType: String, Codable, CaseIterable, Identifiable {
    case whoosh = "Whoosh"
    case impact = "Impact"
    case riser = "Riser"
    case ding = "Ding"
    case pop = "Pop"
    case swoosh = "Swoosh"
    case glitch = "Glitch"
    case bass = "Bass Drop"
    case click = "Click"
    case notification = "Notification"

    var id: String { rawValue }
}

struct AudioDuckingConfig: Codable {
    var enabled: Bool
    var duckLevel: Double
    var attackMs: Double
    var releaseMs: Double
    var threshold: Double

    static let `default` = AudioDuckingConfig(
        enabled: true,
        duckLevel: 0.2,
        attackMs: 50,
        releaseMs: 300,
        threshold: -30
    )
}

struct LoudnessTarget: Codable {
    var enabled: Bool
    var targetLUFS: Double
    var truePeak: Double
    var platform: ExportPlatform

    static let `default` = LoudnessTarget(
        enabled: true,
        targetLUFS: -14.0,
        truePeak: -1.0,
        platform: .youtubeShorts
    )
}

struct VoiceActivitySegment: Identifiable, Codable {
    var id: UUID
    var start: TimeInterval
    var end: TimeInterval
    var isSpeech: Bool
    var confidence: Double
}

struct AudioFadeConfig: Codable {
    var fadeInDuration: TimeInterval
    var fadeOutDuration: TimeInterval
    var fadeInCurve: FadeCurve
    var fadeOutCurve: FadeCurve

    static let `default` = AudioFadeConfig(
        fadeInDuration: 0.5,
        fadeOutDuration: 1.0,
        fadeInCurve: .linear,
        fadeOutCurve: .easeOut
    )
}

enum FadeCurve: String, Codable, CaseIterable, Identifiable {
    case linear = "Linear"
    case easeIn = "Ease In"
    case easeOut = "Ease Out"
    case sCurve = "S-Curve"
    case exponential = "Exponential"

    var id: String { rawValue }
}

// MARK: - Pro Editor Enhancement Models (Tools 20-27)

struct SpeedRampPoint: Identifiable, Codable {
    var id: UUID
    var timestamp: TimeInterval
    var targetSpeed: Double
    var rampDuration: TimeInterval
}

struct ZoomRegion: Identifiable, Codable {
    var id: UUID
    var start: TimeInterval
    var end: TimeInterval
    var zoomFactor: Double
    var focusX: Double
    var focusY: Double
}

struct KenBurnsConfig: Codable {
    var enabled: Bool
    var startScale: Double
    var endScale: Double
    var panDirection: PanDirection
    var speed: Double

    static let `default` = KenBurnsConfig(
        enabled: false,
        startScale: 1.0,
        endScale: 1.2,
        panDirection: .leftToRight,
        speed: 1.0
    )
}

enum PanDirection: String, Codable, CaseIterable, Identifiable {
    case leftToRight = "Left to Right"
    case rightToLeft = "Right to Left"
    case topToBottom = "Top to Bottom"
    case bottomToTop = "Bottom to Top"
    case zoomIn = "Zoom In"
    case zoomOut = "Zoom Out"

    var id: String { rawValue }
}

struct PiPConfig: Codable {
    var enabled: Bool
    var position: PiPPosition
    var scale: Double
    var borderWidth: Double
    var cornerRadius: Double

    static let `default` = PiPConfig(
        enabled: false,
        position: .bottomRight,
        scale: 0.3,
        borderWidth: 2.0,
        cornerRadius: 12.0
    )
}

enum PiPPosition: String, Codable, CaseIterable, Identifiable {
    case topLeft = "Top Left"
    case topRight = "Top Right"
    case bottomLeft = "Bottom Left"
    case bottomRight = "Bottom Right"
    case center = "Center"

    var id: String { rawValue }
}

enum SplitScreenLayout: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case sideBySide = "Side by Side"
    case topBottom = "Top / Bottom"
    case mainWithInset = "Main + Inset"
    case tripleGrid = "Triple Grid"

    var id: String { rawValue }
}

enum ColorGradePreset: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case warm = "Warm"
    case cool = "Cool"
    case vintage = "Vintage"
    case highContrast = "High Contrast"
    case moody = "Moody"
    case bright = "Bright & Clean"
    case film = "Film Look"
    case teal = "Teal & Orange"

    var id: String { rawValue }
}

struct SafeZoneOverlay: Identifiable, Codable {
    var id: UUID
    var platform: ExportPlatform
    var topInset: Double
    var bottomInset: Double
    var leftInset: Double
    var rightInset: Double
}

// MARK: - Distribution Center Models (Tools 28-34)

struct BatchExportItem: Identifiable, Codable {
    var id: UUID
    var platform: ExportPlatform
    var quality: RenderQuality
    var aspectRatio: AspectRatio
    var includeCaptions: Bool
    var status: BatchExportStatus
}

enum BatchExportStatus: String, Codable, CaseIterable, Identifiable {
    case queued = "Queued"
    case rendering = "Rendering"
    case completed = "Completed"
    case failed = "Failed"

    var id: String { rawValue }
}

struct ThumbnailCandidate: Identifiable, Codable {
    var id: UUID
    var timestamp: TimeInterval
    var label: String
    var isSelected: Bool
}

struct WatermarkConfig: Codable {
    var enabled: Bool
    var text: String
    var position: WatermarkPosition
    var opacity: Double
    var fontSize: Double

    static let `default` = WatermarkConfig(
        enabled: false,
        text: "",
        position: .bottomRight,
        opacity: 0.5,
        fontSize: 14.0
    )
}

enum WatermarkPosition: String, Codable, CaseIterable, Identifiable {
    case topLeft = "Top Left"
    case topRight = "Top Right"
    case bottomLeft = "Bottom Left"
    case bottomRight = "Bottom Right"
    case center = "Center"

    var id: String { rawValue }
}

struct ExportTemplate: Identifiable, Codable {
    var id: UUID
    var name: String
    var preset: ExportPreset
    var editorSnapshot: EditorSettings
    var createdAt: Date
}

struct SocialCopy: Identifiable, Codable {
    var id: UUID
    var platform: ExportPlatform
    var title: String
    var body: String
    var hashtags: [String]
    var callToAction: String
}

struct PublishScheduleEntry: Identifiable, Codable {
    var id: UUID
    var platform: ExportPlatform
    var scheduledDate: Date
    var title: String
    var status: PublishStatus
    var notes: String
}

enum PublishStatus: String, Codable, CaseIterable, Identifiable {
    case planned = "Planned"
    case ready = "Ready"
    case published = "Published"
    case skipped = "Skipped"

    var id: String { rawValue }
}

// MARK: - Revenue & Client Models (Tools 35-40)

struct ClipRevenueEntry: Identifiable, Codable {
    var id: UUID
    var clipTitle: String
    var platform: ExportPlatform
    var views: Int
    var revenue: Double
    var currency: String
    var recordedAt: Date
}

struct CostEntry: Identifiable, Codable {
    var id: UUID
    var category: CostCategory
    var amount: Double
    var currency: String
    var description: String
    var date: Date
}

enum CostCategory: String, Codable, CaseIterable, Identifiable {
    case editingTime = "Editing Time"
    case software = "Software"
    case music = "Music License"
    case freelancer = "Freelancer"
    case equipment = "Equipment"
    case other = "Other"

    var id: String { rawValue }

    var label: String { rawValue }
}

struct ClientRecord: Identifiable, Codable {
    var id: UUID
    var name: String
    var contactEmail: String
    var projectCount: Int
    var totalRevenue: Double
    var notes: String
    var createdAt: Date
}

struct InvoiceRecord: Identifiable, Codable {
    var id: UUID
    var clientID: UUID?
    var clientName: String
    var invoiceNumber: String
    var items: [InvoiceLineItem]
    var totalAmount: Double
    var currency: String
    var status: InvoiceStatus
    var issuedDate: Date
    var dueDate: Date
    var notes: String
}

struct InvoiceLineItem: Identifiable, Codable {
    var id: UUID
    var description: String
    var quantity: Int
    var unitPrice: Double
    var total: Double
}

enum InvoiceStatus: String, Codable, CaseIterable, Identifiable {
    case draft = "Draft"
    case sent = "Sent"
    case paid = "Paid"
    case overdue = "Overdue"

    var id: String { rawValue }

    var label: String { rawValue }
}

struct EditingSession: Identifiable, Codable {
    var id: UUID
    var projectID: UUID?
    var startTime: Date
    var endTime: Date?
    var durationMinutes: Double
    var clipsProduced: Int
    var notes: String
}

// MARK: - Pro Tools Data Container

struct ProToolsData: Codable {
    // Clip Intelligence
    var viralScoreReports: [ViralScoreReport]
    var hookAnalyses: [HookAnalysis]
    var trendingMatches: [TrendingMatch]
    var retentionCurve: [RetentionPoint]
    var abHookVariants: [ABHookVariant]
    var platformLengthRecs: [PlatformLengthRec]
    var engagementZones: [EngagementZone]

    // Caption Enhancements
    var captionHighlightMode: CaptionHighlightMode
    var captionAnimation: CaptionAnimation
    var emojiInserts: [EmojiInsertPoint]
    var languageStubs: [LanguageStub]
    var powerWords: [PowerWord]

    // Audio Studio
    var musicBedPresets: [MusicBedPreset]
    var sfxTriggers: [SFXTrigger]
    var audioDucking: AudioDuckingConfig
    var loudnessTarget: LoudnessTarget
    var voiceActivitySegments: [VoiceActivitySegment]
    var audioFade: AudioFadeConfig

    // Pro Editor Enhancements
    var speedRampPoints: [SpeedRampPoint]
    var zoomRegions: [ZoomRegion]
    var kenBurns: KenBurnsConfig
    var pip: PiPConfig
    var splitScreen: SplitScreenLayout
    var colorGrade: ColorGradePreset
    var safeZones: [SafeZoneOverlay]

    // Distribution
    var batchExportQueue: [BatchExportItem]
    var thumbnailCandidates: [ThumbnailCandidate]
    var watermark: WatermarkConfig
    var exportTemplates: [ExportTemplate]
    var socialCopies: [SocialCopy]
    var publishSchedule: [PublishScheduleEntry]

    // Revenue & Clients
    var clipRevenue: [ClipRevenueEntry]
    var costs: [CostEntry]
    var clients: [ClientRecord]
    var invoices: [InvoiceRecord]
    var editingSessions: [EditingSession]

    static let `default` = ProToolsData(
        viralScoreReports: [],
        hookAnalyses: [],
        trendingMatches: [],
        retentionCurve: [],
        abHookVariants: [],
        platformLengthRecs: [],
        engagementZones: [],
        captionHighlightMode: .none,
        captionAnimation: .none,
        emojiInserts: [],
        languageStubs: [],
        powerWords: [],
        musicBedPresets: [],
        sfxTriggers: [],
        audioDucking: .default,
        loudnessTarget: .default,
        voiceActivitySegments: [],
        audioFade: .default,
        speedRampPoints: [],
        zoomRegions: [],
        kenBurns: .default,
        pip: .default,
        splitScreen: .none,
        colorGrade: .none,
        safeZones: [],
        batchExportQueue: [],
        thumbnailCandidates: [],
        watermark: .default,
        exportTemplates: [],
        socialCopies: [],
        publishSchedule: [],
        clipRevenue: [],
        costs: [],
        clients: [],
        invoices: [],
        editingSessions: []
    )
}

// MARK: - Engines

enum ViralScoreEngine {
    static func analyze(clips: [ClipSegment], transcript: [TranscriptSegment]) -> [ViralScoreReport] {
        clips.map { clip in
            let hookScore = scoreHook(clip.hook)
            let pacingScore = scorePacing(clip.duration)
            let keywordScore = scoreKeywords(clip.hook + " " + clip.title)
            let durationScore = scoreDuration(clip.duration)
            let overall = (hookScore * 0.35) + (pacingScore * 0.2) + (keywordScore * 0.25) + (durationScore * 0.2)

            return ViralScoreReport(
                id: UUID(),
                clipID: clip.id,
                hookScore: hookScore,
                pacingScore: pacingScore,
                keywordScore: keywordScore,
                durationScore: durationScore,
                overallScore: min(0.99, max(0.1, overall)),
                breakdown: viralBreakdown(hook: hookScore, pacing: pacingScore, keyword: keywordScore, duration: durationScore),
                generatedAt: Date()
            )
        }
    }

    private static func scoreHook(_ text: String) -> Double {
        let lower = text.lowercased()
        var score = 0.4
        let powerWords = ["secret", "proven", "mistake", "always", "never", "how", "why", "what", "best", "worst", "hack", "trick", "method", "formula", "system"]
        for word in powerWords where lower.contains(word) { score += 0.06 }
        if lower.contains("?") { score += 0.08 }
        if text.count < 80 { score += 0.05 }
        return min(0.98, score)
    }

    private static func scorePacing(_ duration: TimeInterval) -> Double {
        if duration >= 15 && duration <= 45 { return 0.9 }
        if duration >= 8 && duration <= 60 { return 0.7 }
        if duration < 5 { return 0.4 }
        return 0.5
    }

    private static func scoreKeywords(_ text: String) -> Double {
        let lower = text.lowercased()
        var score = 0.3
        let viral = ["viral", "million", "growth", "revenue", "money", "free", "fast", "easy", "simple", "insane", "crazy", "shocking", "unbelievable", "secret"]
        for word in viral where lower.contains(word) { score += 0.07 }
        return min(0.98, score)
    }

    private static func scoreDuration(_ duration: TimeInterval) -> Double {
        switch duration {
        case 15...30: return 0.95
        case 30...60: return 0.85
        case 8...15: return 0.7
        case 60...90: return 0.6
        default: return 0.4
        }
    }

    private static func viralBreakdown(hook: Double, pacing: Double, keyword: Double, duration: Double) -> String {
        let best = max(hook, pacing, keyword, duration)
        if best == hook { return "Strong hook drives this clip's viral potential." }
        if best == keyword { return "High-impact keywords boost discoverability." }
        if best == pacing { return "Excellent pacing keeps viewers engaged." }
        return "Optimal duration for platform algorithms."
    }
}

enum HookAnalyzer {
    static func analyze(clips: [ClipSegment]) -> [HookAnalysis] {
        clips.map { clip in
            let clarity = rateClarity(clip.hook)
            let urgency = rateUrgency(clip.hook)
            let specificity = rateSpecificity(clip.hook)
            let curiosity = rateCuriosity(clip.hook)
            let avg = (clarity + urgency + specificity + curiosity) / 4.0
            let grade = letterGrade(avg)

            return HookAnalysis(
                id: UUID(),
                text: clip.hook,
                clarityScore: clarity,
                urgencyScore: urgency,
                specificityScore: specificity,
                curiosityScore: curiosity,
                overallGrade: grade,
                suggestions: generateSuggestions(clarity: clarity, urgency: urgency, specificity: specificity, curiosity: curiosity)
            )
        }
    }

    private static func rateClarity(_ text: String) -> Double {
        let words = text.split(separator: " ").count
        if words <= 12 { return 0.85 }
        if words <= 20 { return 0.65 }
        return 0.45
    }

    private static func rateUrgency(_ text: String) -> Double {
        let lower = text.lowercased()
        var score = 0.3
        let urgentWords = ["now", "today", "immediately", "stop", "must", "need", "before", "hurry", "miss", "last", "only"]
        for w in urgentWords where lower.contains(w) { score += 0.1 }
        return min(0.95, score)
    }

    private static func rateSpecificity(_ text: String) -> Double {
        let lower = text.lowercased()
        var score = 0.4
        let hasNumbers = lower.rangeOfCharacter(from: .decimalDigits) != nil
        if hasNumbers { score += 0.2 }
        let specifics = ["$", "%", "step", "day", "hour", "minute", "second", "x", "k"]
        for s in specifics where lower.contains(s) { score += 0.06 }
        return min(0.95, score)
    }

    private static func rateCuriosity(_ text: String) -> Double {
        let lower = text.lowercased()
        var score = 0.3
        if lower.contains("?") { score += 0.15 }
        let curiousWords = ["secret", "hidden", "unknown", "revealed", "truth", "really", "actually", "nobody", "everyone"]
        for w in curiousWords where lower.contains(w) { score += 0.08 }
        return min(0.95, score)
    }

    private static func letterGrade(_ score: Double) -> String {
        if score >= 0.85 { return "A+" }
        if score >= 0.75 { return "A" }
        if score >= 0.65 { return "B+" }
        if score >= 0.55 { return "B" }
        if score >= 0.45 { return "C+" }
        if score >= 0.35 { return "C" }
        return "D"
    }

    private static func generateSuggestions(clarity: Double, urgency: Double, specificity: Double, curiosity: Double) -> [String] {
        var suggestions: [String] = []
        if clarity < 0.6 { suggestions.append("Shorten hook to under 12 words for clearer impact.") }
        if urgency < 0.5 { suggestions.append("Add a time-sensitive word (now, today, before) to create urgency.") }
        if specificity < 0.5 { suggestions.append("Include a specific number or metric to boost credibility.") }
        if curiosity < 0.5 { suggestions.append("Frame as a question or use a curiosity gap to pull viewers in.") }
        if suggestions.isEmpty { suggestions.append("Hook is strong across all dimensions. Ship it.") }
        return suggestions
    }
}

enum TrendingMatcher {
    static func match(transcript: [TranscriptSegment]) -> [TrendingMatch] {
        let trendingKeywords: [(String, TrendingCategory)] = [
            ("ai", .aiTech), ("artificial intelligence", .aiTech), ("chatgpt", .aiTech), ("automation", .aiTech),
            ("machine learning", .aiTech), ("robot", .aiTech), ("algorithm", .aiTech),
            ("startup", .business), ("entrepreneur", .business), ("founder", .business), ("revenue", .business),
            ("profit", .business), ("business", .business), ("scale", .business), ("growth", .business),
            ("mindset", .selfImprovement), ("discipline", .selfImprovement), ("habit", .selfImprovement),
            ("productivity", .selfImprovement), ("focus", .selfImprovement), ("motivation", .selfImprovement),
            ("fitness", .health), ("workout", .health), ("nutrition", .health), ("sleep", .health), ("mental health", .health),
            ("invest", .finance), ("money", .finance), ("crypto", .finance), ("stock", .finance), ("wealth", .finance),
            ("passive income", .finance), ("budget", .finance),
            ("viral", .entertainment), ("trending", .entertainment), ("meme", .entertainment), ("celebrity", .entertainment),
            ("learn", .education), ("tutorial", .education), ("course", .education), ("teach", .education),
        ]

        let fullText = transcript.map(\.text).joined(separator: " ").lowercased()
        var matches: [TrendingMatch] = []

        for (keyword, category) in trendingKeywords {
            let occurrences = fullText.components(separatedBy: keyword).count - 1
            if occurrences > 0 {
                let relevance = min(0.99, 0.3 + Double(occurrences) * 0.15)
                let matchedSegment = transcript.first(where: { $0.text.lowercased().contains(keyword) })?.text ?? ""
                matches.append(TrendingMatch(
                    id: UUID(),
                    keyword: keyword.capitalized,
                    category: category,
                    relevanceScore: relevance,
                    matchedText: String(matchedSegment.prefix(80))
                ))
            }
        }

        return matches.sorted { $0.relevanceScore > $1.relevanceScore }
    }
}

enum RetentionEstimator {
    static func estimate(clips: [ClipSegment], totalDuration: TimeInterval) -> [RetentionPoint] {
        guard totalDuration > 0 else { return [] }
        let steps = 10
        let interval = totalDuration / Double(steps)
        var points: [RetentionPoint] = []

        for i in 0...steps {
            let timestamp = Double(i) * interval
            let retention = estimateRetention(at: timestamp, totalDuration: totalDuration, clips: clips)
            let label: String
            if i == 0 { label = "Opening" }
            else if i == steps { label = "End" }
            else if retention > 0.7 { label = "High" }
            else if retention > 0.4 { label = "Medium" }
            else { label = "Drop-off" }

            points.append(RetentionPoint(
                id: UUID(),
                timestamp: timestamp,
                retentionPercent: retention,
                label: label
            ))
        }

        return points
    }

    private static func estimateRetention(at timestamp: TimeInterval, totalDuration: TimeInterval, clips: [ClipSegment]) -> Double {
        let position = timestamp / max(1, totalDuration)
        var base = max(0.1, 1.0 - (position * 0.6))
        let relevantClips = clips.filter { $0.start <= timestamp && $0.end >= timestamp }
        let avgConfidence = relevantClips.isEmpty ? 0.5 : relevantClips.map(\.confidence).reduce(0, +) / Double(relevantClips.count)
        base += (avgConfidence - 0.5) * 0.3
        if position < 0.05 { base = min(1.0, base + 0.15) }
        return min(1.0, max(0.05, base))
    }
}

enum ABHookGenerator {
    static func generate(clips: [ClipSegment]) -> [ABHookVariant] {
        clips.flatMap { clip -> [ABHookVariant] in
            HookStyle.allCases.prefix(3).map { style in
                ABHookVariant(
                    id: UUID(),
                    original: clip.hook,
                    variant: rewriteHook(clip.hook, style: style),
                    style: style,
                    estimatedLift: estimatedLift(for: style)
                )
            }
        }
    }

    private static func rewriteHook(_ hook: String, style: HookStyle) -> String {
        let core = hook.trimmingCharacters(in: .punctuationCharacters).trimmingCharacters(in: .whitespaces)
        switch style {
        case .question:
            return "Did you know \(core.lowercased())?"
        case .statistic:
            return "97% of people miss this: \(core)"
        case .bold:
            return "\(core) — and nobody talks about it."
        case .curiosity:
            return "The real reason \(core.lowercased())..."
        case .story:
            return "I spent 6 months learning this: \(core)"
        case .contrarian:
            return "Everyone says the opposite, but \(core.lowercased())."
        }
    }

    private static func estimatedLift(for style: HookStyle) -> Double {
        switch style {
        case .question: return 0.12
        case .statistic: return 0.18
        case .bold: return 0.15
        case .curiosity: return 0.22
        case .story: return 0.14
        case .contrarian: return 0.20
        }
    }
}

enum OptimalLengthCalculator {
    static func calculate(currentDuration: TimeInterval) -> [PlatformLengthRec] {
        ExportPlatform.allCases.map { platform in
            let (idealMin, idealMax) = idealRange(for: platform)
            let verdict: String
            if currentDuration >= idealMin && currentDuration <= idealMax {
                verdict = "Perfect length for \(platform.rawValue)."
            } else if currentDuration < idealMin {
                verdict = "Too short. Add \(Int(idealMin - currentDuration))s more content."
            } else {
                verdict = "Too long. Trim \(Int(currentDuration - idealMax))s for best performance."
            }

            return PlatformLengthRec(
                id: UUID(),
                platform: platform,
                idealMin: idealMin,
                idealMax: idealMax,
                currentDuration: currentDuration,
                verdict: verdict
            )
        }
    }

    private static func idealRange(for platform: ExportPlatform) -> (TimeInterval, TimeInterval) {
        switch platform {
        case .youtubeShorts: return (15, 58)
        case .tiktok: return (15, 60)
        case .instagramReels: return (15, 90)
        case .x: return (15, 140)
        case .linkedin: return (30, 120)
        }
    }
}

enum EngagementMapper {
    static func map(clips: [ClipSegment], totalDuration: TimeInterval) -> [EngagementZone] {
        guard totalDuration > 0 else { return [] }
        let zoneCount = max(1, Int(totalDuration / 5))
        let zoneDuration = totalDuration / Double(zoneCount)

        return (0..<zoneCount).map { i in
            let start = Double(i) * zoneDuration
            let end = start + zoneDuration
            let overlapping = clips.filter { $0.start < end && $0.end > start }
            let intensity: Double
            let label: String

            if overlapping.isEmpty {
                intensity = 0.2
                label = "Dead Zone"
            } else {
                let avgConf = overlapping.map(\.confidence).reduce(0, +) / Double(overlapping.count)
                intensity = avgConf
                if avgConf > 0.75 { label = "Peak" }
                else if avgConf > 0.55 { label = "Strong" }
                else if avgConf > 0.4 { label = "Medium" }
                else { label = "Weak" }
            }

            return EngagementZone(id: UUID(), start: start, end: end, intensity: intensity, label: label)
        }
    }
}

enum PowerWordDetector {
    static func detect(captions: [CaptionSegment]) -> [PowerWord] {
        let powerList = ["free", "new", "proven", "easy", "secret", "you", "because", "instant", "now", "imagine",
                         "discover", "guarantee", "save", "results", "limited", "exclusive", "powerful", "best",
                         "fast", "simple", "amazing", "breakthrough", "bonus", "hack", "truth", "mistake"]

        var found: [String: (Double, [UUID])] = [:]
        for caption in captions {
            let words = caption.text.lowercased().split(separator: " ").map(String.init)
            for w in words {
                let stripped = w.trimmingCharacters(in: .punctuationCharacters)
                if powerList.contains(stripped) {
                    var (weight, ids) = found[stripped] ?? (0, [])
                    weight += 1.0
                    ids.append(caption.id)
                    found[stripped] = (weight, ids)
                }
            }
        }

        return found.map { word, value in
            PowerWord(id: UUID(), word: word.capitalized, weight: min(1.0, value.0 * 0.15), captionIDs: value.1)
        }
        .sorted { $0.weight > $1.weight }
    }
}

enum VoiceActivityDetector {
    static func detect(transcript: [TranscriptSegment], totalDuration: TimeInterval) -> [VoiceActivitySegment] {
        guard totalDuration > 0 else { return [] }
        var segments: [VoiceActivitySegment] = []
        var cursor: TimeInterval = 0

        for segment in transcript.sorted(by: { $0.start < $1.start }) {
            if segment.start > cursor + 0.5 {
                segments.append(VoiceActivitySegment(
                    id: UUID(),
                    start: cursor,
                    end: segment.start,
                    isSpeech: false,
                    confidence: 0.8
                ))
            }
            segments.append(VoiceActivitySegment(
                id: UUID(),
                start: segment.start,
                end: segment.end,
                isSpeech: true,
                confidence: 0.95
            ))
            cursor = segment.end
        }

        if cursor < totalDuration - 0.5 {
            segments.append(VoiceActivitySegment(
                id: UUID(),
                start: cursor,
                end: totalDuration,
                isSpeech: false,
                confidence: 0.8
            ))
        }

        return segments
    }
}

enum SocialCopyGenerator {
    static func generate(project: StudioProject) -> [SocialCopy] {
        ExportPlatform.allCases.map { platform in
            let title = platformTitle(project: project, platform: platform)
            let body = platformBody(project: project, platform: platform)
            let hashtags = platformHashtags(project: project, platform: platform)
            let cta = platformCTA(platform: platform)

            return SocialCopy(
                id: UUID(),
                platform: platform,
                title: title,
                body: body,
                hashtags: hashtags,
                callToAction: cta
            )
        }
    }

    private static func platformTitle(project: StudioProject, platform: ExportPlatform) -> String {
        let base = project.clips.first?.hook ?? project.title
        switch platform {
        case .youtubeShorts: return "\(base) #shorts"
        case .tiktok: return base
        case .instagramReels: return base
        case .x: return String(base.prefix(240))
        case .linkedin: return "Here's what I learned: \(base)"
        }
    }

    private static func platformBody(project: StudioProject, platform: ExportPlatform) -> String {
        let tags = project.clips.flatMap(\.tags).uniqued()
        let tagLine = tags.isEmpty ? "" : "\nTopics: \(tags.joined(separator: ", "))"
        switch platform {
        case .youtubeShorts:
            return "Quick clip from the latest session.\(tagLine)\n\nFull video on the channel."
        case .tiktok:
            return "Watch until the end for the twist.\(tagLine)"
        case .instagramReels:
            return "Save this for later.\(tagLine)\n\nDrop a comment if this hit different."
        case .x:
            return "Thread-worthy moment clipped.\(tagLine)"
        case .linkedin:
            return "A key takeaway from today's content.\(tagLine)\n\nWhat are your thoughts?"
        }
    }

    private static func platformHashtags(project: StudioProject, platform: ExportPlatform) -> [String] {
        var base = project.clips.flatMap(\.tags).uniqued().map { "#\($0.lowercased().replacingOccurrences(of: " ", with: ""))" }
        switch platform {
        case .youtubeShorts: base.append(contentsOf: ["#shorts", "#youtube"])
        case .tiktok: base.append(contentsOf: ["#fyp", "#viral", "#tiktok"])
        case .instagramReels: base.append(contentsOf: ["#reels", "#explore"])
        case .x: base.append("#thread")
        case .linkedin: base.append(contentsOf: ["#linkedin", "#content"])
        }
        return Array(base.prefix(10))
    }

    private static func platformCTA(platform: ExportPlatform) -> String {
        switch platform {
        case .youtubeShorts: return "Subscribe for more clips like this."
        case .tiktok: return "Follow for Part 2."
        case .instagramReels: return "Save + Share this reel."
        case .x: return "RT if you agree."
        case .linkedin: return "Follow for more insights like this."
        }
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}
