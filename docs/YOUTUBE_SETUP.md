# YouTube Setup Guide

**A Wayne Tech Lab LLC Product**

---

## Overview

CliperTube connects to YouTube via OAuth 2.0 for:
- Downloading your videos
- Browsing your uploads
- Uploading rendered clips

This guide walks through the complete setup process.

---

## Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Click **Select a Project** → **New Project**
3. Enter project name (e.g., "CliperTube")
4. Click **Create**

---

## Step 2: Enable YouTube Data API

1. In your project, go to **APIs & Services** → **Library**
2. Search for "YouTube Data API v3"
3. Click on **YouTube Data API v3**
4. Click **Enable**

---

## Step 3: Configure OAuth Consent Screen

1. Go to **APIs & Services** → **OAuth consent screen**
2. Select **External** → Click **Create**
3. Fill in:
   - **App name**: CliperTube
   - **User support email**: Your email
   - **Developer contact**: Your email
4. Click **Save and Continue**

### Scopes

5. Click **Add or Remove Scopes**
6. Add these scopes:
   - `https://www.googleapis.com/auth/youtube.readonly`
   - `https://www.googleapis.com/auth/youtube.upload`
7. Click **Save and Continue**

### Test Users

8. Click **Add Users**
9. Enter your Google email address
10. Click **Save and Continue**

---

## Step 4: Create OAuth Credentials

1. Go to **APIs & Services** → **Credentials**
2. Click **+ Create Credentials** → **OAuth client ID**
3. Application type: **TV and Limited Input devices**
4. Name: "CliperTube Desktop"
5. Click **Create**

### Copy Your Client ID

6. Copy the **Client ID** (ends with `.apps.googleusercontent.com`)
7. Keep this safe - you'll enter it in CliperTube

> **Note**: Client Secret is not needed for TV/Limited Input flow

---

## Step 5: Connect in CliperTube

### Enter Client ID

1. Open CliperTube
2. Go to **Pro Mode** → **YouTube Hub**
3. Paste your Client ID
4. Click **Save Client ID**

### Authenticate

5. Click **Connect YouTube**
6. A verification code appears
7. Open the link shown (or scan QR code)
8. Enter the code on Google's page
9. Grant permissions when prompted

### Select Channel

10. Once authenticated, your channel appears
11. Click **Select** to activate it

---

## Verification Status

| Status | Description |
|--------|-------------|
| **Testing** | Limited to added test users |
| **Published** | Available to all users |

For personal use, **Testing** mode is sufficient.

---

## Token Management

### Automatic Refresh

CliperTube automatically refreshes tokens before expiry.

### Manual Refresh

If you see authentication errors:
1. Click **Disconnect**
2. Click **Connect YouTube** again
3. Re-authenticate

### Token Storage

Tokens are stored locally in:
```
~/Library/Application Support/CliperTube/
```

---

## Troubleshooting

### "Access Denied"

**Cause**: Your email isn't a test user.

**Fix**: Add your email to test users in Google Cloud Console.

---

### "Invalid Client ID"

**Cause**: Typo or wrong ID format.

**Fix**: 
1. Go to Google Cloud → Credentials
2. Copy the full Client ID
3. Re-paste in CliperTube

---

### "Polling Timeout"

**Cause**: Too long to complete verification.

**Fix**:
1. Click **Connect YouTube** again
2. Complete verification within 5 minutes

---

### "Quota Exceeded"

**Cause**: Hit daily API limits (10,000 units).

**Fix**: Wait 24 hours or request quota increase.

---

### "This app is blocked"

**Cause**: App in testing mode, not a test user.

**Fix**:
1. Google Cloud → OAuth consent screen
2. Add your email to test users

---

## API Quotas

| Operation | Cost (Units) |
|-----------|--------------|
| List videos | 1 |
| Get video details | 1 |
| Upload video | 1,600 |
| Search | 100 |

**Daily limit**: 10,000 units

**Practical limit**: ~6 uploads/day

---

## Security Tips

1. **Never share your Client ID publicly**
2. **Don't commit credentials to git**
3. **Use a dedicated project for CliperTube**
4. **Revoke access if compromised**:
   - Go to [Google Security](https://myaccount.google.com/permissions)
   - Find CliperTube
   - Click **Remove Access**

---

## Supported Features

| Feature | Status |
|---------|--------|
| Browse Uploads | ✅ |
| Download Videos | ✅ |
| Upload Clips | ✅ |
| Set Privacy | ✅ |
| Add Tags | ✅ |
| Schedule Upload | ❌ |

---

## Quick Reference

| Setting | Value |
|---------|-------|
| API | YouTube Data API v3 |
| Auth Type | OAuth 2.0 (TV/Limited Input) |
| Consent | External |
| Scopes | `youtube.readonly`, `youtube.upload` |

---

© 2026 Wayne Tech Lab LLC. All Rights Reserved.
www.WayneTechLab.com
