# 🔥 Firebase Production Setup Guide

## Prerequisites
- Firebase CLI installed: `npm install -g firebase-tools`
- Google account with billing enabled
- Flutter development environment

## 1. Create Firebase Project

1. **Go to [Firebase Console](https://console.firebase.google.com/)**
2. **Click "Create a project"**
3. **Project name**: `beacon-new-beginnings-prod`
4. **Enable Google Analytics**: Yes (recommended)
5. **Analytics account**: Create new or use existing

## 2. Enable Firebase Services

### Authentication
1. Go to **Authentication** → **Sign-in method**
2. Enable:
   - **Email/Password**
   - **Anonymous** (for privacy-first access)

### Firestore Database
1. Go to **Firestore Database**
2. **Create database** in production mode
3. **Location**: Choose closest to Ghana (europe-west1 recommended)

### Storage
1. Go to **Storage**
2. **Get started** with default rules
3. **Location**: Same as Firestore

### Cloud Messaging
1. Go to **Cloud Messaging**
2. **Generate FCM registration token** (for push notifications)

## 3. Configure Mobile Apps

### Android App
1. **Add Android app** to Firebase project
2. **Package name**: `com.beaconnewbeginnings.ngo_support_app`
3. **App nickname**: `Beacon of New Beginnings Android`
4. **Download `google-services.json`**
5. **Place in**: `ngo_support_app/android/app/`

### iOS App
1. **Add iOS app** to Firebase project
2. **Bundle ID**: `com.beaconnewbeginnings.ngo-support-app`
3. **App nickname**: `Beacon of New Beginnings iOS`
4. **Download `GoogleService-Info.plist`**
5. **Place in**: `ngo_support_app/ios/Runner/`

## 4. Update Firebase Configuration

Replace the demo configuration in `lib/firebase_options.dart` with real values:

```bash
cd ngo_support_app
flutter packages pub run build_runner build
flutterfire configure --project=beacon-new-beginnings-prod
```

## 5. Deploy Firestore Rules

```bash
cd ngo_support_app
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only storage
```

## 6. Deploy Website to Firebase Hosting

```bash
firebase deploy --only hosting
```

## 7. Set Up Cloud Functions (Optional)

For advanced features like automated emergency responses:

```bash
firebase init functions
# Choose TypeScript
# Install dependencies

# Edit functions/src/index.ts for custom logic
firebase deploy --only functions
```

## 8. Configure Environment Variables

Set up sensitive configuration:

```bash
firebase functions:config:set app.emergency_phone="+233XXXXXXXXX"
firebase functions:config:set app.admin_email="admin@beaconnewbeginnings.org"
firebase functions:config:set sendgrid.api_key="YOUR_SENDGRID_KEY"
```

## 9. Enable Real Emergency Contacts

Update the app with real Ghana emergency contacts:

### In `lib/services/emergency_service.dart`:
```dart
static const emergencyContacts = {
  'police': '191',
  'fire': '192',
  'ambulance': '193',
  'general_emergency': '999',
  'domestic_violence_hotline': '0800-800-800',
  'beacon_crisis_line': '+233-XXX-XXX-XXXX', // Your real number
};
```

## 10. Production Security Checklist

- [ ] Enable App Check for additional security
- [ ] Set up proper IAM roles for team members
- [ ] Configure backup and disaster recovery
- [ ] Set up monitoring and alerting
- [ ] Review and test all security rules
- [ ] Enable audit logging
- [ ] Set up rate limiting for APIs

## 11. Cost Management

- Set up billing alerts
- Configure daily spending limits
- Monitor usage in Firebase Console
- Optimize Firestore queries to reduce costs

## 12. Testing Production Setup

```bash
# Test with production Firebase
flutter run --dart-define=ENVIRONMENT=production

# Run integration tests
flutter test integration_test/
```

## Support

For technical issues:
- Firebase Documentation: https://firebase.google.com/docs
- Flutter Firebase: https://firebase.flutter.dev/
- GitHub Issues: Create issue in this repository

---

**⚠️ Important**: Never commit `google-services.json` or `GoogleService-Info.plist` to public repositories. These files contain sensitive API keys.