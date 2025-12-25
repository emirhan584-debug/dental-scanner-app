# 🚀 Quick Start: Build APK in 3 Steps

## Prerequisites Check

**Do you have these installed?**
- [ ] Flutter SDK
- [ ] Android Studio
- [ ] Android SDK

**If NO, follow the installation guide first:**
→ See `SIMPLE_BUILD_GUIDE.md`

## Build Commands (If Everything is Installed)

### Step 1: Open PowerShell
- Press `Win + X`
- Click "Windows PowerShell" or "Terminal"

### Step 2: Navigate to Project
```powershell
cd C:\Users\ayyyi\dental_scanner
```

### Step 3: Build APK
```powershell
# Get dependencies first
flutter pub get

# Build the APK
flutter build apk --release
```

### Step 4: Find Your APK
Your APK is here:
```
C:\Users\ayyyi\dental_scanner\build\app\outputs\flutter-apk\app-release.apk
```

## Install on Phone

1. **Copy APK to phone** (USB, email, or cloud)
2. **On your phone:** Open the APK file
3. **Allow installation** from unknown sources
4. **Install** and enjoy! 🎉

## That's It!

If you get errors, check `SIMPLE_BUILD_GUIDE.md` for detailed setup instructions.






