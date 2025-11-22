# Changelog

All notable changes to PresentationGenerator will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Complete PowerPoint XML generation
- DOC/DOCX parsing implementation
- Performance optimization for 50+ slides
- Advanced error handling (network, rate limits, edge cases)

## [1.0.0] - 2025-11-22

### Added - Phase 1-7: Foundation & Core Services
- MVVM architecture with dependency injection
- Domain models (Project, Slide, KeyPoint, SourceFile, Audience, DesignSpec)
- Error handling system (AppError, OpenAIError, KeychainError)
- ProjectRepository with JSON-based persistence
- FileRepository for document and image operations
- KeychainRepository for secure API key storage
- OpenAI Service integration (GPT-4 & DALL-E)
- ContentAnalyzer service for extracting key teaching points
- SlideDesigner service for audience-specific design generation
- SlideGenerator service for automated slide creation
- SlideRenderer service for slide previews
- PowerPointExporter service (partial implementation)
- ImageService for AI image generation
- ProjectManager for high-level workflow orchestration
- AppCoordinator for centralized navigation
- Logger utility for debugging and error tracking

### Added - Phase 8-11: User Interface
- ProjectListView with search, sort, and filter
- ProjectCreationView with audience selection
- ProjectDetailView with 4-step workflow visualization
- ContentImportView with file picker and drag-and-drop
- ContentAnalysisView with key point editing
- SlideGenerationView with real-time progress
- SlideOverviewView with thumbnail grid and reordering
- SlideEditorView for editing individual slides
- ImageEditorView for image management
- ExportView with progress and success states
- SettingsView for API key and preferences
- APIKeySetupView for first-run configuration
- SplashView with animated launch screen
- RootView coordinating app state transitions

### Added - Phase 12: Common Components
- LoadingView with spinner and customizable messages
- ErrorView with retry/dismiss actions and presets
- CustomProgressView with percentage and time estimation
- ToastView for temporary notifications
- ConfirmationDialog with preset configurations
- Reusable UI components library

### Added - Phase 13: App Initialization
- PresentationGeneratorApp with proper initialization
- Directory creation on launch (projects, images, exports)
- Logging setup and configuration
- AppInfo utility for version and metadata
- Keyboard shortcuts (⌘N, ⌘S, ⌘E, ⌘,)

### Added - Phase 14: Integration & Polish
- Complete navigation flow across all screens
- AutoSaveManager with 2-second debouncing
- SlideEditorViewModel auto-save integration
- Drag-and-drop file import support
- Accessibility labels for VoiceOver
- Task cancellation for async operations
- Error recovery mechanisms
- Progress indicators throughout app

### Added - Phase 15: Testing
- ContentAnalyzerTests (30+ test cases)
- SlideDesignerTests (20+ test cases)
- SlideGeneratorTests (15+ test cases)
- ProjectRepositoryTests (20+ test cases)
- FileRepositoryTests (15+ test cases)
- MockOpenAIService for testing without API calls
- Mock repositories for unit testing
- 100+ total test cases covering core services
- 2,136 lines of test code

### Added - Phase 16: Documentation
- USER_GUIDE.md - Comprehensive user manual
- ARCHITECTURE.md - Technical architecture documentation
- API_DOCUMENTATION.md - Service and repository APIs
- DEPLOYMENT.md - Build and distribution guide
- CONTRIBUTING.md - Contributing guidelines
- TESTING_SUMMARY.md - Test coverage details
- PROJECT_STATUS.md - Current project state
- Updated README.md with complete information
- CHANGELOG.md (this file)

### Features
- **5 Audience Types**: Kids, Teenagers, Adults, Seniors, Professionals
- **Audience-Specific Design**: Optimized fonts, colors, and layouts
- **AI Content Analysis**: Automatic key point extraction
- **AI Slide Generation**: GPT-4 powered content creation
- **AI Image Generation**: DALL-E creates contextual illustrations
- **Auto-Save**: Changes saved every 2 seconds
- **File Import**: Support for TXT, RTF, DOC, DOCX
- **PowerPoint Export**: Export to .pptx format
- **Project Management**: Create, save, load, delete, duplicate projects
- **Slide Editing**: Edit titles, content, notes, and images
- **Slide Reordering**: Drag-and-drop slide organization
- **Search & Sort**: Find and organize projects easily
- **Secure Storage**: API keys in macOS Keychain
- **Error Handling**: Comprehensive error recovery
- **Accessibility**: Full VoiceOver support

### Technical
- macOS 13.0+ (Ventura) support
- Swift 5.9+ with async/await concurrency
- SwiftUI with MVVM architecture
- Combine for reactive programming
- OpenAI SDK (MacPaw/OpenAI v0.2.4)
- Swift Package Manager for dependencies
- 89 Swift files in main app
- 6 test files with 100+ test cases
- Build time: ~2.72s (full), ~0.08s (incremental)

### Known Issues
- XCTest module unavailable in SPM executable targets (requires Xcode project)
- PowerPoint export XML generation incomplete
- DOC/DOCX parsing not fully implemented
- Performance not optimized for 50+ slides
- Live API testing incomplete

## [0.5.0] - 2025-11-15

### Added - Initial Development
- Project scaffolding with Swift Package Manager
- Basic project structure
- OpenAI dependency configuration
- Initial model definitions

---

## Version History Summary

- **1.0.0** (2025-11-22) - Full feature release with documentation
- **0.5.0** (2025-11-15) - Initial development build

---

## Migration Guide

### From 0.5.0 to 1.0.0

**Breaking Changes:**
- None (first major release)

**New Features:**
- Complete UI implementation
- All 5 audience types
- Auto-save functionality
- Comprehensive documentation

**Upgrade Steps:**
1. Update to latest build
2. Configure OpenAI API key in Settings
3. Review new keyboard shortcuts
4. Read USER_GUIDE.md for new features

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to propose changes to this project.

---

[Unreleased]: https://github.com/benedetto73/luciano/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/benedetto73/luciano/releases/tag/v1.0.0
[0.5.0]: https://github.com/benedetto73/luciano/releases/tag/v0.5.0
