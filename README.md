# 🎬 Watermark Studio - Flutter Android Video Watermarking App

A fast, modern, and standalone Flutter Android application that performs **local frame-by-frame text watermarking** on videos using **FFmpeg** (`ffmpeg_kit_flutter_min_gpl`). No backend server or cloud processing is required — everything runs 100% on the device!

---

## ✨ Features
1. **Video Selector:** Clean dropzone card to pick any video (MP4, MKV, MOV, WebM) from phone storage/gallery.
2. **Watermark Configuration:**
   - Real-time text input with live visual overlay preview.
   - **Subtle Light Bottom** positioning (centered or cornered with soft semi-transparent backing or text shadow).
   - Adjustable opacity (lightness), font size, bottom padding margin, and background pill box.
3. **Frame-by-Frame Local Processing:** Fast background FFmpeg asynchronous pipeline (`drawtext` filter with ultrafast/faster H.264 encoding & direct audio stream copy).
4. **Real-time Progress:** Animated progress modal displaying percentage rendered, frame elapsed time, and instant **Cancel** capability.
5. **Video Playback & Saving:** Full player preview of the exported video with **Save to Gallery** (`gal` package) and direct **Share** options.

---

## 📁 Project Structure

```
WaterMarkAdder/
├── android/
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── AndroidManifest.xml       # Media permissions (Android 13+ & legacy)
│   │   │   └── kotlin/.../MainActivity.kt
│   │   └── build.gradle                  # minSdkVersion 24 (FFmpegKit required)
│   ├── build.gradle
│   └── settings.gradle
├── lib/
│   ├── models/
│   │   └── watermark_config.dart         # Watermark styling & FFmpeg filter generator
│   ├── services/
│   │   ├── ffmpeg_service.dart           # FFmpeg execution, statistics & cancellation
│   │   └── permission_service.dart       # Android runtime media permission handler
│   ├── widgets/
│   │   ├── export_result_view.dart       # Rendered video player, gallery save & share
│   │   ├── processing_dialog.dart        # Real-time percentage & frame progress modal
│   │   ├── video_player_view.dart        # Video player with live overlay preview
│   │   └── watermark_config_card.dart    # Sliders, presets & text customizer
│   └── main.dart                         # Main UI & Material 3 Dark theme flow
├── pubspec.yaml                          # Dependencies
└── README.md
```

---

## 🚀 Quick Setup & Run Instructions

### 1. Install Dependencies
Open your terminal in the project directory:
```bash
flutter pub get
```

### 2. Connect Your Android Phone
1. Enable **Developer Options** on your Android phone (*Settings > About Phone > Tap "Build Number" 7 times*).
2. Enable **USB Debugging** (*Settings > Developer Options > USB Debugging*).
3. Connect the phone via USB cable and verify device recognition:
   ```bash
   flutter devices
   ```

### 3. Run Directly on Connected Device
```bash
flutter run
```

### 4. Build Standalone APK for Installation
To generate an APK you can transfer and install on any phone:

```bash
# Generate optimized Universal APK
flutter build apk --release

# OR generate split APKs (smaller file size per architecture)
flutter build apk --split-per-abi
```
The compiled APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## ⚙️ Technical Details

### Android Permissions
Configured in `android/app/src/main/AndroidManifest.xml`:
- `READ_MEDIA_VIDEO` & `READ_MEDIA_IMAGES` for **Android 13+ (API 33+)**
- `READ_EXTERNAL_STORAGE` & `WRITE_EXTERNAL_STORAGE` for **Android 12 and below**
- `android:requestLegacyExternalStorage="true"`

### FFmpeg Drawtext Command
```bash
-y -i "input.mp4" -vf "drawtext=text='@MyChannel':fontsize=28:fontcolor=white@0.75:x=(w-text_w)/2:y=h-text_h-35:box=1:boxcolor=black@0.35:boxborderw=8" -c:v libx264 -preset faster -crf 22 -c:a copy "output.mp4"
```
- `-c:a copy`: Copies the original audio stream without re-encoding (instant speed and zero audio quality loss).
- `box=1:boxcolor=black@0.35`: Creates an elegant semi-transparent dark pill behind the light text for high readability across all video backgrounds.
- `y=h-text_h-35`: Keeps the watermark pinned right above the bottom edge.
