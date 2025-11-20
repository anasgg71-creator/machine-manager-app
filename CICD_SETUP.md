# Android CI/CD Setup Guide

This guide explains how to set up automated building and deployment to Google Play Store using GitHub Actions.

## Overview

The CI/CD pipeline automatically:
- Builds APK and AAB files on every push to main
- Deploys to Google Play Store (internal or production track)
- Can be manually triggered with track selection

## Prerequisites

1. **Google Play Console Account**
   - App must be created in Google Play Console
   - At least one manual release must have been published

2. **Android Keystore**
   - You already have: `android/app/optirva-dairytalk-key.jks`
   - Store password: `OpT1rv4Da1ryT4lk2025KeySecure`
   - Key alias: `optirva-dairytalk-key`

3. **Google Play Service Account**
   - Need to create this in Google Cloud Console

## Step 1: Create Google Play Service Account

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (or create one if needed)
3. Navigate to **IAM & Admin** > **Service Accounts**
4. Click **Create Service Account**:
   - Name: `github-actions-play-store`
   - Description: `Service account for GitHub Actions to deploy to Play Store`
5. Click **Create and Continue**
6. Grant the role: **Service Account User**
7. Click **Done**
8. Click on the newly created service account
9. Go to **Keys** tab
10. Click **Add Key** > **Create new key**
11. Select **JSON** format
12. Click **Create** - this downloads the JSON file

## Step 2: Link Service Account to Google Play Console

1. Open [Google Play Console](https://play.google.com/console)
2. Go to **Setup** > **API access**
3. Click **Link** next to Google Cloud Project (if not already linked)
4. Under **Service accounts**, find your service account
5. Click **Grant access**
6. Set permissions:
   - **Releases**: Create and manage releases
   - **App access**: View app information
7. Click **Invite user** then **Send invite**

## Step 3: Prepare Keystore for GitHub Secrets

Run these commands in PowerShell:

```powershell
# Navigate to project directory
cd "C:\Users\anasa\Desktop\Optirva 2"

# Convert keystore to base64
$keystoreBytes = [System.IO.File]::ReadAllBytes("android\app\optirva-dairytalk-key.jks")
$keystoreBase64 = [Convert]::ToBase64String($keystoreBytes)
$keystoreBase64 | Set-Clipboard
Write-Host "Keystore base64 copied to clipboard!"
```

## Step 4: Prepare Google Play JSON for GitHub Secrets

```powershell
# Convert the downloaded JSON file to base64
# Replace the path with your actual downloaded JSON file path
$jsonPath = "$env:USERPROFILE\Downloads\your-service-account-key.json"
$jsonBytes = [System.IO.File]::ReadAllBytes($jsonPath)
$jsonBase64 = [Convert]::ToBase64String($jsonBytes)
$jsonBase64 | Set-Clipboard
Write-Host "Google Play JSON base64 copied to clipboard!"
```

## Step 5: Add GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** > **Secrets and variables** > **Actions**
3. Click **New repository secret** for each of the following:

### Required Secrets:

| Secret Name | Value | How to Get |
|------------|-------|------------|
| `ANDROID_KEYSTORE_BASE64` | Base64 encoded keystore | Run Step 3 command |
| `ANDROID_KEYSTORE_PASSWORD` | `OpT1rv4Da1ryT4lk2025KeySecure` | Your keystore password |
| `ANDROID_KEY_PASSWORD` | `OpT1rv4Da1ryT4lk2025KeySecure` | Your key password |
| `ANDROID_KEY_ALIAS` | `optirva-dairytalk-key` | Your key alias |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Base64 encoded JSON | Run Step 4 command |

## Step 6: Test the Workflow

### Automatic Deployment (on push to main):
```bash
git add .
git commit -m "Test CI/CD pipeline"
git push origin main
```

This will:
- Build APK and AAB
- Deploy to **internal** testing track automatically

### Manual Deployment:
1. Go to GitHub repository
2. Click **Actions** tab
3. Select **Android Build & Deploy** workflow
4. Click **Run workflow**
5. Choose track: **internal** or **production**
6. Click **Run workflow**

## Version Management

The CI/CD pipeline automatically bumps the version number on every build:

- **Version Format**: `MAJOR.MINOR.PATCH+BUILD_NUMBER`
- **Current Version**: `1.0.0+11`
- **Auto-increment**: Patch version and build number increment automatically
- **Commit**: Version bump is committed back to repo with `[skip ci]` to avoid loops

### Manual Version Bump:

You can also bump versions manually:

```bash
# Bump patch version (1.0.0 -> 1.0.1)
./scripts/bump_version.sh patch

# Bump minor version (1.0.0 -> 1.1.0)
./scripts/bump_version.sh minor

# Bump major version (1.0.0 -> 2.0.0)
./scripts/bump_version.sh major
```

## How It Works

### Build Job:
1. Sets up Java 17 and Flutter
2. Installs dependencies
3. **Bumps version automatically** (patch + build number)
4. **Commits version bump** (with [skip ci] flag)
5. Decodes keystore from secrets
6. Creates key.properties file
7. Builds release APK and AAB
8. Uploads artifacts

### Deploy Job:
1. Downloads AAB from build job
2. Sets up Ruby and Fastlane
3. Decodes Google Play service account JSON
4. Runs Fastlane to upload to Play Store

## Deployment Tracks

- **Internal Testing**: For QA team, fast deployment, no review required
- **Production**: Public release, requires Google Play review

## Troubleshooting

### "Service account not found"
- Ensure service account is properly linked in Google Play Console
- Check that JSON file matches the service account email

### "Invalid keystore"
- Verify base64 encoding was done correctly
- Check that passwords match exactly

### "App not found"
- Ensure package name matches: `com.optirva.dairyhtalk`
- Verify at least one manual release was published

### "Permission denied"
- Check service account has correct permissions in Play Console
- Ensure API access is enabled

## Files Overview

```
.github/workflows/
  └── android-playstore.yml    # GitHub Actions workflow

android/
  ├── fastlane/
  │   ├── Appfile              # Package name and service account config
  │   └── Fastfile             # Deployment lanes (internal, production)
  ├── Gemfile                  # Ruby dependencies for Fastlane
  └── key.properties           # Created by CI, contains keystore info
```

## Next Steps (Optional Enhancements)

1. ✅ Version bump automation - **COMPLETED**
2. Add changelog generation from git commits
3. Add automated screenshot uploads
4. Add Play Store metadata updates
5. Add Slack/Discord notifications on deployment
6. Add rollback capabilities

## Security Notes

- Never commit `key.properties`, `*.jks`, or `*.json` files
- All sensitive data is stored in GitHub Secrets
- Service account has minimal required permissions
- Keystore and JSON are base64 encoded in secrets for safety
