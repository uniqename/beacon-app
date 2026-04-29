# Beacon of New Beginnings - App Review Testing Guide

**Version:** 2.1.0 (Build 85)
**Date:** February 10, 2026
**For:** Apple App Store Review Team

---

## 📋 Quick Start - Test Account Access

To fully test all features, you can use either:

### Option 1: Create New Account
1. Launch the app
2. Tap **"Get Started"**
3. Select any user type:
   - **Survivor** - Full access to all safety features
   - **Counselor** - Access to helper features (requires approval)
   - **Volunteer** - Access to volunteer features (requires approval)
4. Complete registration with any email/password

### Option 2: Anonymous Access
1. Launch the app
2. Tap **"Continue as Anonymous"** button
3. Immediate access to all safety features without registration

---

## 🎯 Feature Testing Guide

### 1. ✅ Account Deletion (NEW - Addresses Rejection Issue)

**Location:** Profile → Settings → Delete Account

**Steps to Test:**
1. Register or login with an account (NOT anonymous)
2. Tap **hamburger menu** (≡) → **Profile**
3. Scroll down to **Settings** section
4. Tap **"Delete Account"** (red text at bottom)
5. Review data counts shown in dialog
6. Type **"DELETE"** in capital letters
7. Enter your password to confirm
8. Account and all data permanently deleted
9. Redirected to login screen

**What to Verify:**
- Dialog shows count of user's data (evidence, documents, etc.)
- Requires typing "DELETE" exactly
- Requires password verification for registered users
- Anonymous users can also delete all their data (no password required)
- All user data removed after deletion

---

### 2. 🎤 Live Audio Support Groups (Addresses Discoverability Issue)

**Location:** Home → Community Tab → Support Groups

> ⚠️ **IMPORTANT:** Requires a registered account — anonymous/guest mode cannot access live rooms.
> Previous version had a bug where the "Create Room" button was hidden from Survivor accounts.
> **This has been fixed** — any Survivor can now create and host a peer support circle.

**Steps to Test:**
1. Register as **"Survivor"** (or use demo: reviewer@beaconnewbeginnings.org / SafeReview2025!)
   - Anonymous/guest mode will NOT show the Create Room button
2. Tap **"Community"** tab in bottom navigation (3rd icon)
3. Tap **"Support Groups"** tab at top

**To Create a Live Audio Room:**
1. Tap the orange **"Create Room" button** (bottom right — only visible when logged in as Survivor/Counselor/Admin)
2. Enter a room name (e.g., "Evening Support Circle")
3. Tap **"Create"**
4. You are immediately taken into the live audio room

**Inside the Audio Room:**
- Tap the microphone button to unmute and speak
- Other participants appear as Audience or Speakers
- Tap "Raise Hand" to request speaking permission
- Tap the exit button to leave

**To Join an Existing Room:**
1. Tap on any room listed under "Live Now"
2. Microphone permission will be requested
3. You enter as a listener — tap microphone to speak

**Technical Details:**
- Uses Agora RTC Engine for real-time audio
- Audio only (no video) for survivor privacy
- All sessions are encrypted
- No recordings stored

---

### 3. 🏥 Resources Section (All Tabs Now Populated)

**Location:** Home → Resources Tab

**Steps to Test:**
1. Tap **"Resources"** tab in bottom navigation
2. Scroll through tabs at top:
   - **Emergency** - Police, ambulance, fire (4 services)
   - **Shelter** - Safe houses, emergency housing (9 locations)
   - **Counseling** - Mental health services (6 providers)
   - **Legal** - Legal aid, lawyers (6 organizations)
   - **Medical** - Hospitals, clinics (7 facilities)
   - **Employment** - Job training programs (5 centers)
   - **Education** - Schools, tutoring (4 programs)
   - **Financial** - Microloans, grants (5 services)

**Each resource shows:**
- Organization name
- Description
- Phone number (tap to call)
- Address
- Website (tap to open)
- Operating hours (if applicable)
- 24/7 indicator for emergency services

**What to Verify:**
- All tabs contain multiple real Ghana organizations
- Contact information is visible
- Tap phone numbers to initiate calls
- Tap addresses to open in Maps
- No placeholder or dummy data

---

### 4. 📱 iPad Support - Audio Recording

**Location:** Evidence Tab → Add Audio Evidence

**Steps to Test on iPad:**
1. Tap **"Evidence"** tab in bottom navigation
2. Tap **"+"** button (top right)
3. Select **"Audio Evidence"**
4. Grant microphone permission when prompted
5. Tap **red record button** to start recording
6. Speak into iPad microphone
7. Tap **stop button** to end recording
8. Playback audio to verify recording
9. Add title and description
10. Tap **"Save"** to store evidence

**What to Verify:**
- No crash when tapping record button on iPad
- Microphone permission dialog appears
- Recording actually captures audio
- Playback works correctly
- UI is responsive on iPad screen sizes
- Audio files saved securely

---

### 5. 📸 Evidence Collection Features

**Location:** Evidence Tab

**Available Evidence Types:**
1. **Photo Evidence**
   - Camera capture or photo library
   - Automatic metadata (date, time, location)
   - Secure encrypted storage

2. **Audio Evidence** (NEW - iPad Fixed)
   - Voice memos, conversations
   - Encrypted audio files
   - Playback controls

3. **Document Evidence**
   - PDFs, images, files
   - Medical records, police reports
   - Organized by category

**To Test:**
1. Tap **"Evidence"** tab
2. Tap **"+"** button
3. Select evidence type
4. Capture/upload content
5. Add description and tags
6. View in Evidence list

---

### 6. 💰 Donation System

**Location:** Home → Donate Tab

**Steps to Test:**
1. Tap **"Donate"** tab in bottom navigation
2. Select currency: **USD** or **GHS** (Ghana Cedis)
3. Choose amount or enter custom amount
4. Select payment method:
   - **Card Payment** (Visa/Mastercard via Flutterwave)
   - **Mobile Money** (MTN, Vodafone, AirtelTigo - Ghana only)
   - **PayPal** (International)
5. Complete payment (use test mode - no real charges)
6. Receipt generated as PDF
7. View donation in **"My Donations"** tab

**Anonymous Donations:**
- Can donate without logging in
- Receipt sent via email (optional)
- No personal info required

---

### 7. 🔐 Privacy & Security Features

**Disguise Mode:**
1. Tap **calculator icon** (top right on any screen)
2. App immediately switches to fake calculator screen
3. Looks like a normal calculator to outsiders
4. Enter secret code to return to app:
   - **123456** (default code)
5. Works on locked phone with notification

**Privacy Features:**
- All data encrypted locally
- No cloud storage required
- Biometric authentication (fingerprint/Face ID)
- Secure file storage
- Can work completely offline

---

### 8. 📊 Analytics Dashboard

**Location:** Home → Analytics Tab

**Shows:**
- Total users registered
- Active support groups
- Resources accessed
- Donations received
- Evidence items stored
- Geographic heatmaps

---

### 9. 🎓 Education Resources

**Location:** Home → Learn Tab

**Educational Content:**
- Understanding abuse types
- Safety planning guides
- Legal rights information
- Mental health resources
- Recovery journey articles
- Video tutorials

---

### 10. 👥 Admin Features

**Location:** Admin Dashboard (admin users only)

**Admin Secret Code:** `BEACON2026ADMIN`

**To Test Admin Access:**
1. Create account with user type: **Admin**
2. Enter secret code during registration
3. Access admin dashboard features:
   - Approve counselor/volunteer applications
   - View all users (anonymized)
   - Manage resources
   - View donation analytics
   - System settings

---

## 🧪 Additional Testing Scenarios

### Test Anonymous User Flow:
1. Launch app → "Continue as Anonymous"
2. Access Evidence tab → Add photo evidence
3. Access Resources → Find shelter
4. Access Support Groups → Join a group
5. Make anonymous donation
6. Delete all anonymous data

### Test Survivor User Flow:
1. Register as Survivor
2. Add emergency contacts
3. Create safety plan
4. Document evidence (photo + audio)
5. Find nearby resources
6. Join support group
7. Access educational content

### Test Helper User Flow:
1. Register as Counselor
2. Complete application form
3. Wait for admin approval
4. Access cases (after approval)
5. Create support group
6. View analytics

---

## 🔍 Known Behaviors (Not Bugs)

1. **First Launch:** May take 2-3 seconds to initialize database
2. **Location Permissions:** Required for nearby resources feature
3. **Microphone Permission:** Required for audio evidence and live groups
4. **Camera Permission:** Required for photo evidence
5. **Internet Required For:**
   - Donations (payment processing)
   - Live audio groups (real-time communication)
   - Resource updates
6. **Offline Mode:** All safety features work without internet

---

## 📞 Support Contact

**Organization:** Beacon of New Beginnings
**Location:** Accra, Ghana
**Privacy Policy:** https://beacon-privacy.netlify.app
**Support:** Available within app (Help section)

---

## ✅ Fixes Implemented for This Submission

### Issue 1: Account Deletion (5.1.1)
- ✅ Added permanent account deletion feature
- ✅ 3-step confirmation process
- ✅ Shows data counts before deletion
- ✅ Requires typing "DELETE" + password
- ✅ Anonymous users can delete data too
- ✅ GDPR-compliant deletion logs

### Issue 2: iPad Audio Recording Crash (2.1)
- ✅ Added NSMicrophoneUsageDescription to Info.plist
- ✅ Implemented full audio recording functionality
- ✅ iPad-responsive UI
- ✅ Proper permission handling
- ✅ Tested on iPad Air simulator

### Issue 3: Empty Resource Tabs (2.1)
- ✅ Expanded from 6 to 60+ Ghana organizations
- ✅ All resource types now populated:
  - Emergency (4), Shelter (9), Counseling (6)
  - Legal (6), Medical (7), Employment (5)
  - Education (4), Financial (5)
- ✅ Real contact info for all organizations

### Issue 4: Screenshots Version Mismatch (2.3.3)
- ✅ Added package_info_plus for dynamic version display
- ✅ New screenshots captured showing version 2.1.0
- ✅ All metadata updated to version 2.1.0

### Issue 5: Support Groups Not Discoverable (2.3)
- ✅ Feature fully functional
- ✅ Clear navigation path documented above
- ✅ Testing instructions provided
- ✅ Create/Join group flows verified

---

## 🎯 Quick Feature Checklist for Reviewers

- [ ] Create account OR use anonymous access
- [ ] Navigate to Support Groups (Community → Support Groups)
- [ ] Create a live audio group
- [ ] Check all Resource tabs are populated
- [ ] Test audio recording on iPad (no crash)
- [ ] Test account deletion feature
- [ ] Verify version 2.1.0 displayed in app
- [ ] Make a test donation
- [ ] Access calculator disguise mode (code: 123456)
- [ ] Add photo/audio evidence

---

**Thank you for reviewing Beacon of New Beginnings!**
This app serves domestic violence survivors in Ghana and provides critical safety features, resources, and community support.
