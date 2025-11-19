#!/bin/bash

# 🍎 iOS Build Fix Script for Beacon of New Beginnings
# This script fixes the deployment target issues for Firebase pods

echo "🔧 Starting iOS Build Fix for Beacon of New Beginnings..."
echo "=================================================="

# Navigate to project directory
cd "$(dirname "$0")/ngo_support_app"

echo "📍 Current directory: $(pwd)"

# Step 1: Clean everything
echo "🧹 Step 1: Cleaning build artifacts..."
flutter clean
rm -rf .dart_tool

echo "🧹 Cleaning iOS-specific files..."
cd ios
rm -rf Pods
rm -rf Podfile.lock
rm -rf .symlinks
rm -rf build
cd ..

# Step 2: Update Podfile
echo "📝 Step 2: Updating Podfile with deployment target fix..."

# Create backup of original Podfile
cp ios/Podfile ios/Podfile.backup

# Update Podfile with deployment target fix
cat > ios/Podfile << 'EOF'
# Uncomment this line to define a global platform for your project
platform :ios, '14.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Fix deployment target for all pods to iOS 14.0
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      
      # Additional fixes for Firebase pods
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_LOCATION=1',
        'PERMISSION_NOTIFICATIONS=1',
      ]
      
      # Fix for arm64 simulator issues
      if config.name == 'Debug'
        config.build_settings['OTHER_SWIFT_FLAGS'] = ['$(inherited)', '-Xfrontend', '-warn-long-expression-type-checking=100']
      end
    end
  end
end
EOF

echo "✅ Podfile updated with deployment target fixes"

# Step 3: Reinstall dependencies
echo "📦 Step 3: Reinstalling Flutter dependencies..."
flutter pub get

echo "📦 Installing CocoaPods dependencies..."
cd ios
pod install --repo-update --verbose
cd ..

# Step 4: Test build
echo "🏗️  Step 4: Testing iOS build..."
flutter build ios --release --no-codesign

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ SUCCESS: iOS build completed successfully!"
    echo ""
    echo "🎯 Next steps:"
    echo "1. Open Xcode: open ios/Runner.xcworkspace"
    echo "2. Set up code signing in Xcode"
    echo "3. Archive: Product → Archive"
    echo "4. Upload to TestFlight"
    echo ""
    echo "📱 To create IPA file:"
    echo "flutter build ipa --release"
    echo ""
else
    echo "❌ FAILED: iOS build encountered errors"
    echo ""
    echo "🔧 Try these troubleshooting steps:"
    echo "1. Open Xcode: open ios/Runner.xcworkspace"
    echo "2. Check deployment target is set to 14.0"
    echo "3. Clean build in Xcode: Product → Clean Build Folder"
    echo "4. Try building in Xcode directly"
    echo ""
    echo "📞 For help, check TESTFLIGHT_DEPLOYMENT_GUIDE.md"
fi

echo ""
echo "=================================================="
echo "🍎 iOS Build Fix Script Complete"
echo "📁 Project location: $(pwd)"
echo "📋 Check TESTFLIGHT_DEPLOYMENT_GUIDE.md for full instructions"
EOF