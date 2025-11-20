# Android CI/CD Quick Reference

## 🚀 Quick Deploy

### Automatic Deploy to Internal Testing
```bash
git add .
git commit -m "Your commit message"
git push origin main
```
→ Automatically builds and deploys to **internal testing** track

### Manual Deploy with Track Selection
1. Go to GitHub → **Actions** tab
2. Select **Android Build & Deploy**
3. Click **Run workflow**
4. Choose **internal** or **production**
5. Click **Run workflow**

## 📋 Required GitHub Secrets

Add these in: **GitHub Repo → Settings → Secrets → Actions**

| Secret | Value |
|--------|-------|
| `ANDROID_KEYSTORE_BASE64` | Base64 of keystore file |
| `ANDROID_KEYSTORE_PASSWORD` | `OpT1rv4Da1ryT4lk2025KeySecure` |
| `ANDROID_KEY_PASSWORD` | `OpT1rv4Da1ryT4lk2025KeySecure` |
| `ANDROID_KEY_ALIAS` | `optirva-dairytalk-key` |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Base64 of Google Play JSON |

## 🔧 Setup Commands (PowerShell)

### Encode Keystore
```powershell
$keystoreBytes = [System.IO.File]::ReadAllBytes("android\app\optirva-dairytalk-key.jks")
$keystoreBase64 = [Convert]::ToBase64String($keystoreBytes)
$keystoreBase64 | Set-Clipboard
```

### Encode Google Play JSON
```powershell
$jsonPath = "$env:USERPROFILE\Downloads\your-service-account-key.json"
$jsonBytes = [System.IO.File]::ReadAllBytes($jsonPath)
$jsonBase64 = [Convert]::ToBase64String($jsonBytes)
$jsonBase64 | Set-Clipboard
```

## 📱 Version Management

### Automatic
- Version bumps automatically on every push
- Format: `MAJOR.MINOR.PATCH+BUILD_NUMBER`
- Patch and build number auto-increment

### Manual
```bash
./scripts/bump_version.sh patch   # 1.0.0 → 1.0.1
./scripts/bump_version.sh minor   # 1.0.0 → 1.1.0
./scripts/bump_version.sh major   # 1.0.0 → 2.0.0
```

## 🎯 Deployment Tracks

| Track | Purpose | Review Required |
|-------|---------|-----------------|
| **internal** | QA testing, fast | ❌ No |
| **production** | Public release | ✅ Yes |

## ⚡ What Happens on Push

1. **Version Bump** → Increments version in `pubspec.yaml`
2. **Build** → Creates APK + AAB
3. **Upload** → Sends to GitHub artifacts
4. **Deploy** → Publishes to Play Store (internal track)

## 📁 Important Files

```
.github/workflows/android-playstore.yml  # CI/CD workflow
android/fastlane/Fastfile                # Deployment config
android/app/optirva-dairytalk-key.jks    # Signing keystore
scripts/bump_version.sh                  # Version bumper
CICD_SETUP.md                            # Full setup guide
```

## 🆘 Common Issues

### Build fails with keystore error
→ Check `ANDROID_KEYSTORE_BASE64` secret is correct

### Deploy fails with "service account not found"
→ Link service account in Google Play Console → API Access

### Version not bumping
→ Ensure `scripts/bump_version.sh` has execute permissions

### Deploy stuck on pending
→ Check Google Play Console for any pending reviews/issues

## 📚 Full Documentation

See [CICD_SETUP.md](CICD_SETUP.md) for complete setup instructions.

## 🔗 Useful Links

- [Google Play Console](https://play.google.com/console)
- [Google Cloud Console](https://console.cloud.google.com/)
- [GitHub Actions](https://github.com/anasgg71-creator/machine-manager-app/actions)
- [Fastlane Docs](https://docs.fastlane.tools/)
