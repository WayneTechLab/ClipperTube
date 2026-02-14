# Top Clipper Research (February 13, 2026)

This research informs the Cliper Tube feature set implemented in this repository.

## Market signals from leading clipping tools

| Tool | Observed feature patterns | Source |
|---|---|---|
| OpusClip | Virality scoring using hook/flow/value/trend, AI curation, auto reframe, AI B-roll, animated captions, custom templates | https://help.opus.pro/docs/article/virality-score, https://www.opus.pro/tools/ai-viral-clip-maker, https://help.opus.pro/docs/article/how-to-use-clipanything |
| Descript | Transcript-first editing, AI "find good clips", repurpose tools for clips/highlight reels, multi-platform resize/export | https://www.descript.com/tools/youtube-clip-maker, https://help.descript.com/hc/en-us/articles/21908859003277-Repurpose-with-AI-Tools, https://www.descript.com/tools/video-clip-maker |
| Riverside | AI Magic Clips auto-highlight workflow, animated captions, transcript-powered editing, silence/filler cleanup tools, caption presets, multi-aspect output | https://support.riverside.fm/hc/en-us/articles/12124048765981-AI-Magic-Clips, https://riverside.fm/tools/ai-video-editor, https://support.riverside.fm/hc/en-us/articles/21333240199709-Save-a-caption-preset |
| VEED | Auto clip highlights, auto-subtitles, speaker centering, filler-word/silence cleanup, clip ratings/goals, dynamic subtitle emphasis | https://support.veed.io/en/articles/11652474-clips-feature, https://www.veed.io/tools/auto-video-editor/short-form-video-editor, https://www.veed.io/tools/auto-subtitle-generator-online/dynamic-subtitles |
| Captions | AI shorts/highlights from long video, automatic editing styles, subtitle automation, AI-generated B-roll and music integrations | https://www.captions.ai/features/ai-shorts, https://www.captions.ai/features/highlight-video-maker, https://help.captions.ai/docs/project/ai-edit |

## Cliper Tube implementation mapping

- Viral scoring and clip ranking: `ClipEngine` confidence scoring with hook/value weighting.
- Auto Clip + Stitch timeline: automatic scene extraction and reorder controls.
- Caption generation and style presets: cinematic, punch, minimal, brand kit.
- Voice-over timeline: per-clip narration lanes with note and audio attachment.
- Pro editor assist toggles: auto reframe, silence removal, jump cuts, smart B-roll, noise reduction, color boost.
- Multi-platform export presets: YouTube Shorts, TikTok, Instagram Reels, X, LinkedIn.
- Structured export outputs: manifest JSON + SRT + summary.
- Transaction ledger: subscription/export/purchase/payout records.
- Benchmark view: competitor feature parity dashboard in-app.

## Gaps for future versions

- Native media ingest/downloader pipelines
- Real-time preview timeline renderer
- ML model-backed highlight prediction (instead of heuristics)
- Direct social scheduling/publishing
- In-app payment gateway / StoreKit integration
