#!/bin/bash

# Android-Only Build Script for Google Play
# This script builds ONLY for Android to avoid affecting your live iOS App Store version

echo "🤖 Building Beacon App for Android (Google Play) Only"
echo "📱 This will NOT affect your iOS App Store version"
echo ""

# Ensure we're in the right directory
cd "$(dirname "$0")"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build Android APK (debug for testing)
echo "🔨 Building Android APK (debug)..."
flutter build apk --debug

# Build Android App Bundle (release for Google Play)
echo "📱 Building Android App Bundle for Google Play..."
flutter build appbundle --release

echo ""
echo "✅ Android build complete!"
echo "📁 Files created:"
echo "   - Debug APK: build/app/outputs/flutter-apk/app-debug.apk"
echo "   - Release AAB: build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "🚀 Upload app-release.aab to Google Play Console"
echo "🍏 Your iOS App Store version is unchanged!"