@echo off
echo ========================================================
echo   Watermark Studio - Local Build Script
echo ========================================================
echo.

REM Check if Flutter is in PATH
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Flutter SDK was not found in your system PATH.
    echo.
    echo Please install Flutter or add its bin directory to PATH:
    echo 1. Download Flutter: https://docs.flutter.dev/get-started/install/windows/mobile
    echo 2. Or run: winget install --id Flutter.Flutter
    echo.
    pause
    exit /b 1
)

echo [1/3] Getting Flutter dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo [ERROR] Failed to fetch pub dependencies.
    pause
    exit /b 1
)

echo.
echo [2/3] Building Release APK for Android...
call flutter build apk --release
if %errorlevel% neq 0 (
    echo [ERROR] Build failed. Make sure Android SDK / Android Studio is installed and configured.
    pause
    exit /b 1
)

echo.
echo ========================================================
echo [SUCCESS] APK compiled successfully!
echo Location: build\app\outputs\flutter-apk\app-release.apk
echo ========================================================
echo.
echo You can now transfer app-release.apk to your Android phone via USB/WhatsApp/Drive and install it.
echo.
pause
