#!/bin/bash

# ScreenGuard Build Script
# This script builds the ScreenGuard application

set -e

echo "🏗️  Building ScreenGuard..."
echo "================================"

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: Xcode is not installed or xcodebuild is not in PATH"
    echo "Please install Xcode from the App Store"
    exit 1
fi

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf build/

# Build the project
echo "🔨 Building ScreenGuard (Release configuration)..."
xcodebuild \
    -project ScreenGuard.xcodeproj \
    -scheme ScreenGuard \
    -configuration Release \
    -derivedDataPath build \
    build

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    echo "📱 Your app is ready at:"
    echo "   build/Build/Products/Release/ScreenGuard.app"
    echo ""
    echo "🚀 To run the app:"
    echo "   open build/Build/Products/Release/ScreenGuard.app"
    echo ""
    echo "📝 Next steps:"
    echo "   1. Run the app and grant camera permissions"
    echo "   2. The app will appear in your menu bar"
    echo "   3. Sit at normal distance for calibration"
    echo "   4. Enjoy healthier screen time!"
    echo ""
    echo "⚠️  Note: You may need to allow the app in System Preferences > Privacy & Security"
else
    echo "❌ Build failed. Please check the errors above."
    exit 1
fi
