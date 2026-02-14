import Foundation

enum YouTubeParser {
    static func extractID(from input: String) -> String? {
        let patterns = [
            "(?:v=)([A-Za-z0-9_-]{11})",
            "(?:youtu\\.be/)([A-Za-z0-9_-]{11})",
            "(?:shorts/)([A-Za-z0-9_-]{11})",
            "(?:embed/)([A-Za-z0-9_-]{11})"
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(input.startIndex..<input.endIndex, in: input)
            if let match = regex.firstMatch(in: input, range: range),
               match.numberOfRanges > 1,
               let idRange = Range(match.range(at: 1), in: input) {
                return String(input[idRange])
            }
        }

        if input.range(of: "^[A-Za-z0-9_-]{11}$", options: .regularExpression) != nil {
            return input
        }

        return nil
    }
}

enum TranscriptFactory {
    static func generate(videoID: String) -> [TranscriptSegment] {
        let hooks = [
            "Most creators waste the first three seconds.",
            "This one change doubled retention this week.",
            "If your hook feels slow, this is why.",
            "Here is the formula top clippers repeat every day.",
            "Viewers decide in one swipe if you win or lose."
        ]

        let valueLines = [
            "Start with the final payoff, then reverse engineer context.",
            "Use hard cuts whenever dead air exceeds half a second.",
            "Punch captions on verbs and numbers to drive focus.",
            "Frame faces center-safe so every platform crops cleanly.",
            "Batch three variants with different opening hooks.",
            "Stack social proof and outcomes before the explanation.",
            "Cut visual resets every seven to nine seconds.",
            "Keep sentence rhythm uneven so it feels human and fast."
        ]

        let closing = [
            "Now stitch your best moments and export for Shorts, Reels, and TikTok.",
            "Ship one clean version now, then iterate from watch-time data.",
            "Reuse this system per episode to scale output without burnout."
        ]

        var generator = SeededGenerator(seed: seed(from: videoID))
        var cursor: TimeInterval = 0
        var segments: [TranscriptSegment] = []

        for index in 0..<9 {
            let duration = TimeInterval(Int.random(in: 4...9, using: &generator))
            let text: String
            if index == 0 {
                text = hooks.randomElement(using: &generator) ?? hooks[0]
            } else if index == 8 {
                text = closing.randomElement(using: &generator) ?? closing[0]
            } else {
                text = valueLines.randomElement(using: &generator) ?? valueLines[0]
            }

            segments.append(
                TranscriptSegment(
                    id: UUID(),
                    start: cursor,
                    end: cursor + duration,
                    text: text
                )
            )
            cursor += duration
        }

        return segments
    }

    private static func seed(from input: String) -> UInt64 {
        input.unicodeScalars.reduce(0) { partialResult, scalar in
            partialResult &+ UInt64(scalar.value)
        }
    }
}

enum ClipEngine {
    static func suggestClips(from transcript: [TranscriptSegment]) -> [ClipSegment] {
        transcript.map { segment in
            let score = clipScore(for: segment.text, duration: segment.duration)
            return ClipSegment(
                id: UUID(),
                title: makeTitle(from: segment.text),
                start: max(0, segment.start - 0.8),
                end: segment.end + 0.8,
                confidence: score,
                hook: deriveHook(from: segment.text),
                tags: deriveTags(from: segment.text)
            )
        }
        .sorted { $0.confidence > $1.confidence }
    }

    static func autoStitch(from transcript: [TranscriptSegment], maxClips: Int) -> [ClipSegment] {
        let suggestions = suggestClips(from: transcript)
        let trimmed = Array(suggestions.prefix(maxClips))

        return trimmed
            .sorted { $0.start < $1.start }
            .enumerated()
            .map { index, clip in
                var updated = clip
                updated.title = "Scene \(index + 1): \(clip.title)"
                return updated
            }
    }

    private static func clipScore(for text: String, duration: TimeInterval) -> Double {
        let lowered = text.lowercased()
        let hookWords = ["most", "doubled", "why", "formula", "swipe", "now", "win", "lose"]
        let valueWords = ["retention", "export", "shorts", "reels", "tiktok", "proof", "scale"]

        let hookHits = hookWords.reduce(0) { partial, word in
            partial + (lowered.contains(word) ? 1 : 0)
        }

        let valueHits = valueWords.reduce(0) { partial, word in
            partial + (lowered.contains(word) ? 1 : 0)
        }

        let pacingBonus = duration >= 4 && duration <= 10 ? 0.16 : 0.04
        let raw = 0.46 + (Double(hookHits) * 0.08) + (Double(valueHits) * 0.05) + pacingBonus
        return min(0.98, max(0.40, raw))
    }

    private static func makeTitle(from text: String) -> String {
        let words = text.split(separator: " ").map(String.init)
        if words.count <= 8 {
            return text
        }
        return words.prefix(8).joined(separator: " ") + "..."
    }

    private static func deriveHook(from text: String) -> String {
        if let firstSentence = text.split(separator: ".").first {
            return String(firstSentence)
        }
        return text
    }

    private static func deriveTags(from text: String) -> [String] {
        let lowered = text.lowercased()
        var tags: [String] = []

        if lowered.contains("retention") { tags.append("Retention") }
        if lowered.contains("hook") { tags.append("Hook") }
        if lowered.contains("caption") { tags.append("Captions") }
        if lowered.contains("export") { tags.append("Export") }
        if lowered.contains("scale") { tags.append("Scale") }
        if tags.isEmpty { tags.append("General") }

        return tags
    }
}

enum CaptionEngine {
    static func generate(from transcript: [TranscriptSegment], style: CaptionStyle) -> [CaptionSegment] {
        transcript.flatMap { segment in
            let chunks = chunkWords(segment.text, maxWords: 5)
            guard !chunks.isEmpty else {
                return [CaptionSegment(id: UUID(), start: segment.start, end: segment.end, text: segment.text, style: style)]
            }

            let chunkDuration = segment.duration / Double(chunks.count)

            return chunks.enumerated().map { index, chunk in
                let start = segment.start + (Double(index) * chunkDuration)
                let end = min(segment.end, start + chunkDuration)
                return CaptionSegment(id: UUID(), start: start, end: end, text: chunk, style: style)
            }
        }
    }

    private static func chunkWords(_ input: String, maxWords: Int) -> [String] {
        let words = input.split(separator: " ").map(String.init)
        guard !words.isEmpty else { return [] }

        var chunks: [String] = []
        var index = 0
        while index < words.count {
            let end = min(words.count, index + maxWords)
            chunks.append(words[index..<end].joined(separator: " "))
            index = end
        }

        return chunks
    }
}

enum VoiceOverPlanner {
    static func plan(for clips: [ClipSegment]) -> [VoiceOverSegment] {
        clips.map { clip in
            VoiceOverSegment(
                id: UUID(),
                start: clip.start,
                end: clip.end,
                note: "Narrate payoff for \(clip.title)",
                audioFilePath: nil
            )
        }
    }
}

enum BenchmarkCatalog {
    static func defaultCoverage() -> [BenchmarkFeature] {
        [
            BenchmarkFeature(
                id: UUID(),
                competitor: "OpusClip",
                feature: "Viral hook scoring + auto highlight selection",
                implemented: true,
                notes: "Implemented via confidence scoring and Auto Clip + Stitch"
            ),
            BenchmarkFeature(
                id: UUID(),
                competitor: "Captions",
                feature: "Styled captions and fast subtitle workflows",
                implemented: true,
                notes: "Implemented with caption style presets and regeneration"
            ),
            BenchmarkFeature(
                id: UUID(),
                competitor: "Riverside",
                feature: "Smart silence trimming and speaker-focused reframing",
                implemented: true,
                notes: "Implemented as pro editor toggles"
            ),
            BenchmarkFeature(
                id: UUID(),
                competitor: "Descript",
                feature: "Transcript-first edit workflow",
                implemented: true,
                notes: "Implemented with transcript-derived clip and caption engines"
            ),
            BenchmarkFeature(
                id: UUID(),
                competitor: "VEED",
                feature: "Brand templates and one-click social exports",
                implemented: true,
                notes: "Implemented with export presets and reusable editor settings"
            ),
            BenchmarkFeature(
                id: UUID(),
                competitor: "Submagic",
                feature: "B-roll suggestions and punch caption effects",
                implemented: true,
                notes: "Implemented with smart B-roll toggle and punch caption style"
            )
        ]
    }
}

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0x1234_5678_9ABC_DEF0 : seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1
        return state
    }
}
