# Building Your Dental Scanner APK

## Prerequisites

1. **Flutter SDK Installed**
   - Download from: https://flutter.dev/docs/get-started/install
   - Extract to a location (e.g., `C:\flutter`)
   - Add Flutter to your PATH

2. **Android Studio Installed**
   - Download from: https://developer.android.com/studio
   - Install Android SDK and build tools

3. **Flutter PATH Setup**

   **Windows:**
   - Open "Environment Variables" from System Properties
   - Add Flutter `bin` directory to PATH (e.g., `C:\flutter\bin`)
   - Restart terminal/command prompt

   **Or use full path:**
   ```powershell
   C:\flutter\bin\flutter.bat build apk
   ```

## Build Commands

### Build APK (Default - All ABIs)
```bash
flutter build apk
```

**Output location:**
- `build\app\outputs\flutter-apk\app-release.apk`

### Build APK for Specific Architecture

**ARM64 (Most modern devices):**
```bash
flutter build apk --split-per-abi --target-platform android-arm64
```

**ARM32:**
```bash
flutter build apk --split-per-abi --target-platform android-arm
```

**x86_64 (Emulators):**
```bash
flutter build apk --split-per-abi --target-platform android-x64
```

### Build Release APK (Optimized)
```bash
flutter build apk --release
```

### Build Debug APK (For testing)
```bash
flutter build apk --debug
```

## Build Steps

1. **Navigate to project directory:**
   ```powershell
   cd C:\Users\ayyyi\dental_scanner
   ```

2. **Check Flutter installation:**
   ```bash
   flutter doctor
   ```

3. **Get dependencies:**
   ```bash
   flutter pub get
   ```

4. **Build APK:**
   ```bash
   flutter build apk
   ```

5. **Find your APK:**
   - Location: `build\app\outputs\flutter-apk\app-release.apk`
   - Size: Usually 20-50 MB

## Installing the APK

### On Android Device:

1. **Enable Developer Options:**
   - Go to Settings > About Phone
   - Tap "Build Number" 7 times

2. **Enable USB Debugging:**
   - Settings > Developer Options
   - Enable "USB Debugging"

3. **Transfer APK:**
   - Copy APK to device via USB or cloud
   - Open APK file on device
   - Allow installation from unknown sources if prompted
   - Install

### Via ADB:
```bash
flutter install
```

## Troubleshooting

### "Flutter not recognized"
- Add Flutter to PATH
- Or use full path: `C:\flutter\bin\flutter.bat`

### "Gradle build failed"
- Check Android SDK installed
- Check `android\local.properties` exists
- Run `flutter doctor` to check setup

### "ARCore not available"
- Build will succeed but ARCore features need compatible device
- Check device compatibility at: https://developers.google.com/ar/discover/supported-devices

### Build takes too long
- First build always takes longer (downloads dependencies)
- Subsequent builds are faster
- Use `--release` for optimized builds

### APK too large
- Use `--split-per-abi` to create separate APKs per architecture
- Removes unused native libraries
- Reduces APK size by ~60%

## Alternative: Build App Bundle (For Play Store)

If publishing to Google Play Store, use App Bundle:

```bash
flutter build appbundle
```

**Output location:**
- `build\app\outputs\bundle\release\app-release.aab`

## Verification

After building:

1. **Check APK exists:**
   ```powershell
   Test-Path build\app\outputs\flutter-apk\app-release.apk
   ```

2. **Check APK size:**
   ```powershell
   (Get-Item build\app\outputs\flutter-apk\app-release.apk).Length / 1MB
   ```

3. **Install and test:**
   - Transfer to device
   - Install
   - Test scanning features
   - Test measurements
   - Test orthodontic calculations

## Notes

- **Release builds** are optimized and smaller
- **Debug builds** are larger but include debugging symbols
- **Split APKs** reduce size but require multiple files
- **ARCore requirement** means only compatible devices can use AR features

## Build Configuration

Your app is configured for:
- **Minimum SDK:** 24 (Android 7.0) - Required for ARCore
- **Target SDK:** 34 (Android 14)
- **Package:** com.example.dental_scanner

---

**Ready to build?** Make sure Flutter is in your PATH, then run:
```bash
flutter build apk --release
```






