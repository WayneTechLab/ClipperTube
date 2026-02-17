# Voice Over Guide

**A Wayne Tech Lab LLC Product**

---

## Overview

CliperTube AI Voice Over generates professional narration for your clips using:
- macOS System Text-to-Speech
- AI-generated scripts tailored to your content purpose

This guide covers configuration, best practices, and optimization.

---

## Voice Over in Easy Mode

### Configuration Flow

When you start Easy Mode, you configure voice over as part of the setup:

1. **Content Purpose**: Why are you making this clip?
2. **Engagement Style**: What's the hook/angle?
3. **Voice Over**: What tone and voice?
4. **Affiliate Info**: (If selling) Product details

### Purpose-Driven Narration

The AI automatically adjusts narration based on your purpose:

| Purpose | Narration Style |
|---------|-----------------|
| **Selling** | Product-focused, benefits, call-to-action |
| **Channel Growth** | Engagement hooks, community building |
| **Engagement** | Dramatic, emotional, storytelling |
| **Affiliate** | Review-style, honest, transparent |
| **Brand Awareness** | Professional, value-focused |

---

## Voice Over in Pro Mode

### Per-Segment Approach

Pro Mode gives you per-clip voice over control:

1. Go to **Voice Over Timeline** section
2. Each clip segment shows:
   - Clip preview
   - Note field
   - Attached audio (if any)
3. Add narration notes for each segment
4. Generate or attach audio individually

### AI Generation

For each segment:
1. Enter script/note in the text field
2. Click **Generate AI**
3. Audio generates and attaches automatically

### Manual Attachment

1. Click **Attach Audio**
2. Select pre-recorded audio file
3. File links to that segment

---

## Voice Tones

| Tone | Description | Best For |
|------|-------------|----------|
| **Narrator** | Professional, neutral | Explainers, reviews |
| **Enthusiastic** | Upbeat, excited | Reveals, announcements |
| **Dramatic** | Intense, suspenseful | Drama, reactions |
| **Conversational** | Natural, friendly | Vlogs, casual content |
| **Authoritative** | Expert, trustworthy | Tutorials, education |
| **Inspirational** | Motivating, uplifting | Motivation, challenges |
| **Chill** | Calm, relaxed | ASMR, ambient |
| **News Anchor** | Formal, professional | News, updates |

---

## Voice Tone Settings

Each tone has optimized speech parameters:

| Tone | Speech Rate | Pitch |
|------|-------------|-------|
| Narrator | 0.50 | 1.0 |
| Enthusiastic | 0.55 | 1.1 |
| Dramatic | 0.45 | 0.95 |
| Conversational | 0.52 | 1.0 |
| Authoritative | 0.48 | 0.9 |
| Inspirational | 0.50 | 1.05 |
| Chill | 0.42 | 0.95 |
| News Anchor | 0.50 | 1.0 |

> **Rate**: 0.0 (slowest) to 1.0 (fastest)
> **Pitch**: 0.5 (low) to 2.0 (high), 1.0 = normal

---

## Engagement Styles & Hook Phrases

Each style includes optimized hook phrases for voice over:

### Drama
- "You won't believe what happened"
- "Things are about to get crazy"
- "No one saw this coming"

### Life Event
- "A moment that changed everything"
- "This is huge news"
- "Major life update"

### Breaking News
- "Breaking news just in"
- "This just happened"
- "Developing story"

### New Drop
- "It's finally here"
- "The wait is over"
- "Just dropped"

### Tutorial
- "Let me show you how"
- "The secret to success"
- "Step by step guide"

### Reaction
- "My honest reaction to"
- "I wasn't ready for this"
- "Wait until you see"

### Motivation
- "Remember why you started"
- "You've got this"
- "Keep pushing forward"

### Entertainment
- "Wait for it..."
- "This is gold"
- "You need to see this"

---

## Available Voices

CliperTube uses macOS built-in voices:

### High Quality Voices

| Voice | Accent | Style |
|-------|--------|-------|
| Alex | US English | Natural |
| Samantha | US English | Female |
| Tom | US English | Male |
| Daniel | UK English | Male |
| Karen | AU English | Female |

### Installing More Voices

1. Open **System Settings** → **Accessibility** → **Spoken Content**
2. Click **System Voice** → **Manage Voices**
3. Download additional voices
4. Restart CliperTube to see new voices

---

## Voice Providers

### System TTS (Current)

- **Platform**: macOS NSSpeechSynthesizer
- **Cost**: Free
- **Quality**: Good
- **Speed**: Fast
- **Offline**: Yes

### ElevenLabs (Future)

- **Platform**: API Integration
- **Cost**: Subscription
- **Quality**: Premium
- **Speed**: Moderate
- **Offline**: No

### OpenAI TTS (Future)

- **Platform**: API Integration
- **Cost**: Usage-based
- **Quality**: Very High
- **Speed**: Moderate
- **Offline**: No

---

## Script Best Practices

### Length

- Short-form clips: 10-30 words
- Medium clips: 30-60 words
- Long-form: 60-120 words

### Structure

1. **Hook**: Grab attention (first 3 seconds)
2. **Setup**: Context or problem
3. **Payoff**: Solution, reveal, or CTA

### Word Choice

| Do | Don't |
|----|-------|
| Short words | Complex jargon |
| Active voice | Passive voice |
| Direct address ("you") | Generic language |
| Action verbs | Filler words |

---

## Examples by Purpose

### Selling
```
This product changed my morning routine. 
In just 30 seconds, you'll see why thousands 
have already made the switch. Link in bio.
```

### Channel Growth
```
If you're new here, welcome to the channel. 
Subscribe and turn on notifications so you 
never miss content like this.
```

### Engagement
```
You're not going to believe what happens next. 
Stay until the end because the plot twist 
is absolutely wild.
```

### Affiliate
```
Full disclosure - I've been using this for 
three months now. Here's my honest review. 
Affiliate link below if you want to try it.
```

### Brand Awareness
```
At Wayne Tech Lab, we believe technology 
should make life easier. That's why we 
built CliperTube.
```

---

## Troubleshooting

### No Audio Generated

**Cause**: TTS engine error or unsupported voice.

**Fix**:
1. Try a different voice
2. Restart CliperTube
3. Check System Settings → Accessibility → Spoken Content

---

### Audio Too Fast/Slow

**Cause**: Wrong tone selection.

**Fix**:
1. Choose a tone with appropriate speech rate
2. "Chill" = slowest (0.42)
3. "Enthusiastic" = fastest (0.55)

---

### Voice Sounds Robotic

**Cause**: Using basic system voice.

**Fix**:
1. Install premium voices via System Settings
2. Select "Alex" or "Samantha" for best quality

---

### Audio Not Synced to Video

**Cause**: Audio length doesn't match clip duration.

**Fix**:
1. Shorten or lengthen script
2. Use timeline controls to adjust sync
3. Specify duration in script

---

## File Output

Voice over audio is saved as M4A format:
- Location: Project output folder
- Naming: `voiceover_[timestamp].m4a`
- Quality: AAC, high bitrate

---

## Integration with Timeline

Voice over integrates with the audio timeline:

1. Generated audio appears in Audio Tracks
2. Adjust volume relative to main audio
3. Set start offset for timing
4. Preview in real-time

---

## Tips

### Hook Optimization
- Put the hook in the first 5 words
- Match hook to engagement style
- Test different styles for same content

### Tone Matching
- News content → News Anchor or Authoritative
- Product reviews → Narrator or Conversational
- Drama/reaction → Dramatic or Enthusiastic
- Tutorials → Narrator or Conversational

### Quality Improvement
- Use punctuation for natural pauses
- Break long sentences
- Avoid abbreviations (say "versus" not "vs")

---

© 2026 Wayne Tech Lab LLC. All Rights Reserved.
www.WayneTechLab.com
