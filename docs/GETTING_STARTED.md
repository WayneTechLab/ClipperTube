# Getting Started with Cliper Tube

**A Wayne Tech Lab LLC Product**

---

## Overview

Cliper Tube is an AI-powered video clipping studio designed for content creators who want to transform long-form YouTube videos into viral short-form clips. This guide will walk you through your first steps.

## Installation

### Prerequisites

- macOS 13.0 (Ventura) or later
- 8GB RAM (16GB recommended)
- 500MB free disk space

### Install Steps

1. **Clone or download** the repository:
   ```bash
   git clone https://github.com/WayneTechLab/ClipperTube.git
   cd ClipperTube
   ```

2. **Run the installer**:
   ```bash
   ./scripts/install_app.sh
   ```

3. **Launch the app**:
   ```bash
   open "/Applications/Cliper Tube.app"
   ```

## First Launch

When you first open Cliper Tube, you'll see the main interface with:

- **Sidebar**: Navigation between Easy Mode and Pro Mode sections
- **Mode Switcher**: Toggle between Easy and Pro modes
- **Main Content Area**: Your current workspace

## Choose Your Mode

### Easy Mode (Recommended for beginners)

Perfect for quick, automated clip creation:

1. Paste a YouTube URL
2. Select your content purpose (Selling, Growth, Engagement, etc.)
3. Choose an engagement style (Drama, News, Tutorial, etc.)
4. Configure AI Voice Over settings
5. Click "Create Video Automatically"

The pipeline handles everything: downloading, analyzing, clipping, captioning, voice over, and exporting.

### Pro Mode

For full creative control:

- **Dashboard**: Overview of your projects
- **Projects**: Manage multiple projects
- **YouTube Hub**: Connect and upload to YouTube
- **Clip Intelligence**: AI-powered clip suggestions
- **Timeline**: Full video/audio editing
- **Voice Over**: AI voice generation
- **Captions**: Styled subtitle system
- **Distribution**: Multi-platform export

## Your First Easy Mode Video

1. Find a YouTube video you want to clip
2. Copy the URL
3. Open Cliper Tube in Easy Mode
4. Paste the URL
5. Select:
   - **Purpose**: "Engagement/Views"
   - **Style**: "Entertainment"
   - **Voice Over**: Enable, choose "Enthusiastic" tone
6. Click **"Create Engagement/Views Video"**
7. Wait for the pipeline to complete
8. Click "Show in Finder" or "Play Video"

## Your First Pro Mode Project

1. Switch to Pro Mode
2. Go to **YouTube Hub**
3. Paste a YouTube URL and click "Create Project"
4. Navigate to **Clip Intelligence**
5. Review AI-suggested clips
6. Click "Auto Clip + Stitch"
7. Go to **Timeline** to preview
8. Adjust clips as needed
9. Go to **Distribution Center**
10. Click "Export Now"

## Connecting YouTube (Optional)

To upload directly to YouTube:

1. Go to **YouTube Hub**
2. Enter your Google OAuth Client ID
3. Click "Connect YouTube"
4. Complete the device verification flow
5. Select your channel

See [YouTube Setup](YOUTUBE_SETUP.md) for detailed instructions.

## File Locations

Your files are stored locally:

| Content | Location |
|---------|----------|
| Workspace | `~/Library/Application Support/CliperTube/` |
| Imports | `~/Movies/CliperTubeImports/` |
| Exports | `~/Movies/CliperTubeExports/` |
| Voice Overs | `~/Movies/CliperTubeVoiceOvers/` |

## Next Steps

- [Easy Mode Guide](EASY_MODE_GUIDE.md) - Master automated clip creation
- [Pro Mode Manual](PRO_MODE_MANUAL.md) - Learn all features
- [Voice Over Guide](VOICE_OVER_GUIDE.md) - AI voice configuration

---

© 2026 Wayne Tech Lab LLC. All Rights Reserved.
www.WayneTechLab.com
