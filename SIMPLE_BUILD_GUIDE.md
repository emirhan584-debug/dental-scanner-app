# Simple Guide: Build APK for Your Phone 📱

## Step-by-Step Instructions

### Part 1: Install Flutter (One-Time Setup)

1. **Download Flutter:**
   - Go to: https://flutter.dev/docs/get-started/install/windows
   - Click "Download Flutter SDK"
   - Download the ZIP file (about 1.5 GB)

2. **Extract Flutter:**
   - Extract the ZIP to `C:\flutter` (or any location you prefer)
   - **Important:** Don't extract to a folder with spaces or special characters

3. **Add Flutter to PATH:**
   - Press `Windows Key + X`
   - Click "System"
   - Click "Advanced system settings" (on the right)
   - Click "Environment Variables" button
   - Under "System variables", find and select "Path"
   - Click "Edit"
   - Click "New"
   - Type: `C:\flutter\bin` (or your Flutter location)
   - Click "OK" on all windows
   - **Restart your computer** (or at least restart PowerShell/Terminal)

4. **Verify Installation:**
   - Open a NEW PowerShell window
   - Type: `flutter doctor`
   - It will check what else you need to install

### Part 2: Install Android Studio (Required for Building)

1. **Download Android Studio:**
   - Go to: https://developer.android.com/studio
   - Download and install Android Studio

2. **Install Android SDK:**
   - Open Android Studio
   - Go to: Tools → SDK Manager
   - Install:
     - Android SDK Platform-Tools
     - Android SDK Build-Tools
     - Android 14 (API 34) - Platform SDK

3. **Accept Android Licenses:**
   - Open PowerShell as Administrator
   - Type: `flutter doctor --android-licenses`
   - Accept all licenses (type 'y' for each)

### Part 3: Build Your APK

1. **Open PowerShell in your project folder:**
   - Navigate to: `C:\Users\ayyyi\dental_scanner`

2. **Get dependencies:**
   ```
   flutter pub get
   ```

3. **Build the APK:**
   ```
   flutter build apk --release
   ```

4. **Find your APK:**
   - Go to: `C:\Users\ayyyi\dental_scanner\build\app\outputs\flutter-apk\`
   - You'll see: `app-release.apk` (this is your app!)

### Part 4: Install on Your Phone

**Method 1: USB Transfer**
1. Connect your phone to computer via USB
2. Enable "File Transfer" mode on phone
3. Copy `app-release.apk` to your phone
4. On your phone, open the APK file
5. Allow installation from "Unknown sources" if prompted
6. Install!

**Method 2: Cloud/Email**
1. Upload `app-release.apk` to Google Drive/Dropbox/Email
2. Download it on your phone
3. Open and install

**Method 3: ADB Install (if USB debugging enabled)**
```
flutter install
```

## Quick Checklist

- [ ] Flutter SDK downloaded and extracted
- [ ] Flutter added to PATH
- [ ] Computer restarted (after adding to PATH)
- [ ] Android Studio installed
- [ ] Android SDK installed
- [ ] Licenses accepted (`flutter doctor --android-licenses`)
- [ ] `flutter doctor` shows no critical errors
- [ ] Dependencies installed (`flutter pub get`)
- [ ] APK built successfully
- [ ] APK transferred to phone
- [ ] App installed and tested

## Troubleshooting

### "Flutter not recognized"
→ Add Flutter to PATH and restart terminal/computer

### "Gradle build failed"
→ Make sure Android Studio and SDK are installed

### "SDK not found"
→ Run `flutter doctor` to see what's missing

### Build takes 10+ minutes
→ First build always takes longer (downloading dependencies). This is normal!

### APK file is large (50+ MB)
→ This is normal for Flutter apps with ARCore. To make it smaller, use:
```
flutter build apk --split-per-abi --release
```
This creates separate APKs for different phone types (smaller files).

## Estimated Time

- Flutter installation: 10-15 minutes
- Android Studio setup: 15-20 minutes
- First build: 10-15 minutes (downloading dependencies)
- **Total: ~45-60 minutes** (one-time setup)

After first setup, subsequent builds take only 2-5 minutes!

---

## Need Help?

If you get stuck:
1. Run `flutter doctor` and share the output
2. Check the error message during build
3. Make sure all prerequisites are installed

**You're building a professional dental scanning app - it's worth the setup time!** 🦷📱






