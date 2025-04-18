# Student-Calendar-App

## Running the App on a Real Device

You can run this Flutter app on a physical device using one of the following methods:

- **Mac + iPhone** (requires Xcode)
- **Windows + Android** (or Mac + Android)
- **Direct APK install** (easiest & recommended)

Each method is explained in full detail below, including extra setup steps and common fixes.

---

## Method 1: Run on iPhone (Mac Only)

> You must use a Mac to build and run Flutter apps on iOS.

### Prerequisites

- A physical iPhone and a Lightning cable 
    - If you want to run in on your own device
- A cloned version of this repository

### Steps
1. Install CocoaPods (only required once):

   ```
   sudo gem install cocoapods
   ```
   - If that fails, the alternative (and often more stable) approach is to use Homebrew:

     ```
     /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
     ```
     Install CocoaPods with Homebrew:
     ```
     brew install cocoapods
     ```
2. Install the Flutter SDK 
    - Only follow the steps required to install flutter SDK and to add to path
        - [Start building Flutter iOS apps on macOS](https://docs.flutter.dev/get-started/install/macos/mobile-ios)
3. Open Terminal and navigate to your Flutter project directory:

   ```
   cd /path/to/your/project/Student-Calendar-App/student_app
   flutter clean
   flutter pub get
   ```
4. Navigate into the iOS directory and install CocoaPods dependencies:
   ```
   cd ios 
   pod install
   ```
5. Follow the steps listed here to get the app up and running on Xcode. We have already installed Cocapods and the flutter SDK so you can skip them. 
    - [Start building Flutter iOS apps on macOS](https://docs.flutter.dev/get-started/install/macos/mobile-ios)
        - Follow the steps in the guide based on you specific device/ios configuration and whether you want to run it on an emulator or a physcial ios device 
    > Note: You do not need an apple development account just and apple ID which is stated in the linked steps
6. Once all these setps are complete you should have a fully working application and be greeted with the login page. 

## Method 2: Run on Android (Windows or macOS)

This method allows you to run the Flutter app on a physical Android device using either a Windows or macOS computer.

### Prerequisites

- Flutter SDK installed and added to your system PATH
- Android SDK (recommended: install Android Studio)
- A physical Android phone with a USB cable
- Developer Mode and USB Debugging enabled on the phone
- A cloned version of this repository

### Steps

1. Enable Developer Options on your Android phone:

   - Go to **Settings > About phone**
   - Tap **Build number** seven times until you see a message that Developer Mode has been enabled
2. Enable USB Debugging:

   - Go to **Settings > Developer Options**
   - Enable **USB Debugging**
3. Connect your Android phone to your computer using a USB cable.
4. Authorize USB debugging:

   - When prompted on your phone, tap **Allow** to grant USB debugging access
5. (Optional but recommended) Enable file transfer mode:

   - Swipe down the notification shade and set the USB mode to **File Transfer (MTP)**
6. Allow app installs via USB (if prompted):

   - On newer Android versions, go to **Settings > Apps > Special access > Install unknown apps**
   - Allow your terminal, IDE, or file manager to install apps
7. Open Command Prompt or PowerShell and navigate to the project directory:

   ```
   cd \path\to\your\project\Student-Calendar-App\student_app
   flutter clean
   flutter pub get
   ```
8. Check if your Android device is recognized:

   ```
   flutter devices
   ```

   if it does not appear:

   - Make sure the phone is unlocked
   - Try a different USB cable or port
   - Ensure USB Debugging is enabled
9. Run the app:

   ```
   flutter run
   ```

   The app will build and automatically install on your phone. Once complete, it should launch automatically. If it doesn’t, you can open it manually from your app drawer.

## Method 3: Install APK File (Android Only)

This is the easiest method and does not require setting up Flutter, Android Studio, or any developer tools. You only need an Android phone and the APK file included in this repository.

### Prerequisites

- An Android phone
- Access to this repository (already cloned)

### Steps

1. Locate the APK file in your cloned project directory:

   > student_app/build/app/outputs/flutter-apk/app-release.apk
   >
2. Transfer the `app-release.apk` file to your Android device using one of the following methods:

   - USB cable (set the phone to **File Transfer** mode)
   - Upload the file to **Google Drive** and download it on your phone
   - Send it via **email** or a file-sharing app (e.g., Snapdrop, Nearby Share)
3. On your Android phone, locate and tap the APK file to begin installation.
4. If prompted, allow app installations from unknown sources (an automatic popup should show that redirects you to settings where you can allow download from unknown sources)

   - Go to **Settings > Apps > Special access > Install unknown apps**
   - Select the app you're using to open the APK (e.g., Files, Drive, or your browser)
   - Enable **Allow from this source**
5. Tap **Install** and wait for the installation to finish.
6. Once installed, open the app from your app drawer.

The app is now installed and ready to use on your Android device.
