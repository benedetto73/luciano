#!/bin/bash
# filepath: scripts/create_app_bundle.sh

set -e

echo "📦 Building PresentationGenerator for distribution..."

# Build release
swift build -c release

# Create app bundle structure
APP_NAME="PresentationGenerator"
BUILD_DIR=".build/release"
DIST_DIR="dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

# Clean and create
rm -rf "$DIST_DIR"
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

# Copy executable
cp "$BUILD_DIR/$APP_NAME" "$MACOS/"

# Create Info.plist
cat > "$CONTENTS/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>PresentationGenerator</string>
    <key>CFBundleIdentifier</key>
    <string>com.presentationgenerator.app</string>
    <key>CFBundleName</key>
    <string>Presentation Generator</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# Create DMG
echo "📀 Creating DMG..."
hdiutil create -volname "Presentation Generator" \
    -srcfolder "$DIST_DIR" \
    -ov -format UDZO \
    "$DIST_DIR/PresentationGenerator.dmg"

echo "✅ Done! Your app is ready:"
echo "   📦 App bundle: $APP_BUNDLE"
echo "   💿 Disk image: $DIST_DIR/PresentationGenerator.dmg"
echo ""
echo "Share PresentationGenerator.dmg with your friend!"
echo ""
echo "⚠️  Note: Your friend will need to right-click → Open on first launch"
echo "   (macOS security for unsigned apps)"