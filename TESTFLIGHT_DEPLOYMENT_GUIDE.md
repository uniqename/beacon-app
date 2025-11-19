# 📱 TestFlight Deployment Guide - Beacon of New Beginnings

## 🎯 **Complete Step-by-Step Process**

### Prerequisites Checklist ✅
- [ ] Apple Developer Account ($99/year)
- [ ] Xcode installed (latest version)
- [ ] Flutter SDK installed
- [ ] macOS device for building
- [ ] App Store Connect access

---

## **PHASE 1: FIX iOS BUILD ISSUES** 🔧

### Step 1: Update Podfile Configuration
```bash
cd /Users/enamegyir/Documents/Projects/blazer_home_services_app/beacon-of-new-beginnings/ngo_support_app
```

Open `ios/Podfile` and replace the post_install section:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Fix deployment target for all pods
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      
      # Fix other common iOS build issues
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_LOCATION=1',
        'PERMISSION_NOTIFICATIONS=1',
      ]
    end
  end
end
```

### Step 2: Clean and Rebuild Dependencies
```bash
# Clean everything
cd ios
rm -rf Pods Podfile.lock .symlinks
cd ..
flutter clean
rm -rf .dart_tool

# Reinstall dependencies
flutter pub get
cd ios
pod install --repo-update
cd ..
```

### Step 3: Fix Xcode Project Settings
```bash
# Open Xcode project
open ios/Runner.xcworkspace
```

In Xcode:
1. **Select Runner Project** (top of file navigator)
2. **Select Runner Target** 
3. **Build Settings Tab**
4. **Search for "deployment"**
5. **Set iOS Deployment Target to 14.0**
6. **Search for "excluded"**
7. **Add `arm64` to Excluded Architectures for Simulator**

### Step 4: Test Build Locally
```bash
# Test the build first
flutter build ios --release --no-codesign
```

If successful, you'll see: `✓ Built build/ios/iphoneos/Runner.app`

---

## **PHASE 2: APPLE DEVELOPER SETUP** 🍎

### Step 5: Apple Developer Account Setup

#### 5.1 Create/Access Apple Developer Account
1. Go to [developer.apple.com](https://developer.apple.com)
2. Sign in with Apple ID
3. Enroll in Developer Program ($99/year)
4. Complete verification process (can take 24-48 hours)

#### 5.2 Create App Store Connect App Record
1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click **"My Apps"**
3. Click **"+"** → **"New App"**
4. Fill out app information:
   - **Platform**: iOS
   - **Name**: Beacon of New Beginnings
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: `com.beaconnewbeginnings.ngo-support-app`
   - **SKU**: `beacon-ngo-v1-2024`

#### 5.3 Set Up App Information
1. **App Information Tab**:
   - Category: Medical
   - Age Rating: 17+
   - Privacy Policy URL: `https://beaconnewbeginnings.org/privacy`
   - Support URL: `https://beaconnewbeginnings.org/support`

2. **Pricing and Availability**:
   - Price: Free
   - Availability: All Countries (or Ghana specifically)

---

## **PHASE 3: PREPARE APP METADATA** 📝

### Step 6: Create App Store Metadata

#### 6.1 App Description
**App Name**: Beacon of New Beginnings

**Subtitle** (30 characters max):
"Safe haven for survivors"

**App Description**:
```
Beacon of New Beginnings provides a safe, confidential platform for survivors of domestic violence, abuse, and homelessness in Ghana.

🚨 EMERGENCY FEATURES
• 24/7 crisis support with location alerts
• Direct access to police and medical services
• Anonymous reporting for safety
• Quick exit feature

🏠 ESSENTIAL RESOURCES
• Shelter and accommodation finder
• Legal aid and advocacy services
• Healthcare and mental health support
• Comprehensive service directory

👥 COMMUNITY SUPPORT
• Anonymous support groups
• Success stories for inspiration
• Educational workshops and events
• Peer-to-peer connections

🔒 PRIVACY-FIRST DESIGN
• Anonymous access for crisis situations
• End-to-end encryption for sensitive data
• No tracking without consent
• Trauma-informed interface

This app prioritizes survivor safety and empowerment. Whether you need immediate help or long-term support resources, Beacon of New Beginnings helps you rebuild your life with dignity and hope.

Available in English with local Ghana emergency contacts and resources.
```

**Keywords** (100 characters max):
```
domestic violence,survivor support,emergency,mental health,Ghana,crisis,shelter,legal aid,community
```

#### 6.2 What's New in This Version
```
🌟 Initial Release - Beacon of New Beginnings

• Anonymous access for immediate crisis support
• Emergency services with Ghana local contacts
• Comprehensive resource directory
• Community support features
• Privacy-focused design for survivor safety
• Trauma-informed user interface

Our mission: Providing safety, healing, and empowerment to survivors of abuse and homelessness in Ghana.
```

---

## **PHASE 4: CREATE SCREENSHOTS** 📸

### Step 7: Take App Screenshots

#### 7.1 Required Screenshot Sizes
You need screenshots for these device sizes:
- **6.7"** (iPhone 14 Pro Max): 1290 x 2796 px
- **6.5"** (iPhone 11 Pro Max): 1242 x 2688 px
- **5.5"** (iPhone 8 Plus): 1242 x 2208 px

#### 7.2 Screenshot Content (6 screenshots needed)
1. **Login Screen** - showing anonymous access option
2. **Home Screen** - emergency button prominent
3. **Emergency Services** - contact list with Ghana numbers
4. **Resources Directory** - shelter, legal, health categories
5. **Community Features** - support groups or stories
6. **Profile Screen** - privacy and safety settings

#### 7.3 Taking Screenshots
```bash
# Run app in simulator
flutter run -d "iPhone 15 Pro Max"

# Navigate through app and take screenshots:
# Simulator → Device → Screenshots → Save to Desktop
```

---

## **PHASE 5: BUILD AND ARCHIVE** 🏗️

### Step 8: Create Release Build

#### 8.1 Configure Code Signing
In Xcode (`ios/Runner.xcworkspace`):
1. **Select Runner Target**
2. **Signing & Capabilities Tab**
3. **Team**: Select your Apple Developer Team
4. **Bundle Identifier**: Verify `com.beaconnewbeginnings.ngo-support-app`
5. **Automatically manage signing**: ✅ Enabled

#### 8.2 Build Archive
```bash
# Method 1: Flutter Command (Recommended)
flutter build ipa --release

# Method 2: Xcode Archive
# In Xcode: Product → Archive
```

#### 8.3 Verify Build Success
If successful with Flutter:
```bash
ls -la build/ios/ipa/
# Should show: ngo_support_app.ipa
```

---

## **PHASE 6: UPLOAD TO TESTFLIGHT** 🚀

### Step 9: Upload Build

#### 9.1 Upload via Xcode (Easiest Method)
1. **Open Xcode**
2. **Window → Organizer**
3. **Select your Archive**
4. **Distribute App**
5. **App Store Connect**
6. **Upload**
7. **Next** through all steps
8. **Upload**

#### 9.2 Alternative: Upload IPA via Application Loader
1. **Download Transporter from App Store**
2. **Open Transporter**
3. **Add your IPA file**: `build/ios/ipa/ngo_support_app.ipa`
4. **Deliver**

#### 9.3 Upload via Command Line
```bash
# Using Xcode command line tools
xcrun altool --upload-app -f build/ios/ipa/ngo_support_app.ipa -u your-apple-id@email.com -p your-app-specific-password
```

---

## **PHASE 7: CONFIGURE TESTFLIGHT** 🧪

### Step 10: Set Up TestFlight Testing

#### 10.1 Wait for Processing
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. **My Apps** → **Beacon of New Beginnings**
3. **TestFlight Tab**
4. Wait for "Processing" to complete (5-30 minutes)

#### 10.2 Add Test Information
Once processing is complete:
1. **Click on your build number**
2. **Test Information**:
   - **What to Test**: 
     ```
     🔥 PRIORITY TESTING AREAS:
     
     1. ANONYMOUS LOGIN
     - Test "Continue Anonymously" button
     - Verify home screen loads without crashes
     
     2. EMERGENCY FEATURES
     - Test emergency contacts functionality
     - Verify location services work
     - Test phone call integration
     
     3. NAVIGATION
     - Test all bottom tabs (Home, Resources, Community, Profile)
     - Verify back buttons work
     - Test profile screen features
     
     4. CORE FUNCTIONALITY
     - Browse resource categories
     - View community features
     - Test settings and privacy options
     
     ⚠️ KNOWN LIMITATIONS:
     - Uses demo Firebase (some features limited)
     - Placeholder emergency numbers
     - Sample content in resources
     
     🎯 FEEDBACK FOCUS:
     - App stability and performance
     - User interface feedback
     - Navigation ease
     - Any crashes or errors
     ```
   
   - **App Description**: Use same as App Store description
   - **Feedback Email**: `testflight@beaconnewbeginnings.org`
   - **Marketing URL**: `https://beaconnewbeginnings.org`
   - **Privacy Policy URL**: `https://beaconnewbeginnings.org/privacy`

#### 10.3 Create Test Groups

**Internal Testing** (Immediate access):
1. **TestFlight** → **Internal Testing**
2. **Create Group**: "Core Team"
3. **Add Internal Testers**: 
   - Add email addresses of team members
   - Max 100 internal testers
   - No review required

**External Testing** (Requires review):
1. **TestFlight** → **External Testing**
2. **Create Group**: "NGO Partners"
3. **Add External Testers**:
   - Add partner organizations
   - Max 10,000 external testers
   - Requires Apple review (1-3 days)

---

## **PHASE 8: DISTRIBUTE TESTFLIGHT LINKS** 📤

### Step 11: Share with Testers

#### 11.1 Internal Testers
- **Automatic**: Internal testers get email invitations
- **Manual**: Share TestFlight link from App Store Connect

#### 11.2 External Testers
- **Public Link**: Get shareable link from TestFlight tab
- **Example**: `https://testflight.apple.com/join/abc123xyz`

#### 11.3 Tester Instructions
Send this to testers:

```
📱 BEACON OF NEW BEGINNINGS - TESTFLIGHT TESTING

Thank you for helping test our survivor support app!

INSTALLATION STEPS:
1. Install TestFlight app from App Store
2. Click this link: [TestFlight Link]
3. Tap "Install" in TestFlight
4. Test the app features

TESTING FOCUS:
• Try anonymous login (no account needed)
• Test emergency features
• Browse resources and community
• Report any crashes or issues

FEEDBACK:
Please email: testflight@beaconnewbeginnings.org

PRIVACY NOTE:
This is a test version. Real emergency services 
are not connected yet.
```

---

## **PHASE 9: MONITOR AND ITERATE** 📊

### Step 12: Track Testing Progress

#### 12.1 Monitor TestFlight Analytics
1. **App Store Connect** → **TestFlight** → **Builds**
2. **View metrics**:
   - Number of testers
   - Install rate
   - Session duration
   - Crashes

#### 12.2 Collect Feedback
- **Crash Reports**: Review in App Store Connect
- **Tester Feedback**: Check TestFlight feedback
- **Direct Feedback**: Monitor testflight@beaconnewbeginnings.org

#### 12.3 Update Build if Needed
For new builds:
```bash
# Increment build number in pubspec.yaml
version: 1.0.0+2  # Increment the +number

# Build new version
flutter build ipa --release

# Upload new build following Step 9
```

---

## **PHASE 10: PREPARE FOR APP STORE** 🏪

### Step 13: App Store Submission Preparation

#### 13.1 Complete App Store Information
1. **Screenshots**: Upload all 6 screenshots
2. **App Review Information**:
   - Contact: `review@beaconnewbeginnings.org`
   - Phone: `+233-XXX-XXX-XXXX`
   - Review Notes:
     ```
     This app serves survivors of domestic violence in Ghana. 
     
     TESTING NOTES:
     - Use "Continue Anonymously" for quick access
     - Emergency features are for crisis support
     - Demo Firebase backend is used
     
     DEMO ACCOUNT (if needed):
     Email: demo@beaconnewbeginnings.org
     Password: DemoTest2024!
     
     Please test with sensitivity to the vulnerable 
     population this app serves.
     ```

#### 13.2 Export Compliance
- **Uses Encryption**: Yes (HTTPS only)
- **Qualifies for exemption**: Yes (standard encryption)

#### 13.3 Content Rights
- **Third-party content**: No
- **Advertising**: No

---

## **TROUBLESHOOTING GUIDE** 🔧

### Common Issues and Solutions

#### Build Failures
```bash
# Clean everything and retry
flutter clean
cd ios && rm -rf Pods Podfile.lock && pod install
flutter build ios --release
```

#### Code Signing Issues
1. **Check Apple Developer Account status**
2. **Verify certificates in Xcode**
3. **Try automatic signing**

#### Upload Failures
1. **Check internet connection**
2. **Verify Apple ID credentials**
3. **Try Transporter app instead of Xcode**

#### TestFlight Not Showing
1. **Wait for processing (up to 30 minutes)**
2. **Check email for rejection notices**
3. **Verify build uploaded successfully**

---

## **TIMELINE EXPECTATIONS** ⏰

### Realistic Timeline
- **Phase 1-2** (Build Fix + Setup): 2-4 hours
- **Phase 3-4** (Metadata + Screenshots): 2-3 hours
- **Phase 5-6** (Build + Upload): 1-2 hours
- **Phase 7** (TestFlight Setup): 30 minutes
- **Apple Processing**: 5-30 minutes
- **External Review**: 1-3 days (if needed)

### Total Time: 1-2 days for complete TestFlight deployment

---

## **SUCCESS CHECKLIST** ✅

When everything is working:
- [ ] App builds successfully in Xcode
- [ ] IPA file created without errors
- [ ] Upload to App Store Connect successful
- [ ] Build appears in TestFlight
- [ ] Processing completes without issues
- [ ] Internal testers can install
- [ ] App launches and functions properly
- [ ] External testing approved (if applicable)
- [ ] Public TestFlight link available

---

## **QUICK COMMAND REFERENCE** 💨

```bash
# Complete build process
cd beacon-of-new-beginnings/ngo_support_app
flutter clean
cd ios && rm -rf Pods Podfile.lock && pod install && cd ..
flutter build ipa --release

# Check output
ls -la build/ios/ipa/

# Open for upload
open ios/Runner.xcworkspace
```

---

**🎯 Goal**: Get Beacon of New Beginnings on TestFlight for beta testing  
**📱 Result**: Public beta link for survivor support app testing  
**🔄 Next**: Iterate based on feedback, then submit to App Store

**Support**: For technical issues, contact the development team at tech@beaconnewbeginnings.org