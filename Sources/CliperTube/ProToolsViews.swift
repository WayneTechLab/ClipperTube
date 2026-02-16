import Foundation
import SwiftUI

// MARK: - File-Level Helpers

private func ptFormatTime(_ value: TimeInterval) -> String {
    let total = Int(max(0, value).rounded())
    let minutes = total / 60
    let seconds = total % 60
    return String(format: "%02d:%02d", minutes, seconds)
}

private func ptFormatPercent(_ value: Double) -> String {
    String(format: "%.0f%%", value * 100)
}

private func ptFormatCurrency(_ value: Double) -> String {
    String(format: "$%.2f", value)
}

private func ptFormatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

private func ptShortDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    return formatter.string(from: date)
}

// MARK: - Shared Sub-Components

private struct ScorePill: View {
    var label: String
    var value: Double

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(ptFormatPercent(value))
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(value > 0.7 ? .green : value > 0.4 ? .orange : .red)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct SectionEmptyText: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// ============================================================
// MARK: - 1. Clip Intelligence View (Tools 1-8)
// ============================================================

struct ClipIntelligenceView: View {
    @EnvironmentObject private var store: StudioStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Clip Intelligence")
                    .font(.title2.weight(.bold))

                Text("AI-powered analysis to predict virality, grade hooks, match trends, estimate retention, generate A/B variants, optimize length, and map engagement.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if store.activeProject != nil {
                    HStack(spacing: 10) {
                        Button("Run All Analysis") {
                            store.runViralAnalysis()
                            store.runHookAnalysis()
                            store.runTrendingMatch()
                            store.runRetentionEstimate()
                            store.runABHookGeneration()
                            store.runOptimalLengthCalc()
                            store.runEngagementMapping()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Quick Re-Clip") {
                            store.duplicateProjectForReClip()
                        }
                        .buttonStyle(.bordered)
                    }

                    ViralScorePredictorSection()
                    HookStrengthAnalyzerSection()
                    TrendingKeywordMatcherSection()
                    RetentionCurveEstimatorSection()
                    ABHookGeneratorSection()
                    OptimalClipLengthSection()
                    EngagementHeatmapSection()
                } else {
                    Text("Create or open a project first to use Clip Intelligence tools.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(22)
        }
    }
}

// MARK: Tool 1 - Viral Score Predictor

private struct ViralScorePredictorSection: View {
    @EnvironmentObject private var store: StudioStore

    var body: some View {
        GroupBox("Viral Score Predictor") {
            VStack(alignment: .leading, spacing: 10) {
                Button("Analyze Viral Potential") {
                    store.runViralAnalysis()
                }
                .buttonStyle(.bordered)

                let reports = store.activeProject?.proTools.viralScoreReports ?? []

                if reports.isEmpty {
                    SectionEmptyText(text: "Run analysis to see viral score breakdowns for each clip.")
                } else {
                    ForEach(reports) { report in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Overall: \(ptFormatPercent(report.overallScore))")
                                    .font(.headline)
                                Spacer()
                                Text(report.generatedAt, style: .time)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            HStack(spacing: 12) {
                                ScorePill(label: "Hook", value: report.hookScore)
                                ScorePill(label: "Pacing", value: report.pacingScore)
                                ScorePill(label: "Keywords", value: report.keywordScore)
                                ScorePill(label: "Duration", value: report.durationScore)
                            }
                            Text(report.breakdown)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if report.id != reports.last?.id { Divider() }
                    }
                }
            }
        }
    }
}

// MARK: Tool 2 - Hook Strength Analyzer

private struct HookStrengthAnalyzerSection: View {
    @EnvironmentObject private var store: StudioStore

    var body: some View {
        GroupBox("Hook Strength Analyzer") {
            VStack(alignment: .leading, spacing: 10) {
                Button("Analyze Hooks") {
                    store.runHookAnalysis()
                }
                .buttonStyle(.bordered)

                let analyses = store.activeProject?.proTools.hookAnalyses ?? []

                if analyses.isEmpty {
                    SectionEmptyText(text: "Run analysis to grade each clip hook on clarity, urgency, specificity, and curiosity.")
                } else {
                    ForEach(analyses) { analysis in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(analysis.text)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(2)
                                Spacer()
                                Text("Grade: \(analysis.overallGrade)")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(.blue)
                            }
                            HStack(spacing: 12) {
                                ScorePill(label: "Clarity", value: analysis.clarityScore)
                                ScorePill(label: "Urgency", value: analysis.urgencyScore)
                                ScorePill(label: "Specificity", value: analysis.specificityScore)
                                ScorePill(label: "Curiosity", value: analysis.curiosityScore)
                            }
                            ForEach(analysis.suggestions, id: \.self) { suggestion in
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "lightbulb")
                                        .font(.caption)
                                        .foregroundStyle(.yellow)
                                    Text(suggestion)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        if analysis.id != analyses.last?.id { Divider() }
                    }
                }
            }
        }
    }
}

// MARK: Tool 3 - Trending Keyword Matcher

private struct TrendingKeywordMatcherSection: View {
    @EnvironmentObject private var store: StudioStore

    var body: some View {
        GroupBox("Trending Keyword Matcher") {
            VStack(alignment: .leading, spacing: 10) {
                Button("Scan for Trending Keywords") {
                    store.runTrendingMatch()
                }
                .buttonStyle(.bordered)

                let matches = store.activeProject?.proTools.trendingMatches ?? []

                if matches.isEmpty {
                    SectionEmptyText(text: "Scan your transcript to find trending keywords and topic matches.")
                } else {
                    ForEach(matches) { match in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(match.keyword)
                                    .font(.subheadline.weight(.semibold))
                                Text(match.category.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.purple.opacity(0.12))
                                    .clipShape(Capsule())
                                if !match.matchedText.isEmpty {
                                    Text("\"\(match.matchedText)\"")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                            Text(ptFormatPercent(match.relevanceScore))
                                .font(.body.weight(.semibold).monospacedDigit())
                                .foregroundStyle(match.relevanceScore > 0.6 ? .green : .orange)
                        }
                        if match.id != matches.last?.id { Divider() }
                    }
                }
            }
        }
    }
}

// MARK: Tool 4 - Retention Curve Estimator

private struct RetentionCurveEstimatorSection: View {
    @EnvironmentObject private var store: StudioStore

    var body: some View {
        GroupBox("Retention Curve Estimator") {
            VStack(alignment: .leading, spacing: 10) {
                Button("Estimate Retention Curve") {
                    store.runRetentionEstimate()
                }
                .buttonStyle(.bordered)

                let points = store.activeProject?.proTools.retentionCurve ?? []

                if points.isEmpty {
                    SectionEmptyText(text: "Estimate how viewer retention changes across the clip timeline.")
                } else {
                    HStack(alignment: .bottom, spacing: 3) {
                        ForEach(points) { point in
                            VStack(spacing: 2) {
                                Text(ptFormatPercent(point.retentionPercent))
                                    .font(.system(size: 8).monospacedDigit())
                                    .foregroundStyle(.secondary)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(retentionColor(point.retentionPercent))
                                    .frame(width: 28, height: max(4, CGFloat(point.retentionPercent) * 80))
                                Text(ptFormatTime(point.timestamp))
                                    .font(.system(size: 7).monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 6)

                    ForEach(points) { point in
                        HStack {
                            Text(ptFormatTime(point.timestamp))
                                .font(.caption.monospacedDigit())
                                .frame(width: 44, alignment: .leading)
                            ProgressView(value: max(0, min(1, point.retentionPercent)))
                                .tint(retentionColor(point.retentionPercent))
                            Text(ptFormatPercent(point.retentionPercent))
                                .font(.caption.monospacedDigit())
                                .frame(width: 36, alignment: .trailing)
                            Text(point.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 64, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }

    private func retentionColor(_ value: Double) -> Color {
        if value > 0.7 { return .green }
        if value > 0.4 { return .orange }
        return .red
    }
}

// MARK: Tool 5 - A/B Hook Generator

private struct ABHookGeneratorSection: View {
    @EnvironmentObject private var store: StudioStore

    var body: some View {
        GroupBox("A/B Hook Generator") {
            VStack(alignment: .leading, spacing: 10) {
                Button("Generate Hook Variants") {
                    store.runABHookGeneration()
                }
                .buttonStyle(.bordered)

                let variants = store.activeProject?.proTools.abHookVariants ?? []

                if variants.isEmpty {
                    SectionEmptyText(text: "Generate alternative hooks styled as questions, statistics, bold claims, and more.")
                } else {
                    ForEach(variants) { variant in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(variant.style.rawValue)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.12))
                                    .clipShape(Capsule())
                                Spacer()
                                Text("+\(ptFormatPercent(variant.estimatedLift)) est. lift")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.green)
                            }
                            Text("Original: \(variant.original)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Text("Variant: \(variant.variant)")
                                .font(.subheadline)
                                .lineLimit(2)
                        }
                        if variant.id != variants.last?.id { Divider() }
                    }
                }
            }
        }
    }
}

// MARK: Tool 6 - Optimal Clip Length

private struct OptimalClipLengthSection: View {
    @EnvironmentObject private var store: StudioStore

    var body: some View {
        GroupBox("Optimal Clip Length") {
            VStack(alignment: .leading, spacing: 10) {
                Button("Calculate Optimal Length") {
                    store.runOptimalLengthCalc()
                }
                .buttonStyle(.bordered)

                let recs = store.activeProject?.proTools.platformLengthRecs ?? []

                if recs.isEmpty {
                    SectionEmptyText(text: "Calculate ideal clip duration for each platform based on current timeline length.")
                } else {
                    ForEach(recs) { rec in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(rec.platform.rawValue)
                                    .font(.subheadline.weight(.semibold))
                                Text("Ideal: \(ptFormatTime(rec.idealMin)) - \(ptFormatTime(rec.idealMax))")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Current: \(ptFormatTime(rec.currentDuration))")
                                    .font(.caption.monospacedDigit())
                                Text(rec.verdict)
                                    .font(.caption)
                                    .foregroundStyle(rec.verdict.contains("Perfect") ? .green : .orange)
                                    .lineLimit(1)
                            }
                        }
                        if rec.id != recs.last?.id { Divider() }
                    }
                }
            }
        }
    }
}

// MARK: Tool 7 - Engagement Heatmap

private struct EngagementHeatmapSection: View {
    @EnvironmentObject private var store: StudioStore

    var body: some View {
        GroupBox("Engagement Heatmap") {
            VStack(alignment: .leading, spacing: 10) {
                Button("Generate Engagement Map") {
                    store.runEngagementMapping()
                }
                .buttonStyle(.bordered)

                let zones = store.activeProject?.proTools.engagementZones ?? []

                if zones.isEmpty {
                    SectionEmptyText(text: "Map high-engagement and dead zones across your clip timeline.")
                } else {
                    HStack(spacing: 1) {
                        ForEach(zones) { zone in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(engagementColor(zone.intensity))
                                .frame(height: 30)
                                .overlay(
                                    Text(zone.label)
                                        .font(.system(size: 8).weight(.medium))
                                        .foregroundStyle(.white)
                                )
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(.vertical, 4)

                    ForEach(zones) { zone in
                        HStack {
                            Text("\(ptFormatTime(zone.start)) - \(ptFormatTime(zone.end))")
                                .font(.caption.monospacedDigit())
                                .frame(width: 100, alignment: .leading)
                            Text(zone.label)
                                .font(.caption.weight(.medium))
                                .frame(width: 64)
                            ProgressView(value: max(0, min(1, zone.intensity)))
                                .tint(engagementColor(zone.intensity))
                            Text(ptFormatPercent(zone.intensity))
                                .font(.caption.monospacedDigit())
                                .frame(width: 36, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }

    private func engagementColor(_ value: Double) -> Color {
        if value > 0.75 { return .red }
        if value > 0.55 { return .orange }
        if value > 0.4 { return .yellow }
        return .blue.opacity(0.6)
    }
}

// ============================================================
// MARK: - 2. Audio Studio View (Tools 9-14)
// ============================================================

struct AudioStudioView: View {
    @EnvironmentObject private var store: StudioStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Audio Studio")
                    .font(.title2.weight(.bold))

                Text("Music beds, sound effects, ducking, loudness normalization, voice activity detection, and audio fades.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if store.activeProject != nil {
                    MusicBedPresetsSection()
                    SFXTriggerPointsSection()
                    AudioDuckingSection()
                    LoudnessNormalizationSection()
                    VoiceActivityDetectionSection()
                    AudioFadeSection()
                } else {
                    Text("Create or open a project first to use Audio Studio tools.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(22)
        }
    }
}

// MARK: Tool 9 - Music Bed Presets

private struct MusicBedPresetsSection: View {
    @EnvironmentObject private var store: StudioStore
    @State private var presetName: String = ""
    @State private var selectedGenre: MusicGenre = .lofi
    @State private var selectedMood: MusicMood = .chill
    @State private var bpmText: String = "90"

    var body: some View {
        GroupBox("Music Bed Presets") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    TextField("Preset Name", text: $presetName)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 160)

                    Picker("Genre", selection: $selectedGenre) {
                        ForEach(MusicGenre.allCases) { genre in
                            Text(genre.rawValue).tag(genre)
                        }
                    }
                    .frame(maxWidth: 130)

                    Picker("Mood", selection: $selectedMood) {
                        ForEach(MusicMood.allCases) { mood in
                            Text(mood.rawValue).tag(mood)
                        }
                    }
                    .frame(maxWidth: 130)

                    TextField("BPM", text: $bpmText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 54)

                    Button("Add Preset") {
                        let bpmVal = Int(bpmText) ?? 90
                        let name = presetName.trimmingCharacters(in: .whitespaces).isEmpty
                            ? "\(selectedGenre.rawValue) \(selectedMood.rawValue)"
                            : presetName
                        var presets = store.proToolsBinding(for: \.musicBedPresets, fallback: []).wrappedValue
                        presets.append(MusicBedPreset(
                            id: UUID(),
                            name: name,
                            genre: selectedGenre,
                            mood: selectedMood,
                            bpm: bpmVal,
                            isActive: presets.isEmpty
                        ))
                        store.proToolsBinding(for: \.musicBedPresets, fallback: []).wrappedValue = presets
                        presetName = ""
                    }
                    .buttonStyle(.bordered)
                }

                let presets = store.activeProject?.proTools.musicBedPresets ?? []

                if presets.isEmpty {
                    SectionEmptyText(text: "No music bed presets configured. Add one above.")
                } else {
                    ForEach(presets) { preset in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.name)
                                    .font(.subheadline.weight(.medium))
                                Text("\(preset.genre.rawValue) / \(preset.mood.rawValue) / \(preset.bpm) BPM")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if preset.isActive {
                                Text("Active")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.16))
                                    .clipShape(Capsule())
                            } else {
                                Button("Activate") {
                                    var list = store.proToolsBinding(for: \.musicBedPresets, fallback: []).wrappedValue
                                    for i in list.indices {
                                        list[i].isActive = (list[i].id == preset.id)
                                    }
                                    store.proToolsBinding(for: \.musicBedPresets, fallback: []).wrappedValue = list
                                }
                                .buttonStyle(.bordered)
                            }
                            Button("Remove") {
                                var list = store.proToolsBinding(for: \.musicBedPresets, fallback: []).wrappedValue
                                list.removeAll { $0.id == preset.id }
                                store.proToolsBinding(for: \.musicBedPresets, fallback: []).wrappedValue = list
                            }
                            .buttonStyle(.bordered)
                        }
                        if preset.id != presets.last?.id { Divider() }
                    }
                }
            }
        }
    }
}

// MARK: Tool 10 - SFX Trigger Points

private struct SFXTriggerPointsSection: View {
    @EnvironmentObject private var store: StudioStore
    @State private var sfxTimestamp: String = "0"
    @State private var selectedSFXType: SFXType = .whoosh

    var body: some View {
        GroupBox("SFX Trigger Points") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    TextField("Timestamp (s)", text: $sfxTimestamp)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)

                    Picker("SFX Type", selection: $selectedSFXType) {
                        ForEach(SFXType.allCases) { sfx in
                            Text(sfx.rawValue).tag(sfx)
                        }
                    }
                    .frame(maxWidth: 140)

                    Button("Add SFX Trigger") {
                        let ts = Double(sfxTimestamp) ?? 0
                        store.addSFXTrigger(at: ts, type: selectedSFXType)
                    }
                    .buttonStyle(.bordered)
                }

                let triggers = store.activeProject?.proTools.sfxTriggers ?? []

                if triggers.isEmpty {
                    SectionEmptyText(text: "No SFX triggers placed. Add sound effects at specific timestamps.")
                } else {
                    ForEach(triggers) { trigger in
                        HStack {
                            Text(ptFormatTime(trigger.timestamp))
                                .font(.caption.monospacedDigit())
                                .frame(width: 44, alignment: .leading)
                            Text(trigger.sfxType.rawValue)
                                .font(.subheadline.weight(.medium))
                            Text(trigger.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("Vol: \(String(format: "%.0f%%", trigger.volume * 100))")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Button("Remove") {
                                store.removeSFXTrigger(trigger.id)
                            }
                            .buttonStyle(.bordered)
                        }
                        if trigger.id != triggers.last?.id { Divider() }
                    }
                }
            }
        }
    }
}

// MARK: Tool 11 - Audio Ducking

private struct AudioDuckingSection: View {
    @EnvironmentObject private var store: StudioStore

    var body: some View {
        GroupBox("Audio Ducking") {
            VStack(alignment: .leading, spacing: 10) {
                Toggle(
                    "Enable Audio Ducking",
                    isOn: store.proToolsBinding(for: \.audioDucking.enabled, fallback: true)
                )

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Duck Level")
                            .font(.caption)
                        Slider(
                            value: store.proToolsBinding(for: \.audioDucking.duckLevel, fallback: 0.2),
                            in: 0...1,
                            step: 0.05
                        )
                        Text(String(format: "%.0f%%", (store.activeProject?.proTools.audioDucking.duckLevel ?? 0.2) * 100))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Threshold (dB)")
                            .font(.caption)
                        Slider(
                            value: store.proToolsBinding(for: \.audioDucking.threshold, fallback: -30),
                            in: -60...0,
                            step: 1
                        )
                        Text(String(format: "%.0f dB", store.activeProject?.proTools.audioDucking.threshold ?? -30))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Attack (ms)")
                            .font(.caption)
                        Slider(
                            value: store.proToolsBinding(for: \.audioDucking.attackMs, fallback: 50),
                            in: 5...500,
                            step: 5
                        )
                        Text(String(format: "%.0f ms", store.activeProject?.proTools.audioDucking.attackMs ?? 50))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Release (ms)")
                            .font(.caption)
                        Slider(
                            value: store.proToolsBinding(for: \.audioDucking.releaseMs, fallback: 300),
                            in: 50...2000,
                            step: 10
                        )
                        Text(String(format: "%.0f ms", store.activeProject?.proTools.audioDucking.releaseMs ?? 300))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: Tool 12 - Loudness Normalization

private struct LoudnessNormalizationSection: View {
    @EnvironmentObject private var store: StudioStore

    var body: some View {
        GroupBox("Loudness Normalization") {
            VStack(alignment: .leading, spacing: 10) {
                Toggle(
                    "Enable Loudness Normalization",
                    isOn: store.proToolsBinding(for: \.loudnessTarget.enabled, fallback: true)
                )

                Picker(
                    "Target Platform",
                    selection: store.proToolsBinding(for: \.loudnessTarget.platform, fallback: .youtubeShorts)
                ) {
                    ForEach(ExportPlatform.allCases) { platform in
                        Text(platform.rawValue).tag(platform)
                    }
                }
                .pickerStyle(.segmented)

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Target LUFS")
                            .font(.caption)
                        Slider(
                            value: store.proToolsBinding(for: \.loudnessTarget.targetLUFS, fallback: -14.0),
                            in: -24...(-6),
                            step: 0.5
                        )
                        Text(String(format: "%.1f LUFS", store.activeProject?.proTools.loudnessTarget.targetLUFS ?? -14.0))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("True Peak (dBTP)")
                            .font(.caption)
                        Slider(
                            value: store.proToolsBinding(for: \.loudnessTarget.truePeak, fallback: -1.0),
                            in: -6...0,
                            step: 0.1
                        )
                        Text(String(format: "%.1f dBTP", store.activeProject?.proTools.loudnessTarget.truePeak ?? -1.0))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: Tool 13 - Voice Activity Detection

private struct VoiceActivityDetectionSection: View {
    @EnvironmentObject private var store: StudioStore

    var body: some View {
        GroupBox("Voice Activity Detection") {
            VStack(alignment: .leading, spacing: 10) {
                Button("Detect Voice Activity") {
                    store.runVoiceActivityDetection()
                }
                .buttonStyle(.bordered)

                let segments = store.activeProject?.proTools.voiceActivitySegments ?? []

                if segments.isEmpty {
                    SectionEmptyText(text: "Detect speech and silence segments across the timeline.")
                } else {
                    let speechCount = segments.filter(\.isSpeech).count
                    let silenceCount = segments.filter { !$0.isSpeech }.count
                    let speechDuration = segments.filter(\.isSpeech).reduce(0.0) { $0 + ($1.end - $1.start) }
                    let silenceDuration = segments.filter { !$0.isSpeech }.reduce(0.0) { $0 + ($1.end - $1.start) }

                    HStack(spacing: 16) {
                        VStack(spacing: 2) {
                            Text("\(speechCount)")
                                .font(.title3.weight(.semibold))
                            Text("Speech (\(ptFormatTime(speechDuration)))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        VStack(spacing: 2) {
                            Text("\(silenceCount)")
                                .font(.title3.weight(.semibold))
                            Text("Silence (\(ptFormatTime(silenceDuration)))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)

                    HStack(spacing: 1) {
                        ForEach(segments) { segment in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(segment.isSpeech ? Color.green : Color.gray.opacity(0.3))
                                .frame(height: 20)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(.vertical, 2)

                    ForEach(segments.prefix(20)) { segment in
                        HStack {
                            Text("\(ptFormatTime(segment.start)) - \(ptFormatTime(segment.end))")
                                .font(.caption.monospacedDigit())
                                .frame(width: 100, alignment: .leading)
                            Text(segment.isSpeech ? "Speech" : "Silence")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(segment.isSpeech ? .green : .secondary)
                                .frame(width: 52)
                            Spacer()
                            Text("Confidence: \(ptFormatPercent(segment.confidence))")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }

                    if segments.count > 20 {
                        Text("Showing 20 of \(segments.count) segments.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: Tool 14 - Audio Fade

private struct AudioFadeSection: View {
    @EnvironmentObject private var store: StudioStore

    var body: some View {
        GroupBox("Audio Fade") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fade In Duration")
                            .font(.caption)
                        Slider(
                            value: store.proToolsBinding(for: \.audioFade.fadeInDuration, fallback: 0.5),
                            in: 0...5,
                            step: 0.1
                        )
                        Text(String(format: "%.1f s", store.activeProject?.proTools.audioFade.fadeInDuration ?? 0.5))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fade In Curve")
                            .font(.caption)
                        Picker(
                            "Fade In Curve",
                            selection: store.proToolsBinding(for: \.audioFade.fadeInCurve, fallback: .linear)
                        ) {
                            ForEach(FadeCurve.allCases) { curve in
                                Text(curve.rawValue).tag(curve)
                            }
                        }
                        .labelsHidden()
                    }
                }

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fade Out Duration")
                            .font(.caption)
                        Slider(
                            value: store.proToolsBinding(for: \.audioFade.fadeOutDuration, fallback: 1.0),
                            in: 0...5,
                            step: 0.1
                        )
                        Text(String(format: "%.1f s", store.activeProject?.proTools.audioFade.fadeOutDuration ?? 1.0))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fade Out Curve")
                            .font(.caption)
                        Picker(
                            "Fade Out Curve",
                            selection: store.proToolsBinding(for: \.audioFade.fadeOutCurve, fallback: .easeOut)
                        ) {
                            ForEach(FadeCurve.allCases) { curve in
                                Text(curve.rawValue).tag(curve)
                            }
                        }
                        .labelsHidden()
                    }
                }
            }
        }
    }
}

// ============================================================
// MARK: - 3. Distribution Center View (Tools 15-21)
// ============================================================

struct DistributionCenterView: View {
    @EnvironmentObject private var store: StudioStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Distribution Center")
                    .font(.title2.weight(.bold))

                Text("Batch exports, thumbnail selection, platform crop previews, watermarks, export templates, social copy, and publish scheduling.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if store.activeProject != nil {
                    BatchExportQueueSection()
                    ThumbnailFrameSelectorSection()
                    PlatformCropPreviewSection()
                    WatermarkOverlaySection()
                    ExportTemplatesSection()
                    SocialCopyGeneratorSection()
                    PublishScheduleSection()
                } else {
                    Text("Create or open a project first to use Distribution Center tools.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(22)
        }
    }
}

// MARK: Tool 15 - Batch Export Queue

private struct BatchExportQueueSection: View {
    @EnvironmentObject private var store: StudioStore
    @State private var batchPlatform: ExportPlatform = .youtubeShorts
    @State private var batchQuality: RenderQuality = .high
    @State private var batchAspect: AspectRatio = .vertical

    var body: some View {
        GroupBox("Batch Export Queue") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Picker("Platform", selection: $batchPlatform) {
                        ForEach(ExportPlatform.allCases) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .frame(maxWidth: 160)

                    Picker("Quality", selection: $batchQuality) {
                        ForEach(RenderQuality.allCases) { q in
                            Text(q.rawValue).tag(q)
                        }
                    }
                    .frame(maxWidth: 100)

                    Picker("Aspect", selection: $batchAspect) {
                        ForEach(AspectRatio.allCases) { a in
                            Text(a.rawValue).tag(a)
                        }
                    }
                    .frame(maxWidth: 80)

                    Button("Add to Queue") {
                        store.addBatchExportItem(platform: batchPlatform, quality: batchQuality, aspect: batchAspect)
                    }
                    .buttonStyle(.bordered)

                    Button("Add All Platforms") {
                        for platform in ExportPlatform.allCases {
                            store.addBatchExportItem(platform: platform, quality: batchQuality, aspect: batchAspect)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

                let queue = store.activeProject?.proTools.batchExportQueue ?? []

                if queue.isEmpty {
                    SectionEmptyText(text: "No items in batch export queue. Add platform targets above.")
                } else {
                    ForEach(queue) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.platform.rawValue)
                                    .font(.subheadline.weight(.medium))
                                Text("\(item.quality.rawValue) / \(item.aspectRatio.rawValue) / Captions: \(item.includeCaptions ? "Yes" : "No")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(item.status.rawValue)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(batchStatusColor(item.status).opacity(0.16))
                                .clipShape(Capsule())
                            Button("Remove") {
                                store.removeBatchExportItem(item.id)
                            }
                            .buttonStyle(.bordered)
                        }
                        if item.id != queue.last?.id { Divider() }
                    }
                }
            }
        }
    }

    private func batchStatusColor(_ status: BatchExportStatus) -> Color {
        switch status {
        case .queued: return .blue
        case .rendering: return .orange
        case .completed: return .green
        case .failed: return .red
        }
    }
}

// MARK: Tool 16 - Thumbnail Frame Selector

private struct ThumbnailFrameSelectorSection: View {
    @EnvironmentObject private var store: StudioStore
    @State private var thumbTimestamp: String = "5"

    var body: some View {
        GroupBox("Thumbnail Frame Selector") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    TextField("Timestamp (s)", text: $thumbTimestamp)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)

                    Button("Capture Frame") {
                        let ts = Double(thumbTimestamp) ?? 5
                        store.addThumbnailCandidate(at: ts)
                    }
                    .buttonStyle(.bordered)

                    Button("Capture at 25%") {
                        let dur = store.activeTimelineDuration
                        store.addThumbnailCandidate(at: dur * 0.25)
                    }
                    .buttonStyle(.bordered)

                    Button("Capture at 50%") {
                        let dur = store.activeTimelineDuration
                        store.addThumbnailCandidate(at: dur * 0.5)
                    }
                    .buttonStyle(.bordered)

                    Button("Capture at 75%") {
                        let dur = store.activeTimelineDuration
                        store.addThumbnailCandidate(at: dur * 0.75)
                    }
                    .buttonStyle(.bordered)
                }

                let candidates = store.activeProject?.proTools.thumbnailCandidates ?? []

                if candidates.isEmpty {
                    SectionEmptyText(text: "No thumbnail candidates captured. Select timestamps above.")
                } else {
                    ForEach(candidates) { candidate in
                        HStack {
                            Text(ptFormatTime(candidate.timestamp))
                                .font(.caption.monospacedDigit())
                                .frame(width: 44)
                            Text(candidate.label)
                                .font(.subheadline)
                            Spacer()
                            if candidate.isSelected {
                                Text("Selected")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.16))
                                    .clipShape(Capsule())
                            } else {
                                Button("Select") {
                                    store.selectThumbnailCandidate(candidate.id)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        if candidate.id != candidates.last?.id { Divider() }
                    }
                }
            }
        }
    }
}

// MARK: Tool 17 - Platform Crop Preview

private struct PlatformCropPreviewSection: View {
    @EnvironmentObject private var store: StudioStore
    @State private var previewPlatform: ExportPlatform = .youtubeShorts

    var body: some View {
        GroupBox("Platform Crop Preview") {
            VStack(alignment: .leading, spacing: 10) {
                Picker("Preview Platform", selection: $previewPlatform) {
                    ForEach(ExportPlatform.allCases) { platform in
                        Text(platform.rawValue).tag(platform)
                    }
                }
                .pickerStyle(.segmented)

                let ratio = cropRatio(for: previewPlatform)
                let safeZone = safeZoneInsets(for: previewPlatform)

                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.1))
                                .aspectRatio(ratio, contentMode: .fit)
                                .frame(height: 180)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(Color.accentColor, lineWidth: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(Color.red.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                        .padding(.top, safeZone.top)
                                        .padding(.bottom, safeZone.bottom)
                                        .padding(.leading, safeZone.left)
                                        .padding(.trailing, safeZone.right)
                                )
                                .overlay(
                                    Text(previewPlatform.rawValue)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.secondary)
                                )
                        }
                        Text("Safe zone shown with dashed border")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Platform Specs")
                            .font(.subheadline.weight(.semibold))
                        platformSpecRow("Aspect Ratio", value: cropLabel(for: previewPlatform))
                        platformSpecRow("Max Duration", value: maxDuration(for: previewPlatform))
                        platformSpecRow("Recommended", value: recommendedRes(for: previewPlatform))
                        platformSpecRow("Top Safe Zone", value: "\(Int(safeZone.top))pt")
                        platformSpecRow("Bottom Safe Zone", value: "\(Int(safeZone.bottom))pt")
                    }
                }
            }
        }
    }

    private func platformSpecRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .font(.caption.weight(.medium))
        }
    }

    private func cropRatio(for platform: ExportPlatform) -> CGFloat {
        switch platform {
        case .youtubeShorts, .tiktok, .instagramReels: return 9.0 / 16.0
        case .x: return 16.0 / 9.0
        case .linkedin: return 1.0
        }
    }

    private func cropLabel(for platform: ExportPlatform) -> String {
        switch platform {
        case .youtubeShorts, .tiktok, .instagramReels: return "9:16 Vertical"
        case .x: return "16:9 Landscape"
        case .linkedin: return "1:1 Square"
        }
    }

    private func maxDuration(for platform: ExportPlatform) -> String {
        switch platform {
        case .youtubeShorts: return "60s"
        case .tiktok: return "60s (up to 10m)"
        case .instagramReels: return "90s"
        case .x: return "140s"
        case .linkedin: return "10m"
        }
    }

    private func recommendedRes(for platform: ExportPlatform) -> String {
        switch platform {
        case .youtubeShorts, .tiktok, .instagramReels: return "1080x1920"
        case .x: return "1920x1080"
        case .linkedin: return "1080x1080"
        }
    }

    private func safeZoneInsets(for platform: ExportPlatform) -> (top: CGFloat, bottom: CGFloat, left: CGFloat, right: CGFloat) {
        switch platform {
        case .youtubeShorts: return (14, 28, 8, 8)
        case .tiktok: return (18, 34, 8, 8)
        case .instagramReels: return (16, 30, 8, 8)
        case .x: return (8, 8, 12, 12)
        case .linkedin: return (8, 8, 10, 10)
        }
    }
}

// MARK: Tool 18 - Watermark Overlay

private struct WatermarkOverlaySection: View {
    @EnvironmentObject private var store: StudioStore

    var body: some View {
        GroupBox("Watermark Overlay") {
            VStack(alignment: .leading, spacing: 10) {
                Toggle(
                    "Enable Watermark",
                    isOn: store.proToolsBinding(for: \.watermark.enabled, fallback: false)
                )

                TextField(
                    "Watermark Text",
                    text: store.proToolsBinding(for: \.watermark.text, fallback: "")
                )
                .textFieldStyle(.roundedBorder)

                HStack(spacing: 16) {
                    Picker(
                        "Position",
                        selection: store.proToolsBinding(for: \.watermark.position, fallback: .bottomRight)
                    ) {
                        ForEach(WatermarkPosition.allCases) { pos in
                            Text(pos.rawValue).tag(pos)
                        }
                    }
                    .frame(maxWidth: 160)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Opacity")
                            .font(.caption)
                        Slider(
                            value: store.proToolsBinding(for: \.watermark.opacity, fallback: 0.5),
                            in: 0.1...1.0,
                            step: 0.05
                        )
                        Text(String(format: "%.0f%%", (store.activeProject?.proTools.watermark.opacity ?? 0.5) * 100))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Font Size")
                            .font(.caption)
                        Slider(
                            value: store.proToolsBinding(for: \.watermark.fontSize, fallback: 14.0),
                            in: 8...48,
                            step: 1
                        )
                        Text(String(format: "%.0fpt", store.activeProject?.proTools.watermark.fontSize ?? 14.0))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                let config = store.activeProject?.proTools.watermark ?? .default
                if config.enabled && !config.text.isEmpty {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.8))
                            .frame(height: 80)
                        Text(config.text)
                            .font(.system(size: config.fontSize))
                            .foregroundStyle(.white.opacity(config.opacity))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: watermarkAlignment(config.position))
                            .padding(8)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private func watermarkAlignment(_ position: WatermarkPosition) -> Alignment {
        switch position {
        case .topLeft: return .topLeading
        case .topRight: return .topTrailing
        case .bottomLeft: return .bottomLeading
        case .bottomRight: return .bottomTrailing
        case .center: return .center
        }
    }
}

// MARK: Tool 19 - Export Templates

private struct ExportTemplatesSection: View {
    @EnvironmentObject private var store: StudioStore
    @State private var templateName: String = ""

    var body: some View {
        GroupBox("Export Templates") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    TextField("Template Name", text: $templateName)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 220)

                    Button("Save Current Settings as Template") {
                        let name = templateName.trimmingCharacters(in: .whitespaces)
                        guard !name.isEmpty else { return }
                        store.saveExportTemplate(name: name)
                        templateName = ""
                    }
                    .buttonStyle(.bordered)
                }

                let templates = store.activeProject?.proTools.exportTemplates ?? []

                if templates.isEmpty {
                    SectionEmptyText(text: "No export templates saved. Name and save your current editor and export settings.")
                } else {
                    ForEach(templates) { template in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(template.name)
                                    .font(.subheadline.weight(.medium))
                                Text("\(template.preset.platform.rawValue) / \(template.preset.renderQuality.rawValue) / \(template.editorSnapshot.aspectRatio.rawValue)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Created: \(ptShortDate(template.createdAt))")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Button("Remove") {
                                var list = store.proToolsBinding(for: \.exportTemplates, fallback: []).wrappedValue
                                list.removeAll { $0.id == template.id }
                                store.proToolsBinding(for: \.exportTemplates, fallback: []).wrappedValue = list
                            }
                            .buttonStyle(.bordered)
                        }
                        if template.id != templates.last?.id { Divider() }
                    }
                }
            }
        }
    }
}

// MARK: Tool 20 - Social Copy Generator

private struct SocialCopyGeneratorSection: View {
    @EnvironmentObject private var store: StudioStore
    @State private var expandedPlatform: UUID?

    var body: some View {
        GroupBox("Social Copy Generator") {
            VStack(alignment: .leading, spacing: 10) {
                Button("Generate Social Copy for All Platforms") {
                    store.generateSocialCopy()
                }
                .buttonStyle(.borderedProminent)

                let copies = store.activeProject?.proTools.socialCopies ?? []

                if copies.isEmpty {
                    SectionEmptyText(text: "Generate platform-specific titles, descriptions, hashtags, and calls-to-action.")
                } else {
                    ForEach(copies) { copy in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(copy.platform.rawValue)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Button(expandedPlatform == copy.id ? "Collapse" : "Expand") {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        expandedPlatform = expandedPlatform == copy.id ? nil : copy.id
                                    }
                                }
                                .buttonStyle(.bordered)
                            }

                            Text(copy.title)
                                .font(.caption.weight(.medium))
                                .lineLimit(expandedPlatform == copy.id ? nil : 1)

                            if expandedPlatform == copy.id {
                                Text(copy.body)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if !copy.hashtags.isEmpty {
                                    Text(copy.hashtags.joined(separator: " "))
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                }

                                Text("CTA: \(copy.callToAction)")
                                    .font(.caption.italic())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if copy.id != copies.last?.id { Divider() }
                    }
                }
            }
        }
    }
}

// MARK: Tool 21 - Publish Schedule

private struct PublishScheduleSection: View {
    @EnvironmentObject private var store: StudioStore
    @State private var schedulePlatform: ExportPlatform = .youtubeShorts
    @State private var scheduleDate: Date = Date()
    @State private var scheduleTitle: String = ""

    var body: some View {
        GroupBox("Publish Schedule") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Picker("Platform", selection: $schedulePlatform) {
                        ForEach(ExportPlatform.allCases) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .frame(maxWidth: 160)

                    DatePicker("Date", selection: $scheduleDate, displayedComponents: [.date, .hourAndMinute])
                        .frame(maxWidth: 240)

                    TextField("Title / Notes", text: $scheduleTitle)
                        .textFieldStyle(.roundedBorder)

                    Button("Add Entry") {
                        let title = scheduleTitle.trimmingCharacters(in: .whitespaces)
                        guard !title.isEmpty else { return }
                        store.addScheduleEntry(platform: schedulePlatform, date: scheduleDate, title: title)
                        scheduleTitle = ""
                        scheduleDate = Date()
                    }
                    .buttonStyle(.bordered)
                }

                let schedule = store.activeProject?.proTools.publishSchedule ?? []

                if schedule.isEmpty {
                    SectionEmptyText(text: "No publish schedule entries. Plan your content calendar above.")
                } else {
                    ForEach(schedule) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.title)
                                    .font(.subheadline.weight(.medium))
                                Text("\(entry.platform.rawValue) / \(ptFormatDate(entry.scheduledDate))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Picker(
                                "Status",
                                selection: Binding(
                                    get: { entry.status },
                                    set: { store.updateScheduleStatus(entry.id, status: $0) }
                                )
                            ) {
                                ForEach(PublishStatus.allCases) { status in
                                    Text(status.rawValue).tag(status)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(maxWidth: 100)
                        }
                        if entry.id != schedule.last?.id { Divider() }
                    }
                }
            }
        }
    }
}

// ============================================================
// MARK: - 4. Revenue & Clients View (Tools 22-27)
// ============================================================

struct RevenueClientsView: View {
    @EnvironmentObject private var store: StudioStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Revenue & Clients")
                    .font(.title2.weight(.bold))

                Text("Track clip revenue, calculate costs, monitor ROI, manage clients, generate invoices, and time editing sessions.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if store.activeProject != nil {
                    ROIDashboardSection()
                    RevenuePerClipSection()
                    CostCalculatorSection()
                    ClientManagerSection()
                    InvoiceGeneratorSection()
                    SessionTimerSection()
                } else {
                    Text("Create or open a project first to use Revenue and Client tools.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(22)
        }
    }
}

// MARK: Tool 22 - Revenue Per Clip

private struct RevenuePerClipSection: View {
    @EnvironmentObject private var store: StudioStore
    @State private var clipTitle: String = ""
    @State private var revenuePlatform: ExportPlatform = .youtubeShorts
    @State private var viewsText: String = ""
    @State private var revenueText: String = ""

    var body: some View {
        GroupBox("Revenue Per Clip") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    TextField("Clip Title", text: $clipTitle)
                        .textFieldStyle(.roundedBorder)

                    Picker("Platform", selection: $revenuePlatform) {
                        ForEach(ExportPlatform.allCases) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .frame(maxWidth: 160)

                    TextField("Views", text: $viewsText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)

                    TextField("Revenue $", text: $revenueText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)

                    Button("Add Entry") {
                        let title = clipTitle.trimmingCharacters(in: .whitespaces)
                        guard !title.isEmpty else { return }
                        let views = Int(viewsText) ?? 0
                        let revenue = Double(revenueText) ?? 0
                        store.addClipRevenue(clipTitle: title, platform: revenuePlatform, views: views, revenue: revenue)
                        clipTitle = ""
                        viewsText = ""
                        revenueText = ""
                    }
                    .buttonStyle(.bordered)
                }

                let entries = store.activeProject?.proTools.clipRevenue ?? []

                if entries.isEmpty {
                    SectionEmptyText(text: "No revenue entries yet. Track earnings per clip and platform.")
                } else {
                    let totalRevenue = entries.reduce(0.0) { $0 + $1.revenue }
                    let totalViews = entries.reduce(0) { $0 + $1.views }

                    HStack(spacing: 16) {
                        VStack(spacing: 2) {
                            Text(ptFormatCurrency(totalRevenue))
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.green)
                            Text("Total Revenue")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        VStack(spacing: 2) {
                            Text("\(totalViews)")
                                .font(.title3.weight(.semibold))
                            Text("Total Views")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if totalViews > 0 {
                            VStack(spacing: 2) {
                                Text(ptFormatCurrency(totalRevenue / Double(totalViews) * 1000))
                                    .font(.title3.weight(.semibold))
                                Text("RPM")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)

                    ForEach(entries) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.clipTitle)
                                    .font(.subheadline.weight(.medium))
                                Text("\(entry.platform.rawValue) / \(ptShortDate(entry.recordedAt))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(entry.views) views")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Text(ptFormatCurrency(entry.revenue))
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(.green)
                        }
                        if entry.id != entries.last?.id { Divider() }
                    }
                }
            }
        }
    }
}

// MARK: Tool 23 - Cost Calculator

private struct CostCalculatorSection: View {
    @EnvironmentObject private var store: StudioStore
    @State private var costCategory: CostCategory = .editingTime
    @State private var costAmountText: String = ""
    @State private var costDescription: String = ""

    var body: some View {
        GroupBox("Cost Calculator") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Picker("Category", selection: $costCategory) {
                        ForEach(CostCategory.allCases) { cat in
                            Text(cat.label).tag(cat)
                        }
                    }
                    .frame(maxWidth: 140)

                    TextField("Amount $", text: $costAmountText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)

                    TextField("Description", text: $costDescription)
                        .textFieldStyle(.roundedBorder)

                    Button("Add Cost") {
                        let amount = Double(costAmountText) ?? 0
                        let desc = costDescription.trimmingCharacters(in: .whitespaces)
                        guard amount > 0 else { return }
                        store.addCostEntry(category: costCategory, amount: amount, description: desc.isEmpty ? costCategory.label : desc)
                        costAmountText = ""
                        costDescription = ""
                    }
                    .buttonStyle(.bordered)
                }

                let costs = store.activeProject?.proTools.costs ?? []

                if costs.isEmpty {
                    SectionEmptyText(text: "No cost entries yet. Track expenses per category.")
                } else {
                    let totalCost = costs.reduce(0.0) { $0 + $1.amount }
                    let grouped = Dictionary(grouping: costs, by: \.category)

                    HStack(spacing: 16) {
                        VStack(spacing: 2) {
                            Text(ptFormatCurrency(totalCost))
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.red)
                            Text("Total Costs")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        ForEach(CostCategory.allCases.filter { grouped[$0] != nil }, id: \.self) { cat in
                            let catTotal = grouped[cat]?.reduce(0.0) { $0 + $1.amount } ?? 0
                            VStack(spacing: 2) {
                                Text(ptFormatCurrency(catTotal))
                                    .font(.caption.weight(.semibold).monospacedDigit())
                                Text(cat.label)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)

                    ForEach(costs) { cost in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(cost.description)
                                    .font(.subheadline)
                                Text("\(cost.category.label) / \(ptShortDate(cost.date))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(ptFormatCurrency(cost.amount))
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(.red)
                        }
                        if cost.id != costs.last?.id { Divider() }
                    }
                }
            }
        }
    }
}

// MARK: Tool 24 - ROI Dashboard

private struct ROIDashboardSection: View {
    @EnvironmentObject private var store: StudioStore

    var body: some View {
        GroupBox("ROI Dashboard") {
            VStack(alignment: .leading, spacing: 10) {
                let revenue = store.activeProject?.proTools.clipRevenue ?? []
                let costs = store.activeProject?.proTools.costs ?? []
                let sessions = store.activeProject?.proTools.editingSessions ?? []

                let totalRevenue = revenue.reduce(0.0) { $0 + $1.revenue }
                let totalCost = costs.reduce(0.0) { $0 + $1.amount }
                let profit = totalRevenue - totalCost
                let roi = totalCost > 0 ? (profit / totalCost) * 100 : 0
                let totalViews = revenue.reduce(0) { $0 + $1.views }
                let totalClips = revenue.count
                let totalSessionMinutes = sessions.reduce(0.0) { $0 + $1.durationMinutes }
                let totalClipsProduced = sessions.reduce(0) { $0 + $1.clipsProduced }

                HStack(spacing: 0) {
                    roiCard(title: "Total Revenue", value: ptFormatCurrency(totalRevenue), color: .green)
                    roiCard(title: "Total Costs", value: ptFormatCurrency(totalCost), color: .red)
                    roiCard(title: "Net Profit", value: ptFormatCurrency(profit), color: profit >= 0 ? .green : .red)
                    roiCard(title: "ROI", value: String(format: "%.1f%%", roi), color: roi >= 0 ? .green : .red)
                }

                HStack(spacing: 0) {
                    roiCard(title: "Total Views", value: "\(totalViews)", color: .blue)
                    roiCard(title: "Revenue Entries", value: "\(totalClips)", color: .blue)
                    roiCard(title: "Edit Time", value: String(format: "%.0f min", totalSessionMinutes), color: .orange)
                    roiCard(title: "Clips Produced", value: "\(totalClipsProduced)", color: .purple)
                }

                if totalClipsProduced > 0 && totalRevenue > 0 {
                    HStack(spacing: 0) {
                        roiCard(title: "Rev/Clip", value: ptFormatCurrency(totalRevenue / Double(max(1, totalClips))), color: .green)
                        roiCard(title: "Cost/Clip", value: ptFormatCurrency(totalCost / Double(max(1, totalClipsProduced))), color: .red)
                        roiCard(title: "Min/Clip", value: String(format: "%.1f", totalSessionMinutes / Double(totalClipsProduced)), color: .orange)
                        roiCard(title: "Rev/1K Views", value: totalViews > 0 ? ptFormatCurrency(totalRevenue / Double(totalViews) * 1000) : "$0.00", color: .green)
                    }
                }

                if totalRevenue == 0 && totalCost == 0 {
                    Text("Add revenue and cost entries to see ROI calculations.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }

    private func roiCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(2)
    }
}

// MARK: Tool 25 - Client Manager

private struct ClientManagerSection: View {
    @EnvironmentObject private var store: StudioStore
    @State private var clientName: String = ""
    @State private var clientEmail: String = ""
    @State private var clientNotes: String = ""

    var body: some View {
        GroupBox("Client Manager") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    TextField("Client Name", text: $clientName)
                        .textFieldStyle(.roundedBorder)

                    TextField("Email", text: $clientEmail)
                        .textFieldStyle(.roundedBorder)

                    TextField("Notes", text: $clientNotes)
                        .textFieldStyle(.roundedBorder)

                    Button("Add Client") {
                        let name = clientName.trimmingCharacters(in: .whitespaces)
                        guard !name.isEmpty else { return }
                        store.addClient(name: name, email: clientEmail, notes: clientNotes)
                        clientName = ""
                        clientEmail = ""
                        clientNotes = ""
                    }
                    .buttonStyle(.bordered)
                }

                let clients = store.activeProject?.proTools.clients ?? []

                if clients.isEmpty {
                    SectionEmptyText(text: "No clients registered. Add clients to track projects and invoices.")
                } else {
                    ForEach(clients) { client in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(client.name)
                                    .font(.subheadline.weight(.medium))
                                if !client.contactEmail.isEmpty {
                                    Text(client.contactEmail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if !client.notes.isEmpty {
                                    Text(client.notes)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(client.projectCount) projects")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                Text(ptFormatCurrency(client.totalRevenue))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.green)
                            }
                            Text(ptShortDate(client.createdAt))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .frame(width: 64, alignment: .trailing)
                        }
                        if client.id != clients.last?.id { Divider() }
                    }
                }
            }
        }
    }
}

// MARK: Tool 26 - Invoice Generator

private struct InvoiceGeneratorSection: View {
    @EnvironmentObject private var store: StudioStore
    @State private var invoiceClientName: String = ""
    @State private var invoiceNotes: String = ""
    @State private var lineItems: [InvoiceLineItem] = []
    @State private var lineDescription: String = ""
    @State private var lineQtyText: String = "1"
    @State private var linePriceText: String = ""

    var body: some View {
        GroupBox("Invoice Generator") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    let clients = store.activeProject?.proTools.clients ?? []
                    if clients.isEmpty {
                        TextField("Client Name", text: $invoiceClientName)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 200)
                    } else {
                        Picker("Client", selection: $invoiceClientName) {
                            Text("Select Client").tag("")
                            ForEach(clients) { client in
                                Text(client.name).tag(client.name)
                            }
                        }
                        .frame(maxWidth: 200)
                    }

                    TextField("Invoice Notes", text: $invoiceNotes)
                        .textFieldStyle(.roundedBorder)
                }

                Text("Line Items")
                    .font(.caption.weight(.semibold))

                HStack(spacing: 8) {
                    TextField("Description", text: $lineDescription)
                        .textFieldStyle(.roundedBorder)

                    TextField("Qty", text: $lineQtyText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)

                    TextField("Unit $", text: $linePriceText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)

                    Button("Add Line") {
                        let qty = Int(lineQtyText) ?? 1
                        let price = Double(linePriceText) ?? 0
                        let desc = lineDescription.trimmingCharacters(in: .whitespaces)
                        guard !desc.isEmpty && price > 0 else { return }
                        lineItems.append(InvoiceLineItem(
                            id: UUID(),
                            description: desc,
                            quantity: qty,
                            unitPrice: price,
                            total: Double(qty) * price
                        ))
                        lineDescription = ""
                        lineQtyText = "1"
                        linePriceText = ""
                    }
                    .buttonStyle(.bordered)
                }

                if !lineItems.isEmpty {
                    ForEach(lineItems) { item in
                        HStack {
                            Text(item.description)
                                .font(.caption)
                            Spacer()
                            Text("\(item.quantity) x \(ptFormatCurrency(item.unitPrice)) = \(ptFormatCurrency(item.total))")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Button("X") {
                                lineItems.removeAll { $0.id == item.id }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    let invoiceTotal = lineItems.reduce(0.0) { $0 + $1.total }
                    HStack {
                        Spacer()
                        Text("Total: \(ptFormatCurrency(invoiceTotal))")
                            .font(.subheadline.weight(.semibold))
                    }
                }

                Button("Create Invoice") {
                    let name = invoiceClientName.trimmingCharacters(in: .whitespaces)
                    guard !name.isEmpty && !lineItems.isEmpty else { return }
                    store.addInvoice(clientName: name, items: lineItems, notes: invoiceNotes)
                    lineItems = []
                    invoiceClientName = ""
                    invoiceNotes = ""
                }
                .buttonStyle(.borderedProminent)
                .disabled(invoiceClientName.trimmingCharacters(in: .whitespaces).isEmpty || lineItems.isEmpty)

                let invoices = store.activeProject?.proTools.invoices ?? []

                if !invoices.isEmpty {
                    Divider()
                    Text("Invoices")
                        .font(.caption.weight(.semibold))

                    ForEach(invoices) { invoice in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(invoice.invoiceNumber)
                                    .font(.subheadline.weight(.semibold).monospaced())
                                Text(invoice.clientName)
                                    .font(.subheadline)
                                Spacer()
                                Text(ptFormatCurrency(invoice.totalAmount))
                                    .font(.subheadline.weight(.semibold).monospacedDigit())
                            }
                            HStack {
                                Text("Issued: \(ptShortDate(invoice.issuedDate))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Due: \(ptShortDate(invoice.dueDate))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Picker(
                                    "Status",
                                    selection: Binding(
                                        get: { invoice.status },
                                        set: { store.updateInvoiceStatus(invoice.id, status: $0) }
                                    )
                                ) {
                                    ForEach(InvoiceStatus.allCases) { status in
                                        Text(status.label).tag(status)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(maxWidth: 90)
                            }
                            if !invoice.items.isEmpty {
                                ForEach(invoice.items) { item in
                                    HStack {
                                        Text("  \(item.description)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text("\(item.quantity) x \(ptFormatCurrency(item.unitPrice))")
                                            .font(.caption.monospacedDigit())
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                            }
                        }
                        if invoice.id != invoices.last?.id { Divider() }
                    }
                }
            }
        }
    }
}

// MARK: Tool 27 - Session Timer

private struct SessionTimerSection: View {
    @EnvironmentObject private var store: StudioStore
    @State private var clipsProducedText: String = "1"

    var body: some View {
        GroupBox("Session Timer") {
            VStack(alignment: .leading, spacing: 10) {
                let sessions = store.activeProject?.proTools.editingSessions ?? []
                let hasActiveSession = sessions.contains(where: { $0.endTime == nil })

                HStack(spacing: 12) {
                    if hasActiveSession {
                        if let active = sessions.first(where: { $0.endTime == nil }) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Session in progress")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.green)
                                Text("Started: \(ptFormatDate(active.startTime))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                let elapsed = Date().timeIntervalSince(active.startTime) / 60
                                Text(String(format: "Elapsed: %.0f min", elapsed))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        TextField("Clips Produced", text: $clipsProducedText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)

                        Button("End Session") {
                            let clips = Int(clipsProducedText) ?? 1
                            store.endEditingSession(clipsProduced: clips)
                            clipsProducedText = "1"
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("Start Editing Session") {
                            store.startEditingSession()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                if sessions.isEmpty {
                    SectionEmptyText(text: "Track editing time per session. Start a session to begin timing.")
                } else {
                    let completedSessions = sessions.filter { $0.endTime != nil }
                    let totalMinutes = completedSessions.reduce(0.0) { $0 + $1.durationMinutes }
                    let totalClips = completedSessions.reduce(0) { $0 + $1.clipsProduced }

                    if !completedSessions.isEmpty {
                        HStack(spacing: 16) {
                            VStack(spacing: 2) {
                                Text("\(completedSessions.count)")
                                    .font(.title3.weight(.semibold))
                                Text("Sessions")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            VStack(spacing: 2) {
                                Text(String(format: "%.0f min", totalMinutes))
                                    .font(.title3.weight(.semibold))
                                Text("Total Time")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            VStack(spacing: 2) {
                                Text("\(totalClips)")
                                    .font(.title3.weight(.semibold))
                                Text("Clips Made")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if totalClips > 0 {
                                VStack(spacing: 2) {
                                    Text(String(format: "%.1f min", totalMinutes / Double(totalClips)))
                                        .font(.title3.weight(.semibold))
                                    Text("Min/Clip")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)
                    }

                    ForEach(completedSessions) { session in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ptFormatDate(session.startTime))
                                    .font(.caption)
                                if let endTime = session.endTime {
                                    Text("to \(ptFormatDate(endTime))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text(String(format: "%.0f min", session.durationMinutes))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Text("\(session.clipsProduced) clips")
                                .font(.caption.weight(.medium))
                        }
                        if session.id != completedSessions.last?.id { Divider() }
                    }
                }
            }
        }
    }
}
