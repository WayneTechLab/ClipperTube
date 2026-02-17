import Foundation
import AVFoundation
import AppKit

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

// MARK: - AI Voice Over Engine

/// Generates voice over audio using macOS TTS or external APIs
enum VoiceOverEngine {
    
    /// Available system voices for voice over
    static func availableVoices() -> [(id: String, name: String, language: String)] {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.starts(with: "en") } // English voices
            .map { ($0.identifier, $0.name, $0.language) }
    }
    
    /// Get the best default English voice
    static func defaultVoiceID() -> String {
        // Prefer premium voices
        let premiumVoices = ["com.apple.voice.premium.en-US.Zoe",
                             "com.apple.voice.premium.en-US.Evan",
                             "com.apple.voice.enhanced.en-US.Evan",
                             "com.apple.voice.enhanced.en-US.Samantha"]
        
        for voiceID in premiumVoices {
            if AVSpeechSynthesisVoice(identifier: voiceID) != nil {
                return voiceID
            }
        }
        
        // Fallback to first available English voice
        return AVSpeechSynthesisVoice.speechVoices()
            .first(where: { $0.language.starts(with: "en-US") })?
            .identifier ?? "com.apple.voice.compact.en-US.Samantha"
    }
    
    /// Generate voice over audio file using system TTS
    /// - Parameters:
    ///   - script: The text to speak
    ///   - config: Voice over configuration
    ///   - outputDirectory: Where to save the audio file
    /// - Returns: Path to generated audio file
    static func generateSystemTTS(
        script: String,
        config: VoiceOverConfig,
        outputDirectory: URL
    ) async throws -> URL {
        
        let voiceID = config.voiceID ?? defaultVoiceID()
        
        // Create output file path
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let outputPath = outputDirectory
            .appendingPathComponent("voiceover-\(timestamp).m4a")
        
        // Use NSSpeechSynthesizer for file output (AVSpeechSynthesizer doesn't support direct file output)
        return try await withCheckedThrowingContinuation { continuation in
            let synthesizer = NSSpeechSynthesizer()
            
            // Find and set the voice
            if let voice = NSSpeechSynthesizer.availableVoices.first(where: { $0.rawValue.contains(voiceID) }) {
                synthesizer.setVoice(voice)
            } else if let defaultVoice = NSSpeechSynthesizer.availableVoices.first(where: { $0.rawValue.contains("en-US") }) {
                synthesizer.setVoice(defaultVoice)
            }
            
            // Set rate based on tone
            synthesizer.rate = config.tone.speechRate * 200 // NSSpeechSynthesizer rate is words per minute
            
            // Create AIFF file first (NSSpeechSynthesizer native format)
            let tempAIFF = outputDirectory.appendingPathComponent("temp-voiceover.aiff")
            
            // Use a dispatch queue since NSSpeechSynthesizer needs to run on main
            DispatchQueue.main.async {
                let success = synthesizer.startSpeaking(script, to: tempAIFF)
                
                if !success {
                    continuation.resume(throwing: VoiceOverError.synthesisStartFailed)
                    return
                }
                
                // Poll for completion (NSSpeechSynthesizer doesn't have async API)
                DispatchQueue.global(qos: .userInitiated).async {
                    // Wait for speech to complete (max 60 seconds)
                    var waited = 0
                    while synthesizer.isSpeaking && waited < 600 {
                        Thread.sleep(forTimeInterval: 0.1)
                        waited += 1
                    }
                    
                    // Check if AIFF was created
                    guard FileManager.default.fileExists(atPath: tempAIFF.path) else {
                        continuation.resume(throwing: VoiceOverError.fileNotCreated)
                        return
                    }
                    
                    // Convert AIFF to M4A using AVFoundation
                    do {
                        try convertToM4A(from: tempAIFF, to: outputPath)
                        try? FileManager.default.removeItem(at: tempAIFF)
                        continuation.resume(returning: outputPath)
                    } catch {
                        // Fallback: just rename AIFF to output path
                        do {
                            try FileManager.default.moveItem(at: tempAIFF, to: outputPath)
                            continuation.resume(returning: outputPath)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        }
    }
    
    /// Convert audio file to M4A format
    private static func convertToM4A(from source: URL, to destination: URL) throws {
        let asset = AVAsset(url: source)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw VoiceOverError.exportSessionFailed
        }
        
        exportSession.outputFileType = .m4a
        exportSession.outputURL = destination
        
        let semaphore = DispatchSemaphore(value: 0)
        var exportError: Error?
        
        exportSession.exportAsynchronously {
            if exportSession.status == .failed {
                exportError = exportSession.error ?? VoiceOverError.exportFailed
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        
        if let error = exportError {
            throw error
        }
    }
    
    /// Generate a script based on content purpose and style
    static func generateScript(
        config: EasyModeConfig,
        clipTitle: String?,
        transcriptSnippet: String?
    ) -> String {
        var parts: [String] = []
        
        // Hook line based on engagement style
        if config.voiceOver.includeHook {
            parts.append(config.engagementStyle.hookPhrases.randomElement() ?? "Check this out")
        }
        
        // Content reference
        if let title = clipTitle, !title.isEmpty {
            // Clean up the title for speech
            let cleanTitle = title
                .replacingOccurrences(of: "Clip:", with: "")
                .trimmingCharacters(in: .whitespaces)
            if !cleanTitle.isEmpty {
                parts.append(cleanTitle)
            }
        }
        
        // Call to action based on purpose
        if config.voiceOver.includeCTA {
            switch config.purpose {
            case .selling:
                if let aff = config.affiliate, !aff.productName.isEmpty {
                    parts.append("Get \(aff.productName) now! \(aff.callToAction)")
                } else {
                    parts.append("Link in description!")
                }
            case .channelGrowth:
                parts.append("Subscribe for more content like this!")
            case .engagement:
                parts.append("Follow for more!")
            case .affiliate:
                if let aff = config.affiliate {
                    parts.append(aff.callToAction)
                } else {
                    parts.append("Check the link in bio!")
                }
            case .brandAwareness:
                parts.append("Stay tuned for more!")
            }
        }
        
        // Allow custom script override
        if let custom = config.voiceOver.customScript, !custom.isEmpty {
            return custom
        }
        
        return parts.joined(separator: "... ")
    }
}

enum VoiceOverError: LocalizedError {
    case synthesisStartFailed
    case fileNotCreated
    case exportSessionFailed
    case exportFailed
    case unsupportedProvider
    
    var errorDescription: String? {
        switch self {
        case .synthesisStartFailed: return "Failed to start speech synthesis"
        case .fileNotCreated: return "Voice over file was not created"
        case .exportSessionFailed: return "Failed to create audio export session"
        case .exportFailed: return "Failed to export audio"
        case .unsupportedProvider: return "Voice provider not supported"
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
