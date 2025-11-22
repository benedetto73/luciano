# PresentationGenerator - Deployment Guide

**Version:** 1.0.0  
**Last Updated:** November 22, 2025

---

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Build Configuration](#build-configuration)
3. [Code Signing](#code-signing)
4. [Distribution Methods](#distribution-methods)
5. [Mac App Store](#mac-app-store-distribution)
6. [Direct Distribution](#direct-distribution)
7. [Notarization](#notarization)
8. [CI/CD Setup](#cicd-setup)
9. [Version Management](#version-management)
10. [Post-Deployment](#post-deployment)

---

## Pre-Deployment Checklist

### Code Quality

- [ ] All tests passing
- [ ] No compiler warnings
- [ ] Code reviewed and approved
- [ ] Documentation complete
- [ ] CHANGELOG updated

### Testing

- [ ] Manual testing on multiple macOS versions (13.0+)
- [ ] Performance testing with large projects (50+ slides)
- [ ] Real OpenAI API testing
- [ ] Export functionality verified
- [ ] Error handling tested
- [ ] Accessibility tested (VoiceOver)

### Assets

- [ ] App icon (1024x1024)
- [ ] Launch screen/splash
- [ ] Screenshots for App Store (if applicable)
- [ ] Privacy policy
- [ ] Terms of service

### Legal

- [ ] License file included (LICENSE)
- [ ] Third-party licenses documented
- [ ] Privacy policy compliant
- [ ] OpenAI terms of service acknowledged

---

## Build Configuration

### Project Settings

**Info.plist Configuration:**

```xml
<key>CFBundleName</key>
<string>PresentationGenerator</string>
<key>CFBundleDisplayName</key>
<string>Presentation Generator</string>
<key>CFBundleIdentifier</key>
<string>com.yourcompany.presentationgenerator</string>
<key>CFBundleVersion</key>
<string>1</string>
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
<key>LSMinimumSystemVersion</key>
<string>13.0</string>
<key>NSHumanReadableCopyright</key>
<string>Copyright © 2025 Your Company. All rights reserved.</string>
```

**Required Capabilities:**

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
</dict>
```

**Privacy Descriptions:**

```xml
<key>NSNetworkUsageDescription</key>
<string>This app uses the internet to connect to OpenAI services for AI-powered content generation.</string>
```

### Build Settings

**In Xcode (if using Xcode project):**

1. Set **Deployment Target**: macOS 13.0
2. Enable **Hardened Runtime**: Yes
3. Set **Bundle Identifier**: com.yourcompany.presentationgenerator
4. Set **Version**: 1.0.0
5. Set **Build Number**: 1

**In Package.swift:**

```swift
let package = Package(
    name: "PresentationGenerator",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "PresentationGenerator",
            targets: ["PresentationGenerator"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/MacPaw/OpenAI", from: "0.2.4")
    ],
    targets: [
        .executableTarget(
            name: "PresentationGenerator",
            dependencies: ["OpenAI"]
        )
    ]
)
```

---

## Code Signing

### Apple Developer Account

**Requirements:**
1. **Apple Developer Program** membership ($99/year)
2. **Developer ID** certificate
3. **App ID** registered

### Creating Certificates

**Via Xcode:**
1. Open Xcode → Preferences → Accounts
2. Add Apple ID
3. Select team → Manage Certificates
4. Click **+** → Select certificate type:
   - **Mac App Distribution** (for App Store)
   - **Developer ID Application** (for direct distribution)

**Via Developer Portal:**
1. Visit https://developer.apple.com/account
2. Certificates, Identifiers & Profiles
3. Create new certificate
4. Download and install

### Signing the App

**Command Line:**

```bash
# Sign with Developer ID
codesign --deep --force --verify --verbose \
    --sign "Developer ID Application: Your Name (TEAM_ID)" \
    --options runtime \
    PresentationGenerator.app

# Verify signature
codesign --verify --deep --strict --verbose=2 PresentationGenerator.app
spctl -a -vvv -t execute PresentationGenerator.app
```

**Xcode:**
1. Select target → Signing & Capabilities
2. Enable "Automatically manage signing"
3. Select team
4. Choose signing certificate

### Entitlements

**PresentationGenerator.entitlements:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.downloads.read-write</key>
    <true/>
</dict>
</plist>
```

---

## Distribution Methods

### Option 1: Mac App Store

**Pros:**
- ✅ Trusted distribution
- ✅ Automatic updates
- ✅ Wider audience reach
- ✅ Payment processing included

**Cons:**
- ❌ App review required (1-2 weeks)
- ❌ 30% commission on sales
- ❌ Strict sandboxing requirements
- ❌ Cannot use all system APIs

### Option 2: Direct Distribution

**Pros:**
- ✅ Full control
- ✅ No commission fees
- ✅ Faster updates
- ✅ Fewer restrictions

**Cons:**
- ❌ Notarization required
- ❌ Manual update system needed
- ❌ Handle payments yourself
- ❌ Less trust from users

### Option 3: TestFlight (Beta)

**Pros:**
- ✅ Beta testing before release
- ✅ Easy distribution to testers
- ✅ Analytics and feedback

**Cons:**
- ❌ Limited to 100 testers
- ❌ 90-day build expiration

---

## Mac App Store Distribution

### Preparation

**1. Create App Record:**
1. Visit https://appstoreconnect.apple.com
2. My Apps → **+** → New App
3. Fill in details:
   - Name: PresentationGenerator
   - Primary Language: English
   - Bundle ID: com.yourcompany.presentationgenerator
   - SKU: PRESGEN001

**2. App Information:**
- **Category**: Education or Productivity
- **Description**: AI-powered presentation generator
- **Keywords**: presentation, slides, education, AI, PowerPoint
- **Screenshots**: 1280x800 or 2880x1800
- **Privacy Policy URL**: Required

**3. Pricing:**
- Select pricing tier or Free
- Availability: All territories or specific

### Building for App Store

**Archive the App:**

```bash
# Generate Xcode project from SPM
swift package generate-xcodeproj

# Open in Xcode
open PresentationGenerator.xcodeproj

# Product → Archive
# Or via command line:
xcodebuild archive \
    -scheme PresentationGenerator \
    -archivePath build/PresentationGenerator.xcarchive

# Export for App Store
xcodebuild -exportArchive \
    -archivePath build/PresentationGenerator.xcarchive \
    -exportPath build/AppStore \
    -exportOptionsPlist ExportOptions.plist
```

**ExportOptions.plist:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
</dict>
</plist>
```

### Upload to App Store

**Via Xcode:**
1. Window → Organizer
2. Select archive
3. Distribute App → App Store Connect
4. Upload

**Via Transporter App:**
1. Export .pkg from Xcode
2. Open Transporter app
3. Drag and drop .pkg
4. Deliver

**Via Command Line:**

```bash
xcrun altool --upload-app \
    --type macos \
    --file PresentationGenerator.pkg \
    --username "your@email.com" \
    --password "app-specific-password"
```

### App Review Submission

**1. Build Selection:**
- Select uploaded build
- Add "What's New" notes

**2. Review Information:**
- Contact information
- Demo account (if needed)
- Notes for reviewer

**3. Submit for Review:**
- Click "Submit for Review"
- Wait 1-2 weeks for approval

---

## Direct Distribution

### Notarization (Required for macOS 10.15+)

**Why Notarize?**
- Prevents "App is damaged" messages
- Required for distribution outside App Store
- Validates app integrity

**Steps:**

**1. Sign with Hardened Runtime:**

```bash
codesign --deep --force --verify --verbose \
    --sign "Developer ID Application: Your Name (TEAM_ID)" \
    --options runtime \
    --entitlements PresentationGenerator.entitlements \
    PresentationGenerator.app
```

**2. Create DMG or ZIP:**

```bash
# DMG (recommended)
hdiutil create -volname "PresentationGenerator" \
    -srcfolder PresentationGenerator.app \
    -ov -format UDZO \
    PresentationGenerator.dmg

# Or ZIP
ditto -c -k --keepParent PresentationGenerator.app PresentationGenerator.zip
```

**3. Submit for Notarization:**

```bash
# Create app-specific password at appleid.apple.com
# Store credentials
xcrun notarytool store-credentials "AC_PASSWORD" \
    --apple-id "your@email.com" \
    --team-id "YOUR_TEAM_ID"

# Submit
xcrun notarytool submit PresentationGenerator.dmg \
    --keychain-profile "AC_PASSWORD" \
    --wait

# Check status
xcrun notarytool info SUBMISSION_ID \
    --keychain-profile "AC_PASSWORD"
```

**4. Staple Notarization:**

```bash
# Staple ticket to DMG
xcrun stapler staple PresentationGenerator.dmg

# Verify
spctl -a -vv -t install PresentationGenerator.dmg
```

### Creating DMG Installer

**Custom DMG with background:**

```bash
# 1. Create temporary DMG
hdiutil create -size 200m -fs HFS+ -volname "PresentationGenerator" temp.dmg

# 2. Mount and customize
hdiutil attach temp.dmg
cp -R PresentationGenerator.app /Volumes/PresentationGenerator/
ln -s /Applications /Volumes/PresentationGenerator/Applications

# 3. Add background image
mkdir /Volumes/PresentationGenerator/.background
cp background.png /Volumes/PresentationGenerator/.background/

# 4. Detach
hdiutil detach /Volumes/PresentationGenerator

# 5. Convert to compressed
hdiutil convert temp.dmg -format UDZO -o PresentationGenerator.dmg
rm temp.dmg
```

### Distribution Checklist

- [ ] App signed with Developer ID
- [ ] Hardened Runtime enabled
- [ ] Entitlements configured
- [ ] Notarized by Apple
- [ ] Stapled to DMG
- [ ] Tested on clean machine
- [ ] Download link works
- [ ] Auto-update configured (if applicable)

---

## CI/CD Setup

### GitHub Actions

**.github/workflows/build.yml:**

```yaml
name: Build and Test

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: macos-13
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Select Xcode
      run: sudo xcode-select -s /Applications/Xcode_15.0.app
    
    - name: Build
      run: swift build -c release
    
    - name: Run tests
      run: swift test
    
    - name: Archive
      if: github.ref == 'refs/heads/main'
      run: |
        swift build -c release
        mkdir -p build
        cp .build/release/PresentationGenerator build/
```

### Release Automation

**.github/workflows/release.yml:**

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: macos-13
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Build Release
      run: swift build -c release
    
    - name: Create DMG
      run: |
        # DMG creation script here
    
    - name: Create Release
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        tag_name: ${{ github.ref }}
        release_name: Release ${{ github.ref }}
        draft: false
        prerelease: false
    
    - name: Upload DMG
      uses: actions/upload-release-asset@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        upload_url: ${{ steps.create_release.outputs.upload_url }}
        asset_path: ./PresentationGenerator.dmg
        asset_name: PresentationGenerator.dmg
        asset_content_type: application/octet-stream
```

---

## Version Management

### Semantic Versioning

Format: `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

**Example:**
- `1.0.0` - Initial release
- `1.1.0` - Added new audience types
- `1.1.1` - Fixed export bug
- `2.0.0` - Complete UI redesign

### Version Update Process

**1. Update Version Numbers:**

```swift
// AppInfo.swift
static var version: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
}

static var build: String {
    Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
}
```

**2. Update CHANGELOG.md:**

```markdown
## [1.1.0] - 2025-11-22

### Added
- Support for Seniors and Professionals audiences
- Auto-save functionality
- Keyboard shortcuts

### Fixed
- Export to PowerPoint issue
- Image loading performance

### Changed
- Improved AI content generation
```

**3. Tag Release:**

```bash
git tag -a v1.1.0 -m "Release version 1.1.0"
git push origin v1.1.0
```

---

## Post-Deployment

### Monitoring

**Analytics to Track:**
- Downloads/installs
- Active users (DAU/MAU)
- Feature usage
- Crash reports
- Error rates
- API usage costs

**Tools:**
- Crashlytics or Sentry for crash reporting
- Google Analytics or Mixpanel for usage
- Custom logging for errors

### Support

**Documentation:**
- User guide published
- FAQ updated
- Video tutorials (optional)

**Support Channels:**
- GitHub Issues
- Email support
- Discord/Slack community

### Updates

**Update Frequency:**
- Bug fixes: As needed
- Features: Monthly or quarterly
- Security: Immediately

**Release Notes Template:**

```markdown
## Version X.Y.Z

**Release Date:** YYYY-MM-DD

### What's New
- New feature 1
- New feature 2

### Improvements
- Performance optimization
- UI enhancements

### Bug Fixes
- Fixed issue with export
- Resolved crash on startup

### Known Issues
- Minor display issue on macOS Sonoma (fixing in next release)
```

---

## Troubleshooting

### Common Issues

**"App is damaged and can't be opened"**
- **Cause**: Not notarized
- **Solution**: Complete notarization process

**"This app is not signed"**
- **Cause**: Missing code signature
- **Solution**: Sign with Developer ID

**Build fails with "No such module 'XCTest'"**
- **Cause**: SPM limitation for executable targets
- **Solution**: Generate Xcode project first

**Users can't download DMG**
- **Cause**: File size or server issue
- **Solution**: Host on GitHub Releases or CDN

---

## Resources

- **Apple Developer**: https://developer.apple.com
- **App Store Connect**: https://appstoreconnect.apple.com
- **Notarization Guide**: https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution
- **Human Interface Guidelines**: https://developer.apple.com/design/human-interface-guidelines/macos

---

**Ready to Deploy! 🚀**

For questions about deployment, consult Apple's documentation or reach out to the development team.
