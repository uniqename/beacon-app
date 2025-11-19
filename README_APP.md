# Beacon of New Beginnings - Mobile App

Flutter mobile application for Beacon of New Beginnings NGO, providing safety, healing, and empowerment to survivors of abuse and homelessness in Ghana.

## App Stores

- **iOS**: Available on the Apple App Store
- **Android**: Available on Google Play Store

## Repository Structure

This repository contains only the mobile app code, separated from the website for cleaner deployment and maintenance.

### Current Version

**v2.0.1+49**

## Features

- **Emergency Services**: Quick access to emergency contacts with location alerts
- **Resource Directory**: Comprehensive directory of support services
- **Community Support**: Connect with support groups and share stories
- **Privacy-Focused**: Designed with survivor safety and privacy as top priorities
- **Location-Based Resources**: Find nearby support services
- **Anonymous Submissions**: Submit information anonymously when needed

## Tech Stack

- **Framework**: Flutter (Dart)
- **Backend**: Firebase
- **Platforms**: iOS, Android
- **Min SDK**: Android API 21+, iOS 12+

## Documentation

- [Firebase Setup](FIREBASE_SETUP.md)
- [App Store Submission](APP_STORE_SUBMISSION.md)
- [TestFlight Deployment](TESTFLIGHT_DEPLOYMENT_GUIDE.md)
- [iOS Build Fix](IOS_BUILD_FIX.md)
- [Release Notes](RELEASE_NOTES.md)
- [Release Status](RELEASE_STATUS.md)

## Development Setup

### Prerequisites

- Flutter SDK (^3.8.1)
- Xcode (for iOS development)
- Android Studio (for Android development)
- Firebase account

### Installation

```bash
# Get dependencies
flutter pub get

# Run on iOS simulator
flutter run -d ios

# Run on Android emulator
flutter run -d android
```

### Building

```bash
# Build iOS
flutter build ios --release

# Build Android
flutter build apk --release
# or
flutter build appbundle --release
```

## iOS Build

See [fix_ios_build.sh](fix_ios_build.sh) for iOS-specific build fixes and configurations.

```bash
./fix_ios_build.sh
```

## App Icons

App icons are located in the `app_icons/` directory with platform-specific sizes:
- iOS: 1024x1024 and various smaller sizes
- Android: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi

## Firebase Configuration

Follow the [Firebase Setup Guide](FIREBASE_SETUP.md) to configure Firebase services:
- Authentication
- Firestore Database
- Cloud Storage
- Cloud Functions

## Store Submission

- **App Store**: Follow [APP_STORE_SUBMISSION.md](APP_STORE_SUBMISSION.md)
- **Google Play**: Follow [STORE_SUBMISSION_GUIDE.md](STORE_SUBMISSION_GUIDE.md)

## Related Repository

- **Website**: [beacon-website](https://github.com/uniqename/beacon-website) - Official website hosted on Netlify

## Contributing

This is a sensitive NGO application. All contributions must maintain the highest standards of privacy and security for vulnerable users.

## License

MIT License - See original repository for full details

## Support

For app-related support, please visit the website at [beaconnewbeginnings.org](https://beaconnewbeginnings.org)
