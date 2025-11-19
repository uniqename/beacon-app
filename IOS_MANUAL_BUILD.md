# iOS Manual Build Instructions
**Due to CocoaPods/Xcode 16.4 Compatibility Issues**

## 🚨 Current Issue
CocoaPods 1.16.2 has a known compatibility issue with Xcode 16.4 causing:
- `Unable to load contents of file list: Pods-Runner-frameworks-Release-*.xcfilelist`
- Build script phase errors

## ✅ Working Solutions

### Option 1: Manual Xcode Archive (Recommended)

1. **Open Xcode**
   ```
   open ios/Runner.xcworkspace
   ```

2. **Clean Build Folder**
   - Product → Clean Build Folder (⌘⇧K)

3. **Archive Steps**
   - Select: Runner → Any iOS Device (or specific device)
   - Product → Archive (⌘⇧B then ⌘⇧A)
   - Wait for archive to complete
   - Xcode Organizer will open automatically

4. **Export IPA**
   - In Organizer → Archives tab
   - Select your archive → "Distribute App"
   - Choose distribution method:
     - **App Store Connect** (for TestFlight/App Store)
     - **Development** (for testing)
     - **Ad Hoc** (for limited distribution)
   - Follow export wizard
   - Save IPA to Desktop

### Option 2: Command Line Archive (Alternative)

```bash
# Navigate to iOS directory
cd ios

# Clean previous builds
rm -rf build/
rm -rf DerivedData/

# Archive the app
xcodebuild clean archive \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -archivePath ~/Desktop/BeaconNGO.xcarchive \
  -destination "generic/platform=iOS"

# Export IPA (requires Apple Developer account)
xcodebuild -exportArchive \
  -archivePath ~/Desktop/BeaconNGO.xcarchive \
  -exportPath ~/Desktop/ \
  -exportOptionsPlist ExportOptions.plist
```

### Option 3: Fix CocoaPods (Advanced)

Create `ExportOptions.plist` in ios folder:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>compileBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
```

## 🔧 Troubleshooting

### Issue: "No signing certificate found"
**Solution:**
1. Xcode → Preferences → Accounts
2. Add Apple ID account
3. Download certificates
4. Or use manual signing with p12 certificate

### Issue: "Build failed with provisioning profile"
**Solution:**
1. Select Runner project in Xcode
2. Signing & Capabilities tab
3. Enable "Automatically manage signing"
4. Select Development Team

### Issue: "Archive not showing in Organizer"
**Solution:**
1. Window → Organizer (⌘⇧O)
2. Archives tab
3. Refresh or check "All" apps

## 📱 App Store Submission

After successful IPA creation:

1. **TestFlight Distribution**
   - Upload IPA to App Store Connect
   - Submit for TestFlight review
   - Invite internal testers

2. **App Store Release**
   - Create App Store listing
   - Submit for App Store review
   - Average review time: 24-48 hours

## 🎯 Current Status

- ✅ **Android AAB**: Ready for Google Play Store
  - File: `~/Desktop/beacon-ngo-app-release.aab`
  - Size: 44.2MB
  - Status: Production signed

- 🔄 **iOS IPA**: Requires manual Xcode build
  - Issue: CocoaPods compatibility 
  - Solution: Manual archive via Xcode
  - Icons: ✅ Updated with NGO beacon design

## 📞 Support

If manual build fails:
1. Update to Xcode 16.5+ when available
2. Downgrade CocoaPods: `gem install cocoapods -v 1.15.2`
3. Use Flutter 3.24+ with better iOS 18 support

**Bottom Line:** Android is ready to ship, iOS needs manual Xcode archiving due to toolchain compatibility issues.