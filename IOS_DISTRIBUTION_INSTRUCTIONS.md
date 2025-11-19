# iOS IPA Creation Instructions
**Manual Steps Required Due to CocoaPods/Xcode Issues**

## 🚨 Current Blocking Issues
1. **Provisioning Profile**: No profiles for `com.beaconnewbeginnings.ngo-support-app`
2. **CocoaPods**: xcfilelist file missing errors
3. **Xcode 16.4**: Compatibility issues with current toolchain

## ✅ **SOLUTION: Manual Xcode Archive**

### Step 1: Open Xcode
```bash
open ios/Runner.xcworkspace
```

### Step 2: Fix Signing (Critical)
1. **Select Runner Project** (top of file tree)
2. **Select Runner Target** 
3. **Signing & Capabilities Tab**
4. **Enable "Automatically manage signing"**
5. **Select your Development Team**
6. **Verify Bundle ID**: `com.beaconnewbeginnings.ngo-support-app`

### Step 3: Clean Build
- **Product → Clean Build Folder** (⌘⇧K)
- Wait for completion

### Step 4: Archive
1. **Select**: Runner → **Any iOS Device** (top left dropdown)
2. **Product → Archive** (⌘⇧A)
3. **Wait** for archive process (may take 5-10 minutes)
4. **Xcode Organizer** will open automatically

### Step 5: Export IPA
1. **In Organizer → Archives tab**
2. **Select your archive → "Distribute App"**
3. **Choose method:**
   - **Development** (for testing)
   - **App Store Connect** (for TestFlight/App Store)
4. **Follow export wizard**
5. **Save IPA** to Desktop

## 🔧 **Troubleshooting**

### Issue: "No Development Team"
**Solution:**
1. Xcode → Settings → Accounts
2. Add Apple ID
3. Sign into developer account
4. Download certificates

### Issue: "Provisioning Profile Error"
**Solution:**
1. Enable automatic signing (Step 2 above)
2. Or manually create provisioning profile at [developer.apple.com](https://developer.apple.com)

### Issue: "Build Errors from Pods"
**Solution:**
1. Try archiving anyway - often succeeds despite warnings
2. Or clean DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData`

## 📱 **Alternative: Use Development Distribution**

If App Store signing fails, create development IPA:

1. **Xcode → Preferences → Accounts**
2. **Add Personal Team** (free Apple ID)
3. **Change Bundle ID** to `com.yourname.ngo-support-app`
4. **Archive with Development signing**

## 🎯 **Expected Results**

**After successful archive:**
- `BeaconNGO.ipa` file on Desktop
- Size: ~50-80MB
- Ready for TestFlight upload or device installation

## 📤 **App Store Submission**

1. **Upload to App Store Connect**:
   - Use Xcode Organizer "Upload to App Store"
   - Or use Transporter app
   
2. **TestFlight**:
   - Internal testing: immediate
   - External testing: requires review

3. **App Store Review**:
   - Create app listing
   - Submit for review
   - Average: 24-48 hours

## ⚠️ **Known Limitations**

Due to current toolchain issues:
- **Manual build required** (not automated)
- **Xcode workspace must open successfully**
- **Valid Apple Developer account needed**

## 📞 **If Build Still Fails**

**Contact Apple Developer Support:**
- Provisioning profile issues
- Certificate problems
- Bundle ID conflicts

**Or wait for:**
- Xcode 16.5+ with CocoaPods fixes
- Flutter 3.25+ with better iOS 18 support

---

## 🎯 **Current Project Status**

- ✅ **Android AAB**: Ready for Google Play Store (`~/Desktop/beacon-ngo-app-release.aab`)
- 🔄 **iOS IPA**: Requires manual Xcode build (this document)
- ✅ **Website**: Deployed to Netlify (auto-updates from GitHub)
- ✅ **GitHub**: Updated with website code

**The iOS app just needs manual Xcode archiving due to current toolchain compatibility issues.**