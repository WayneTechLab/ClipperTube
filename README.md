# Cliper Tube

Local-first macOS clipping studio by Wayne Tech Lab LLC.

Cliper Tube lets creators paste a YouTube link, generate clip candidates, import local media, edit a real video/audio timeline, preview playback in-app, and export rendered videos.

## What is implemented

- YouTube link intake and video ID parsing
- Multi-project workspace with status buckets:
  - Current
  - Working
  - Past
- Project + output browser for current/past/working projects
- Transcript-driven clip engine with confidence scoring (viral-style ranking)
- Auto Clip + Stitch suggestions from transcript
- Captation/caption generation with multiple style presets
- Voice-over timeline with note editing and local audio attachment
- Full timeline editor:
  - Import primary video and additional B-roll videos
  - Import direct remote MP4/MOV URLs (server must support byte-range streaming)
  - Add audio tracks (music/SFX/bed)
  - Play/pause/seek preview monitor
  - Rebuild timeline from AI clip suggestions
  - Reorder clips
  - Trim in/out points
  - Per-clip speed control
  - Per-clip mute toggle
  - Audio track start offset and volume controls
  - Mixed-orientation source handling with aspect-ratio aware render composition
- Pro editor toggles for reframe, silence cleanup, jump cuts, B-roll mode, noise reduction, and color boost
- YouTube Hub:
  - OAuth device-flow login
  - Channel/page picker and recent video listing
  - Direct upload of rendered timeline clips to YouTube
  - Token refresh + unauthorized retry handling for robust uploads
  - Secure Keychain token persistence with explicit write/read/delete error handling
- Export bundles containing:
  - `rendered.mov`
  - `manifest.json`
  - `captions.srt` (when captions enabled)
  - `summary.txt`
- Local transactions ledger for exports and purchases
- Benchmark dashboard for top-clipper feature coverage
- Automatic local persistence at:
  - `~/Library/Application Support/CliperTube/workspace.json`

## Build and install

### One-command install

```bash
./scripts/install_app.sh
```

The script will:
1. Compile the app executable with `swiftc`
2. Build `Cliper Tube.app`
3. Ad-hoc sign it
4. Install into `/Applications` when writable, otherwise `~/Applications`

### Launch

```bash
open "/Applications/Cliper Tube.app"
```

If installed to user applications:

```bash
open "$HOME/Applications/Cliper Tube.app"
```

## YouTube setup

1. In Google Cloud Console, enable `YouTube Data API v3`.
2. Create an OAuth Client ID and copy the client ID value.
3. Open Cliper Tube -> `YouTube Hub`.
4. Paste client ID and click `Save Client ID`.
5. Click `Connect YouTube`, then complete Google verification using the shown code.
6. Select your channel/page and upload rendered clips.

## Project layout

- `Package.swift`
- `Sources/CliperTube/CliperTubeApp.swift`
- `Sources/CliperTube/StudioModels.swift`
- `Sources/CliperTube/Engines.swift`
- `Sources/CliperTube/TimelineComposer.swift`
- `Sources/CliperTube/StudioStore.swift`
- `Sources/CliperTube/StudioViews.swift`
- `Sources/CliperTube/Persistence.swift`
- `scripts/install_app.sh`
- `docs/TOP_CLIPPERS_RESEARCH.md`

## Notes

- This app edits local media files that you import into the timeline.
- It does not download YouTube media inside the app.
- YouTube watch links are not direct media files; use local/downloaded media for timeline playback/editing.
