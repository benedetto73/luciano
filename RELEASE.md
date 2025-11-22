# Release Configuration Guide

## Version: 1.0.0
**Release Date**: November 22, 2025

---

## Pre-Release Checklist

### Code Quality
- [x] All compilation errors resolved
- [x] All warnings addressed
- [x] Code reviewed and refactored
- [x] Dead code removed
- [x] Documentation complete
- [x] Performance optimizations applied

### Testing
- [x] Unit tests written (100+ tests)
- [x] Integration tests completed
- [x] UI flow tests created
- [x] Performance tests included
- [ ] Manual testing on macOS 13.0+
- [ ] Manual testing on macOS 14.0+
- [ ] Manual testing on macOS 15.0+ (Sequoia)

### Features
- [x] All core features implemented
- [x] OpenAI integration complete
- [x] File import working
- [x] Slide generation functional
- [x] Export capabilities ready
- [x] Error handling comprehensive
- [x] Auto-save implemented
- [x] Keyboard shortcuts working

### Documentation
- [x] README.md complete
- [x] USER_GUIDE.md created
- [x] ARCHITECTURE.md documented
- [x] API_DOCUMENTATION.md finished
- [x] DEPLOYMENT.md prepared
- [x] CONTRIBUTING.md ready
- [x] CHANGELOG.md updated

---

## Build Configuration

### Debug Build
```bash
swift build --configuration debug
```

### Release Build
```bash
swift build --configuration release -Xswiftc -O
```

### Optimization Flags
- `-O`: Optimize for speed
- `-whole-module-optimization`: Enable whole module optimization
- `-enable-testing`: Disabled in release builds

---

## Code Signing

### Developer ID Application Certificate

1. **Obtain Certificate**
   ```bash
   # List available certificates
   security find-identity -p codesigning -v
   ```

2. **Sign Application**
   ```bash
   codesign --deep --force --verify --verbose \
     --sign "Developer ID Application: Your Name (TEAM_ID)" \
     --options runtime \
     /path/to/PresentationGenerator.app
   ```

3. **Verify Signature**
   ```bash
   codesign --verify --deep --strict --verbose=2 \
     /path/to/PresentationGenerator.app
   ```

### Entitlements

Create `PresentationGenerator.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
```

---

## Notarization

### 1. Create App Bundle

```bash
# Build for release
swift build --configuration release

# Create app bundle structure
mkdir -p PresentationGenerator.app/Contents/MacOS
mkdir -p PresentationGenerator.app/Contents/Resources

# Copy executable
cp .build/release/PresentationGenerator \
   PresentationGenerator.app/Contents/MacOS/

# Create Info.plist
# (See below)
```

### 2. Info.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>PresentationGenerator</string>
    <key>CFBundleIdentifier</key>
    <string>com.yourcompany.presentationgenerator</string>
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
</dict>
</plist>
```

### 3. Submit for Notarization

```bash
# Create ZIP archive
ditto -c -k --keepParent PresentationGenerator.app \
  PresentationGenerator.zip

# Submit to notary service
xcrun notarytool submit PresentationGenerator.zip \
  --apple-id "your-apple-id@example.com" \
  --team-id "TEAM_ID" \
  --password "app-specific-password" \
  --wait

# Staple notarization ticket
xcrun stapler staple PresentationGenerator.app
```

---

## Distribution Methods

### 1. Direct Download (DMG)

Create a DMG for distribution:

```bash
# Create DMG
hdiutil create -volname "Presentation Generator" \
  -srcfolder PresentationGenerator.app \
  -ov -format UDZO \
  PresentationGenerator.dmg
```

### 2. Mac App Store

1. Archive in Xcode
2. Validate archive
3. Upload to App Store Connect
4. Submit for review

### 3. Homebrew Cask

Create a cask formula:

```ruby
cask "presentation-generator" do
  version "1.0.0"
  sha256 "checksum"

  url "https://github.com/youruser/presentation-generator/releases/download/v#{version}/PresentationGenerator.dmg"
  name "Presentation Generator"
  desc "AI-powered presentation generator for educators"
  homepage "https://github.com/youruser/presentation-generator"

  app "PresentationGenerator.app"
end
```

---

## Release Process

### 1. Version Bump

Update version in:
- `Info.plist`
- `CHANGELOG.md`
- `README.md`

### 2. Create Git Tag

```bash
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

### 3. Build Release

```bash
./scripts/build.sh release
```

### 4. Run Tests

```bash
./scripts/build.sh test
```

### 5. Code Quality Check

```bash
./scripts/build.sh check
```

### 6. Create Archive

```bash
./scripts/build.sh archive
```

### 7. Sign and Notarize

Follow code signing and notarization steps above.

### 8. Create GitHub Release

1. Go to GitHub Releases
2. Create new release
3. Upload DMG and ZIP files
4. Add release notes from CHANGELOG.md

---

## Post-Release

### Monitoring

- Monitor crash reports
- Track user feedback
- Monitor API usage
- Check performance metrics

### Support Channels

- GitHub Issues
- Email support
- Documentation updates
- FAQ updates

---

## Rollback Plan

If critical issues are found:

1. **Remove Downloads**
   - Remove download links
   - Add notice on website

2. **Revert to Previous Version**
   - Tag previous stable version
   - Rebuild and redistribute

3. **Communicate**
   - Notify users
   - Explain issues
   - Provide timeline

---

## Future Versions

### Version 1.1 Roadmap
- Complete PowerPoint export
- DOC/DOCX parsing
- Performance optimizations
- Additional templates

### Version 1.2 Roadmap
- iCloud sync
- Collaboration features
- Advanced layouts
- Custom themes

---

**Last Updated**: November 22, 2025
**Prepared By**: Development Team
