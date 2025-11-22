# Luciano - AI Presentation Generator

<div align="center">
  
**An intelligent macOS app for creating educational presentations with AI**

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS%2014.0+-lightgrey.svg)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

</div>

## 🎯 Overview

Luciano is a native macOS application that transforms text documents into professional presentations using OpenAI's GPT models. Named after an intelligent assistant, it helps educators and content creators generate audience-appropriate slides quickly and efficiently.

### Key Features

✨ **AI-Powered Content Analysis** - Automatically extract key teaching points from documents  
🎨 **Smart Slide Generation** - Create audience-optimized presentations with GPT-4  
👶 **Audience Targeting** - Tailored designs for Kids and Adults  
📄 **Multi-Format Support** - Import .doc, .docx, .txt, and .rtf files  
💾 **PowerPoint Export** - Export to standard .pptx format  
🔒 **Secure Storage** - API keys stored in macOS Keychain  

## 🚀 Quick Start

### Requirements
- macOS 14.0 or later
- Xcode 15.0+ (for building from source)
- OpenAI API key (optional - free models available)

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/luciano.git
cd luciano

# Build and run
swift build
swift run
```

### First Launch

1. **Choose Your Setup**
   - Enter OpenAI API key for GPT-4 models
   - Or use free GPT-3.5 models (no key required)

2. **Create Your First Presentation**
   - Click **+** to create a new project
   - Import your content files
   - Let AI analyze and generate slides
   - Export to PowerPoint

## 📖 Usage Guide

### Creating a Presentation

```
1. New Project → Enter name and select audience (Kids/Adults)
2. Import Content → Add .doc/.docx/.txt/.rtf files
3. Analyze Content → AI extracts key teaching points
4. Generate Slides → AI creates optimized slides
5. Export → Download .pptx to ~/Downloads
```

### Managing Projects

- 🔍 **Search** - Find projects by name
- 📊 **Sort** - By modified date, created date, or name
- 🗑️ **Delete** - Swipe left to remove projects
- ♻️ **Refresh** - Pull down to reload

### Settings

Access via the ⚙️ gear icon:
- Manage OpenAI API keys
- Toggle between free and premium models
- View app version and documentation links

## 🏗️ Architecture

### Tech Stack
- **UI**: SwiftUI + MVVM pattern
- **AI**: OpenAI GPT-3.5/GPT-4
- **Storage**: JSON-based local persistence
- **Security**: macOS Keychain integration
- **Export**: OpenXML PowerPoint generation

### Project Structure
```
PresentationGenerator/
├── App/                   # Entry point, AppCoordinator
├── ViewModels/            # 7 ViewModels for screens
├── Views/                 # SwiftUI views
│   ├── ProjectList/       # Main project list
│   ├── ProjectDetail/     # Workflow screen
│   ├── ContentImport/     # File picker
│   ├── SlideList/         # Slide viewer
│   └── Export/            # PowerPoint export
├── Services/              # Business logic
│   ├── OpenAI/           # GPT integration
│   └── BusinessLogic/    # Content analysis, slide generation
├── Repositories/          # Data access
└── Models/               # Domain models + DTOs
```

### Key Services

| Service | Purpose |
|---------|---------|
| **ProjectManager** | High-level orchestration |
| **ContentAnalyzer** | Extract key points from text |
| **SlideDesigner** | Create audience-appropriate designs |
| **SlideGenerator** | Generate slides with AI |
| **PowerPointExporter** | Export to .pptx format |
| **ImageService** | AI image generation (planned) |

## 🧪 Development

### Build Commands
```bash
# Clean build
swift package clean

# Debug build
swift build

# Release build
swift build -c release

# Run tests
swift test

# Open in Xcode
open Package.swift
```

### Running Tests
```bash
# Run all tests
swift test

# Run specific test
swift test --filter ProjectManagerTests
```

### Dependencies
```swift
.package(url: "https://github.com/MacPaw/OpenAI", from: "0.2.4")
```

## 📊 Project Status

**Version**: 1.0.0 (Beta)  
**Build**: November 22, 2025  
**Swift Files**: 64  
**Completion**: ~47% (45/95 planned tasks)

### ✅ Completed
- [x] Core architecture (MVVM + DI)
- [x] Data persistence layer
- [x] OpenAI integration
- [x] Business logic services
- [x] UI screens and navigation
- [x] PowerPoint export
- [x] Settings management

### 🚧 In Progress
- [ ] Content analysis view
- [ ] Advanced slide editor
- [ ] Unit test coverage
- [ ] Performance optimization

### 📋 Planned
- [ ] Additional audience types
- [ ] Custom themes
- [ ] Batch processing
- [ ] Cloud sync
- [ ] Collaboration features

## 🐛 Troubleshooting

### Common Issues

**API Key Errors**
```
Problem: "Invalid API key"
Solution: Verify key in Settings → Update API Key
Check: OpenAI account has available credits
```

**Build Failures**
```
Problem: "Cannot find module 'OpenAI'"
Solution: swift package resolve
```

**Slow Generation**
```
Problem: Large documents take too long
Solution: Split into smaller files or use free models
```

**Export Failures**
```
Problem: "Export failed"
Solution: Check ~/Downloads permissions
Verify: Slides were generated first
```

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow SwiftUI best practices
- Use async/await for concurrency
- Add unit tests for new features
- Update documentation

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [MacPaw/OpenAI](https://github.com/MacPaw/OpenAI) - Swift SDK for OpenAI
- OpenAI - GPT models powering the intelligence
- SwiftUI community for excellent resources

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/luciano/issues)
- **Documentation**: See [BUILD_SUMMARY.md](BUILD_SUMMARY.md)
- **OpenAI Docs**: [API Reference](https://platform.openai.com/docs)

## 🗺️ Roadmap

### Version 1.1 (Q1 2026)
- Enhanced slide editor
- More audience types
- Improved export options

### Version 1.2 (Q2 2026)
- Custom themes and templates
- Batch processing
- Performance improvements

### Version 2.0 (Q3 2026)
- Cloud sync
- Collaboration features
- Mobile companion app

---

<div align="center">

**Built with ❤️ for educators and content creators**

[Report Bug](https://github.com/yourusername/luciano/issues) · [Request Feature](https://github.com/yourusername/luciano/issues) · [Documentation](BUILD_SUMMARY.md)

</div>
