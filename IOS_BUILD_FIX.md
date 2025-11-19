# 🍎 iOS Build Fix Guide - Beacon of New Beginnings

## 🚨 **Current Issue**
**Error**: `unsupported option '-G' for target 'arm64-apple-ios10.0'`
**Cause**: Firebase dependencies have mismatched iOS deployment targets

## 🔧 **Quick Fix Steps**

### Step 1: Update Podfile Post Install
Edit `/ios/Podfile` and update the post_install section:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Fix deployment target for all pods
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
    end
  end
end
```

### Step 2: Clean and Reinstall
```bash
cd ios
rm -rf Pods Podfile.lock .symlinks
cd ..
flutter clean
flutter pub get
cd ios
pod install
```

### Step 3: Update Xcode Project Settings
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner project → Runner target
3. Build Settings → Deployment → iOS Deployment Target → Set to 14.0
4. Build Settings → Architectures → Excluded Architectures → Add `arm64` for simulator

### Step 4: Build Release
```bash
flutter build ios --release
```

## 📦 **Creating IPA for App Store**

### Option 1: Xcode Archive (Recommended)
```bash
# After successful build
open ios/Runner.xcworkspace
```
In Xcode:
1. Product → Archive
2. Distribute App → App Store Connect
3. Upload

### Option 2: Command Line
```bash
flutter build ipa --release
```
IPA will be at: `build/ios/ipa/ngo_support_app.ipa`

## 🚀 **TestFlight Upload**

### Using Xcode (Easiest)
1. Archive in Xcode
2. Window → Organizer
3. Select Archive → Distribute App
4. Choose "App Store Connect"
5. Upload and submit for TestFlight

### Using Application Loader
1. Download from App Store Connect
2. Load the IPA file
3. Upload to App Store Connect

## 📱 **TestFlight Testing Process**

### Internal Testing (Immediate)
- Up to 100 internal testers
- No review required
- Available immediately after upload

### External Testing (Review Required)
- Up to 10,000 external testers
- Requires beta app review (1-3 days)
- Public link available

### Test Groups Setup
1. **Staff Testing**: Internal team (5-10 people)
2. **NGO Partners**: Service providers (20-30 people)  
3. **Survivor Community**: Safe testing group (10-20 people)

## 🔐 **App Store Connect Setup**

### Required Information
- **Bundle ID**: `com.beaconnewbeginnings.ngo-support-app`
- **SKU**: `beacon-ngo-support-app-v1`
- **Primary Language**: English (Ghana)
- **Category**: Medical
- **Age Rating**: 17+ (Mature)

### App Information
```
Name: Beacon of New Beginnings
Subtitle: Safe haven for survivors
Description: [Use description from APP_STORE_SUBMISSION.md]
Keywords: domestic violence, survivor support, emergency, Ghana
Support URL: https://beaconnewbeginnings.org/support
Privacy Policy: https://beaconnewbeginnings.org/privacy
```

### Pricing
- **Price**: Free
- **Availability**: Ghana (initially)
- **Distribution**: App Store

## 📸 **Screenshots Required**

### iPhone Screenshots (Required)
- **6.7" Display** (iPhone 14 Pro Max): 1290 x 2796 px
- **6.5" Display** (iPhone 11 Pro Max): 1242 x 2688 px  
- **5.5" Display** (iPhone 8 Plus): 1242 x 2208 px

### iPad Screenshots (Optional but Recommended)
- **12.9" Display** (iPad Pro): 2048 x 2732 px
- **11" Display** (iPad Air): 1668 x 2388 px

### Screenshot Content
1. **Login Screen**: Showing anonymous access option
2. **Home Screen**: Emergency button prominent
3. **Emergency Services**: Contact list
4. **Resources Directory**: Categories view
5. **Community Support**: Groups/stories
6. **Profile Settings**: Privacy controls

## ⚡ **Quick Commands Summary**

```bash
# Fix iOS build
cd ios && rm -rf Pods Podfile.lock .symlinks && cd ..
flutter clean && flutter pub get
cd ios && pod install && cd ..

# Build for release
flutter build ios --release

# Create IPA
flutter build ipa --release

# Check build
ls -la build/ios/ipa/
```

## 🐛 **Common Issues & Solutions**

### "No such module" Error
```bash
flutter clean
cd ios && rm -rf Pods && pod install
```

### Code Signing Issues
```bash
# Build without signing first
flutter build ios --release --no-codesign
```

### Archive Not Showing
- Ensure "Generic iOS Device" is selected
- Check deployment target is 14.0+
- Verify all required capabilities are enabled

## 📞 **If Build Still Fails**

### Alternative: Manual Xcode Build
1. `flutter build ios --debug` (to generate runner)
2. Open `ios/Runner.xcworkspace` in Xcode  
3. Set deployment target to 14.0
4. Product → Archive
5. Distribute manually

### Fallback: Web Version
The app also supports web deployment for immediate testing:
```bash
flutter build web --release
```

## ✅ **Success Indicators**

When iOS build succeeds, you'll see:
```
✓ Built build/ios/iphoneos/Runner.app
```

For IPA creation:
```
✓ Built IPA at build/ios/ipa/ngo_support_app.ipa
```

---

**Estimated Fix Time**: 30-60 minutes  
**Alternative**: Contact iOS developer for deployment target fixes  
**Priority**: High (needed for App Store submission)