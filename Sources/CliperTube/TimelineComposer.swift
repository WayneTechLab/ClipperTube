import AVFoundation
import CoreGraphics
import Foundation

enum TimelineComposerError: LocalizedError {
    case noTimelineClips
    case missingSource(UUID)
    case invalidSourceURL(String)
    case sourceFileNotFound(String)
    case sourceHasNoVideo(String)
    case cannotCreateExportSession
    case exportFailed(String)

    var errorDescription: String? {
        switch self {
        case .noTimelineClips:
            return "Timeline has no video clips. Add clips in the Timeline section first."
        case .missingSource(let id):
            return "Missing media source for timeline clip: \(id.uuidString)."
        case .invalidSourceURL(let path):
            return "Invalid media source URL: \(path)."
        case .sourceFileNotFound(let path):
            return "Media file not found: \(path)."
        case .sourceHasNoVideo(let path):
            return "Selected file has no video track: \(path)."
        case .cannotCreateExportSession:
            return "Could not create export session for this timeline."
        case .exportFailed(let message):
            return "Export failed: \(message)"
        }
    }
}

struct TimelineCompositionResult {
    var composition: AVMutableComposition
    var audioMix: AVAudioMix?
    var videoComposition: AVVideoComposition?
    var duration: CMTime
}

private struct VideoSegmentDescriptor {
    var timeRange: CMTimeRange
    var displaySize: CGSize
    var normalizedTransform: CGAffineTransform
}

enum TimelineComposer {
    static func build(
        project: StudioProject,
        includeVoiceOvers: Bool = true,
        includeAuxAudio: Bool = true
    ) async throws -> TimelineCompositionResult {
        guard project.timelineVideoClips.isEmpty == false else {
            throw TimelineComposerError.noTimelineClips
        }

        let composition = AVMutableComposition()
        guard let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw TimelineComposerError.cannotCreateExportSession
        }

        var primaryAudioTrack: AVMutableCompositionTrack?
        var mixParameters: [AVAudioMixInputParameters] = []
        var videoSegments: [VideoSegmentDescriptor] = []
        var cursor = CMTime.zero

        for clip in project.timelineVideoClips {
            guard let source = project.mediaSources.first(where: { $0.id == clip.sourceID }) else {
                throw TimelineComposerError.missingSource(clip.sourceID)
            }

            guard let sourceURL = mediaURL(from: source.filePath) else {
                throw TimelineComposerError.invalidSourceURL(source.filePath)
            }
            if sourceURL.isFileURL,
               FileManager.default.fileExists(atPath: sourceURL.path) == false {
                throw TimelineComposerError.sourceFileNotFound(source.filePath)
            }

            let asset = AVURLAsset(url: sourceURL)
            let sourceVideoTracks = try await asset.loadTracks(withMediaType: .video)
            guard let sourceVideoTrack = sourceVideoTracks.first else {
                throw TimelineComposerError.sourceHasNoVideo(source.filePath)
            }
            let sourceTransform = try await sourceVideoTrack.load(.preferredTransform)
            let sourceNaturalSize = try await sourceVideoTrack.load(.naturalSize)
            let transformedRect = CGRect(origin: .zero, size: sourceNaturalSize).applying(sourceTransform)
            let displaySize = CGSize(
                width: max(1, abs(transformedRect.width)),
                height: max(1, abs(transformedRect.height))
            )
            let normalizedTransform = normalizeTransform(sourceTransform, transformedRect: transformedRect)

            let sourceDuration = max(0.1, seconds(try await asset.load(.duration)))
            let inPoint = clamp(clip.inPoint, lower: 0, upper: max(0, sourceDuration - 0.1))
            let outPoint = clamp(clip.outPoint, lower: inPoint + 0.1, upper: sourceDuration)
            let sourceRange = CMTimeRange(
                start: CMTime(seconds: inPoint, preferredTimescale: 600),
                duration: CMTime(seconds: outPoint - inPoint, preferredTimescale: 600)
            )

            let insertionStart = cursor
            try compositionVideoTrack.insertTimeRange(sourceRange, of: sourceVideoTrack, at: insertionStart)

            var insertedRange = CMTimeRange(start: insertionStart, duration: sourceRange.duration)
            let rate = max(0.1, clip.playbackRate)
            if abs(rate - 1.0) > 0.0001 {
                let scaledDuration = CMTimeMultiplyByFloat64(sourceRange.duration, multiplier: 1.0 / rate)
                compositionVideoTrack.scaleTimeRange(insertedRange, toDuration: scaledDuration)
                insertedRange.duration = scaledDuration
            }
            videoSegments.append(
                VideoSegmentDescriptor(
                    timeRange: insertedRange,
                    displaySize: displaySize,
                    normalizedTransform: normalizedTransform
                )
            )

            if clip.muted == false {
                let sourceAudioTracks = try await asset.loadTracks(withMediaType: .audio)
                guard let sourceAudio = sourceAudioTracks.first else {
                    cursor = cursor + insertedRange.duration
                    continue
                }

                if primaryAudioTrack == nil {
                    primaryAudioTrack = composition.addMutableTrack(
                        withMediaType: .audio,
                        preferredTrackID: kCMPersistentTrackID_Invalid
                    )
                }

                if let primaryAudioTrack {
                    try primaryAudioTrack.insertTimeRange(sourceRange, of: sourceAudio, at: insertionStart)
                    if abs(rate - 1.0) > 0.0001 {
                        primaryAudioTrack.scaleTimeRange(
                            CMTimeRange(start: insertionStart, duration: sourceRange.duration),
                            toDuration: insertedRange.duration
                        )
                    }
                }
            }

            cursor = cursor + insertedRange.duration
        }

        if let primaryAudioTrack {
            let params = AVMutableAudioMixInputParameters(track: primaryAudioTrack)
            params.setVolume(1.0, at: .zero)
            mixParameters.append(params)
        }

        if includeAuxAudio {
            for audioClip in project.timelineAudioClips {
                guard let sourceURL = mediaURL(from: audioClip.filePath) else {
                    continue
                }
                if sourceURL.isFileURL,
                   FileManager.default.fileExists(atPath: sourceURL.path) == false {
                    continue
                }
                let asset = AVURLAsset(url: sourceURL)
                let sourceAudioTracks = try await asset.loadTracks(withMediaType: .audio)
                guard let sourceAudio = sourceAudioTracks.first else {
                    continue
                }

                let sourceDuration = max(0.1, seconds(try await asset.load(.duration)))
                let inPoint = clamp(audioClip.inPoint, lower: 0, upper: max(0, sourceDuration - 0.1))
                let outPoint = clamp(audioClip.outPoint, lower: inPoint + 0.1, upper: sourceDuration)

                let timeRange = CMTimeRange(
                    start: CMTime(seconds: inPoint, preferredTimescale: 600),
                    duration: CMTime(seconds: outPoint - inPoint, preferredTimescale: 600)
                )

                guard let overlayTrack = composition.addMutableTrack(
                    withMediaType: .audio,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                ) else {
                    continue
                }

                let startTime = CMTime(seconds: max(0, audioClip.timelineStart), preferredTimescale: 600)
                try overlayTrack.insertTimeRange(timeRange, of: sourceAudio, at: startTime)

                let params = AVMutableAudioMixInputParameters(track: overlayTrack)
                params.setVolume(Float(clamp(audioClip.volume, lower: 0, upper: 2.0)), at: .zero)
                mixParameters.append(params)
            }
        }

        if includeVoiceOvers {
            for voiceOver in project.voiceOvers {
                guard let path = voiceOver.audioFilePath else { continue }
                guard let sourceURL = mediaURL(from: path) else {
                    continue
                }
                if sourceURL.isFileURL,
                   FileManager.default.fileExists(atPath: sourceURL.path) == false {
                    continue
                }

                let asset = AVURLAsset(url: sourceURL)
                let sourceAudioTracks = try await asset.loadTracks(withMediaType: .audio)
                guard let sourceAudio = sourceAudioTracks.first else {
                    continue
                }

                let fileDuration = max(0.1, seconds(try await asset.load(.duration)))
                let preferredDuration = max(0.1, voiceOver.end - voiceOver.start)
                let insertDuration = min(fileDuration, preferredDuration)

                let range = CMTimeRange(
                    start: .zero,
                    duration: CMTime(seconds: insertDuration, preferredTimescale: 600)
                )

                guard let voiceTrack = composition.addMutableTrack(
                    withMediaType: .audio,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                ) else {
                    continue
                }

                let startTime = CMTime(seconds: max(0, voiceOver.start), preferredTimescale: 600)
                try voiceTrack.insertTimeRange(range, of: sourceAudio, at: startTime)

                let params = AVMutableAudioMixInputParameters(track: voiceTrack)
                params.setVolume(1.0, at: .zero)
                mixParameters.append(params)
            }
        }

        let audioMix: AVAudioMix? = {
            guard mixParameters.isEmpty == false else { return nil }
            let mix = AVMutableAudioMix()
            mix.inputParameters = mixParameters
            return mix
        }()
        let videoComposition = makeVideoComposition(
            for: compositionVideoTrack,
            segments: videoSegments,
            aspectRatio: project.editor.aspectRatio
        )

        return TimelineCompositionResult(
            composition: composition,
            audioMix: audioMix,
            videoComposition: videoComposition,
            duration: composition.duration
        )
    }

    static func export(
        project: StudioProject,
        outputURL: URL,
        renderQuality: RenderQuality,
        includeVoiceOvers: Bool = true,
        includeAuxAudio: Bool = true
    ) async throws {
        let result = try await build(
            project: project,
            includeVoiceOvers: includeVoiceOvers,
            includeAuxAudio: includeAuxAudio
        )
        guard let session = makeExportSession(for: result.composition, preferredPreset: presetName(for: renderQuality)) else {
            throw TimelineComposerError.cannotCreateExportSession
        }

        try? FileManager.default.removeItem(at: outputURL)
        session.outputURL = outputURL
        session.outputFileType = .mov
        session.shouldOptimizeForNetworkUse = true
        session.audioMix = result.audioMix
        session.videoComposition = result.videoComposition

        do {
            try await session.export(to: outputURL, as: .mov)
        } catch {
            throw TimelineComposerError.exportFailed(error.localizedDescription)
        }
    }

    private static func presetName(for quality: RenderQuality) -> String {
        switch quality {
        case .standard:
            return AVAssetExportPreset1280x720
        case .high:
            return AVAssetExportPreset1920x1080
        case .ultra:
            return AVAssetExportPreset3840x2160
        }
    }

    private static func makeExportSession(for asset: AVAsset, preferredPreset: String) -> AVAssetExportSession? {
        let fallbackPresets = [
            preferredPreset,
            AVAssetExportPresetHighestQuality,
            AVAssetExportPreset1920x1080,
            AVAssetExportPreset1280x720,
            AVAssetExportPresetMediumQuality
        ]

        for preset in fallbackPresets {
            if let session = AVAssetExportSession(asset: asset, presetName: preset) {
                return session
            }
        }

        return nil
    }

    private static func makeVideoComposition(
        for track: AVCompositionTrack,
        segments: [VideoSegmentDescriptor],
        aspectRatio: AspectRatio
    ) -> AVVideoComposition? {
        guard segments.isEmpty == false else { return nil }

        let ratio = aspectRatioValue(for: aspectRatio)
        let maxRequiredHeight = segments
            .map { requiredRenderHeight(for: $0.displaySize, targetRatio: ratio) }
            .max() ?? 1080

        let renderHeight = max(240, even(maxRequiredHeight))
        let renderWidth = max(240, even(renderHeight * ratio))
        let renderSize = CGSize(width: renderWidth, height: renderHeight)

        let instructions: [AVMutableVideoCompositionInstruction] = segments.map { segment in
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
            layerInstruction.setTransform(fittedTransform(for: segment, renderSize: renderSize), at: segment.timeRange.start)

            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = segment.timeRange
            instruction.layerInstructions = [layerInstruction]
            return instruction
        }

        let composition = AVMutableVideoComposition()
        composition.renderSize = renderSize
        composition.frameDuration = CMTime(value: 1, timescale: 30)
        composition.instructions = instructions
        return composition
    }

    private static func requiredRenderHeight(for size: CGSize, targetRatio: CGFloat) -> CGFloat {
        let width = max(1, size.width)
        let height = max(1, size.height)
        let sourceRatio = width / height

        if sourceRatio > targetRatio {
            return width / targetRatio
        }
        return height
    }

    private static func fittedTransform(for segment: VideoSegmentDescriptor, renderSize: CGSize) -> CGAffineTransform {
        let sourceWidth = max(1, segment.displaySize.width)
        let sourceHeight = max(1, segment.displaySize.height)
        let scale = min(renderSize.width / sourceWidth, renderSize.height / sourceHeight)
        let scaledWidth = sourceWidth * scale
        let scaledHeight = sourceHeight * scale

        var transform = segment.normalizedTransform.scaledBy(x: scale, y: scale)
        transform.tx += (renderSize.width - scaledWidth) / 2
        transform.ty += (renderSize.height - scaledHeight) / 2
        return transform
    }

    private static func normalizeTransform(_ transform: CGAffineTransform, transformedRect: CGRect) -> CGAffineTransform {
        var normalized = transform
        normalized.tx -= transformedRect.origin.x
        normalized.ty -= transformedRect.origin.y
        return normalized
    }

    private static func aspectRatioValue(for aspectRatio: AspectRatio) -> CGFloat {
        switch aspectRatio {
        case .vertical:
            return 9.0 / 16.0
        case .square:
            return 1.0
        case .landscape:
            return 16.0 / 9.0
        }
    }

    private static func even(_ value: CGFloat) -> CGFloat {
        let rounded = ceil(value)
        return rounded.truncatingRemainder(dividingBy: 2) == 0 ? rounded : rounded + 1
    }

    private static func mediaURL(from raw: String) -> URL? {
        if let parsed = URL(string: raw),
           let scheme = parsed.scheme?.lowercased(),
           ["http", "https", "file"].contains(scheme) {
            return parsed
        }
        return URL(fileURLWithPath: raw)
    }

    private static func seconds(_ time: CMTime) -> TimeInterval {
        let value = CMTimeGetSeconds(time)
        return value.isFinite ? max(0, value) : 0
    }

    private static func clamp(_ value: Double, lower: Double, upper: Double) -> Double {
        min(upper, max(lower, value))
    }
}
