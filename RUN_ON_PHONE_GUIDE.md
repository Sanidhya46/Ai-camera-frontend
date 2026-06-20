# How to Run Flutter App on Your Phone via USB

## Prerequisites
- USB cable to connect phone to PC
- Android phone
- USB drivers installed (usually automatic on Windows 10/11)

---

## Part 1: Prepare Your Android Phone

### Step 1: Enable Developer Options
1. Open **Settings** on your phone
2. Scroll to **About Phone** (or **About Device**)
3. Find **Build Number** (might be under Software Information)
4. **Tap Build Number 7 times** rapidly
5. You'll see: "You are now a developer!"

### Step 2: Enable USB Debugging
1. Go back to **Settings**
2. Look for **Developer Options** (usually in System → Advanced → Developer Options)
3. Toggle **Developer Options** to ON
4. Find and enable:
   - ✅ **USB Debugging**
   - ✅ **Install via USB** (if available)
   - ✅ **USB debugging (Security settings)** (if available)

### Step 3: Connect Phone to PC
1. **Connect your phone** to your PC using USB cable
2. On your phone, you may see:
   - "Use USB for?" → Select **File Transfer** or **PTP**
   - "Allow USB debugging?" → **Check "Always allow"** → Tap **OK**

### Step 4: Verify USB Connection Mode
- Swipe down notification panel on phone
- Tap on "USB" notification
- Select **File Transfer** or **MTP** mode (NOT "Charging only")

---

## Part 2: Verify Connection from PC

### Open Command Prompt or PowerShell

```cmd
# Check if device is detected
adb devices
```

**Expected Output:**
```
List of devices attached
XXXXXXXXXX    device
```

If you see your device listed, you're ready! ✅

### Troubleshooting "adb not found"

If `adb` command is not found, use Flutter's ADB:

```cmd
cd C:\Users\a\flutter\bin\cache\dart-sdk\bin
adb devices
```

Or add to PATH:
```cmd
# Add Flutter's platform-tools to PATH temporarily
set PATH=%PATH%;C:\Users\a\AppData\Local\Android\Sdk\platform-tools
adb devices
```

---

## Part 3: Run the App on Your Phone

### Method 1: Using Flutter Run Command (HOT RELOAD) ⚡

```bash
# Navigate to your project
cd d:\Ai_camera\ai-camera-frontend

# Check connected devices
flutter devices

# Run in debug mode (with hot reload)
flutter run
```

**What happens:**
- App installs on your phone
- Opens automatically
- You can make code changes
- Press `r` in terminal to hot reload
- Press `R` for hot restart
- Press `q` to quit

### Method 2: Install Pre-built APK

```bash
# First, build the APK
flutter build apk --debug

# Install on connected device
adb install build\app\outputs\flutter-apk\app-debug.apk
```

**If you get "INSTALL_FAILED_UPDATE_INCOMPATIBLE":**
```bash
# Uninstall first
adb uninstall com.example.smart_shutter

# Then install
adb install build\app\outputs\flutter-apk\app-debug.apk
```

### Method 3: Install Release APK

```bash
# Build release APK (smaller, optimized)
flutter build apk --release

# Install on device
adb install build\app\outputs\flutter-apk\app-release.apk
```

---

## Part 4: Quick Commands Reference

### Device Management
```bash
# List connected devices
flutter devices
adb devices

# Get device info
adb shell getprop ro.product.model
adb shell getprop ro.build.version.release

# Reboot device
adb reboot
```

### App Installation
```bash
# Install APK
adb install path\to\app.apk

# Install and replace existing app
adb install -r app.apk

# Uninstall app
adb uninstall com.example.smart_shutter
```

### Logging (View Console Output)
```bash
# View live logs from your app
adb logcat

# Filter Flutter logs only
adb logcat -s flutter

# Clear logs and view fresh
adb logcat -c && adb logcat
```

### File Management
```bash
# Copy file TO phone
adb push C:\myfile.txt /sdcard/Download/

# Copy file FROM phone
adb pull /sdcard/Download/myfile.txt C:\Downloads\

# Take screenshot
adb shell screencap -p /sdcard/screen.png
adb pull /sdcard/screen.png screenshot.png
```

---

## Common Issues & Solutions

### ⚠️ Issue: "No devices found"

**Solutions:**
1. Check USB cable (use original cable, some cables are charge-only)
2. Try different USB port on PC
3. On phone: Disable and re-enable USB Debugging
4. On PC: Restart ADB server:
   ```bash
   adb kill-server
   adb start-server
   adb devices
   ```
5. Install/Update USB drivers:
   - Windows: Usually automatic
   - Try: https://developer.android.com/studio/run/oem-usb

### ⚠️ Issue: Device shows as "unauthorized"

**Solution:**
- On phone, you'll see "Allow USB debugging?" prompt
- Tap **OK** and check "Always allow from this computer"
- If prompt doesn't appear:
  - Go to Developer Options → Revoke USB debugging authorizations
  - Disconnect and reconnect phone

### ⚠️ Issue: "Offline" device

**Solutions:**
```bash
# Restart ADB
adb kill-server
adb start-server

# Or disconnect USB and reconnect
```

### ⚠️ Issue: App won't install

**Solutions:**
```bash
# Uninstall old version first
adb uninstall com.example.smart_shutter

# Then install fresh
adb install build\app\outputs\flutter-apk\app-debug.apk
```

### ⚠️ Issue: "Waiting for another flutter command to release the startup lock"

**Solution:**
```bash
# Kill Flutter processes
taskkill /F /IM flutter.exe

# Or delete lock file
del C:\Users\a\AppData\Local\Temp\flutter_tools_lock_*
```

---

## Part 5: Development Workflow

### Recommended Development Flow:

1. **Connect phone via USB**
   ```bash
   adb devices
   ```

2. **Start development server**
   ```bash
   cd d:\Ai_camera\ai-camera-frontend
   flutter run
   ```

3. **Make changes to your code**
   - Edit files in VS Code/Kiro

4. **Hot Reload** (press `r` in terminal)
   - Fastest: Updates UI instantly
   - Preserves app state

5. **Hot Restart** (press `R` in terminal)
   - Restarts app
   - Resets state

6. **View logs**
   - Logs appear in terminal automatically
   - Or use: `flutter logs`

### Performance Testing:

```bash
# Run in profile mode (performance testing)
flutter run --profile

# Run in release mode (production performance)
flutter run --release
```

---

## Part 6: Wireless Debugging (Advanced) 📱

Once USB is working, you can switch to wireless:

### Setup Wireless ADB (Android 11+)

1. Connect phone via USB first
2. Run:
   ```bash
   adb tcpip 5555
   ```
3. Find phone's IP address:
   - Phone Settings → About → Status → IP address
   - Or: `adb shell ip addr show wlan0`
4. Disconnect USB cable
5. Connect wirelessly:
   ```bash
   adb connect 192.168.x.x:5555
   ```
6. Verify:
   ```bash
   adb devices
   ```

Now you can use `flutter run` wirelessly! 🎉

### To go back to USB:
```bash
adb usb
```

---

## Quick Start Checklist ✅

Before running your app:

- [ ] USB Debugging enabled on phone
- [ ] Phone connected via USB (File Transfer mode)
- [ ] USB debugging authorized on phone
- [ ] `adb devices` shows your device
- [ ] Phone screen is unlocked

Then run:
```bash
cd d:\Ai_camera\ai-camera-frontend
flutter run
```

---

## Useful Commands for Your Project

```bash
# Check device is connected
flutter devices

# Run on connected phone (debug mode with hot reload)
flutter run

# Run on specific device (if multiple devices connected)
flutter run -d <device-id>

# Run in release mode (production performance)
flutter run --release

# Build and install APK manually
flutter build apk --debug
adb install build\app\outputs\flutter-apk\app-debug.apk

# View app logs
flutter logs

# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

---

## Tips & Best Practices

1. **Keep phone connected** during development for hot reload
2. **Use release builds** for performance testing
3. **Enable "Stay awake"** in Developer Options (screen won't turn off when charging)
4. **Disable "Battery Optimization"** for better debugging experience
5. **Use original USB cable** - cheap cables often don't support data transfer

---

## Need Help?

### Check Flutter Doctor
```bash
flutter doctor -v
```
This will tell you if everything is set up correctly.

### Check Device Logs
```bash
flutter logs
# or
adb logcat -s flutter
```

---

## Summary

**Fastest way to run on phone:**

1. Enable USB Debugging on phone
2. Connect via USB
3. Run: `flutter run`
4. Done! ✅

The app will install and run, and you can make live changes with hot reload!
