MacOS Presentation Generator - Development Task List
Phase 1: Project Setup & Foundation (Tasks 1-10)

Create new macOS SwiftUI project

Set up Xcode project with name "PresentationGenerator"
Configure minimum deployment target (macOS 13.0+)
Set up proper bundle identifier and app icons
Configure project settings and capabilities


Create directory structure

Set up all folders as per architecture document
Create placeholder files for main components
Add README.md with project description


Set up dependency management

Create Package.swift or configure SPM
Add OpenAI SDK dependency (or REST API client)
Add any necessary file parsing libraries for .doc/.docx


Create core domain models

Implement Project.swift with all properties
Implement Slide.swift with all properties
Implement KeyPoint.swift with all properties
Implement Audience.swift enum with design preferences
Implement DesignSpec.swift with layout specifications


Create supporting models

Implement SourceFile.swift
Implement ImageData.swift
Implement ProjectSettings.swift
Implement layout enums (LayoutType, ImagePosition, etc.)


Create error types

Implement AppError.swift with all error cases
Implement KeychainError.swift
Implement OpenAIError.swift
Add localized error descriptions


Create constants files

Implement AppConstants.swift (file paths, defaults)
Implement APIConstants.swift (endpoints, model names)
Implement DesignConstants.swift (colors, fonts, sizes)


Create utility extensions

Implement String+Extensions.swift (trimming, validation)
Implement Date+Extensions.swift (formatting)
Implement View+Extensions.swift (common modifiers)
Implement Color+Extensions.swift (custom colors)


Create helper utilities

Implement Logger.swift for consistent logging
Implement NetworkMonitor.swift for connectivity checking
Implement ErrorHandler.swift for centralized error handling


Set up OpenAI prompt templates

Create ContentAnalysisPrompts.swift with system/user prompts
Create SlideGenerationPrompts.swift with generation prompts
Create ContentFilterPrompts.swift with filtering rules



Phase 2: Data Layer (Tasks 11-20)

Implement Keychain Repository

Create KeychainRepositoryProtocol.swift
Implement KeychainRepository.swift with save/retrieve/delete
Add proper error handling for Keychain operations
Add unit tests for KeychainRepository


Implement Project Storage Manager

Create ProjectStorageManager.swift
Implement JSON encoding/decoding for projects
Handle file system operations (create directories)
Add error handling for file operations


Implement Project Repository

Create ProjectRepositoryProtocol.swift
Implement ProjectRepository.swift with CRUD operations
Implement project file naming and organization
Add unit tests for ProjectRepository


Implement File Repository

Create FileRepositoryProtocol.swift
Implement FileRepository.swift for file operations
Add methods for image storage/retrieval
Add unit tests for FileRepository


Implement Document Parser

Create DocumentParser.swift
Add support for .docx parsing (using library)
Add support for .doc parsing (using library)
Add text extraction and cleaning logic
Handle parsing errors gracefully


Implement Image Service

Create ImageService.swift
Add image caching with LRU strategy
Add image compression/optimization
Add methods to save/load images by UUID
Implement cache size limits


Create mock repositories for testing

Implement MockProjectRepository.swift
Implement MockKeychainRepository.swift
Implement MockFileRepository.swift



Phase 3: OpenAI Integration (Tasks 18-27)

Create OpenAI DTO models

Implement OpenAIRequest.swift (chat completion request)
Implement OpenAIResponse.swift (chat completion response)
Implement DALLERequest.swift
Implement DALLEResponse.swift
Make all models Codable


Implement GPT Service

Create GPTService.swift
Implement chat completion API call
Add request/response parsing
Implement retry logic for rate limits
Add timeout handling


Implement DALL-E Service

Create DALLEService.swift
Implement image generation API call
Add image download and conversion to Data
Implement retry logic
Add timeout handling


Implement OpenAI Service Protocol

Create OpenAIServiceProtocol.swift with all required methods
Document expected inputs/outputs


Implement OpenAI Service

Create OpenAIService.swift implementing the protocol
Integrate GPTService and DALLEService
Add API key validation method
Implement analyzeContent method
Implement generateSlideContent method
Implement generateImage method


Implement Content Filter

Create ContentFilterProtocol.swift
Implement ContentFilter.swift
Add rules for Catholic educational content
Add age-appropriateness checking
Add validation methods for AI responses


Create mock OpenAI service for testing

Implement MockOpenAIService.swift
Add predefined responses for testing
Allow configurable delays to simulate API calls



Phase 4: Business Logic Layer (Tasks 25-32)

Implement Content Analyzer

Create ContentAnalyzer.swift
Implement analyzeAndExtractKeyPoints method
Implement suggestSlideCount method
Integrate with OpenAIService and ContentFilter
Add comprehensive error handling


Implement Slide Designer

Create SlideDesigner.swift
Implement design generation based on audience
Create default design templates for kids/adults
Add methods to customize designs


Implement Slide Generator

Create SlideGeneratorProtocol.swift
Implement SlideGenerator.swift
Implement generateSlide method
Integrate OpenAIService, ImageService, and SlideDesigner
Add progress tracking


Implement Slide Renderer

Create SlideRenderer.swift
Add methods to render slides to images/views
Prepare slides for export format


Implement PowerPoint Exporter Protocol

Create PowerPointExporterProtocol.swift
Define export method signature


Implement PowerPoint Exporter

Create PowerPointExporter.swift
Research and integrate PowerPoint generation library
Implement export method (slides → .pptx)
Add image embedding in slides
Add text formatting
Handle export errors


Create export format converters

Implement conversion from Slide model to PowerPoint format
Handle font and color conversions
Ensure layout consistency



Phase 5: Dependency Injection (Tasks 32-34)

Implement Dependency Container

Create DependencyContainer.swift
Add lazy properties for all repositories
Add lazy properties for all services
Add factory methods for ViewModels


Implement Service Factory

Create ServiceFactory.swift (if needed for complex creation)
Add methods to create configured services


Implement Repository Factory

Create RepositoryFactory.swift (if needed)
Add methods to create configured repositories



Phase 6: Coordinator & Navigation (Tasks 35-37)

Create AppScreen enum

Define all possible screens in the app
Make it hashable for navigation


Implement App Coordinator

Create AppCoordinator.swift as ObservableObject
Implement navigation stack management
Add methods for all navigation actions
Implement checkAPIKeyAndSetInitialScreen logic


Create root navigation structure

Create RootView.swift
Implement NavigationStack with coordinator
Add screen switching logic based on AppScreen



Phase 7: UI - Setup & Project List (Tasks 38-45)

Create API Key Setup View

Create APIKeySetupView.swift
Add SecureField for API key input
Add validation button
Add loading indicator


Create API Key Setup ViewModel

Create APIKeySetupViewModel.swift
Implement API key validation logic
Implement key saving to Keychain
Add error state handling


Create Project Card View

Create ProjectCardView.swift
Display project name, date, audience, slide count
Add hover effects
Make clickable


Create Project List View

Create ProjectListView.swift
Display grid/list of projects
Add "New Project" button
Add search/filter functionality
Add empty state view


Create Project List ViewModel

Create ProjectListViewModel.swift
Implement loadProjects method
Implement createNewProject method
Implement openProject method
Implement deleteProject method
Add loading and error states


Create Project Creation View

Create ProjectCreationView.swift
Add project name TextField
Add audience selection (Kids/Adults)
Add "Create" button


Create Audience Selection Component

Create AudienceSelectionView.swift
Add visual cards for Kids/Adults selection
Add descriptions for each audience type


Create Project Creation ViewModel

Create ProjectCreationViewModel.swift
Implement project creation logic
Validate project name
Save new project to repository
Navigate to file import



Phase 8: UI - File Import (Tasks 46-50)

Create File Import View

Create FileImportView.swift
Add drag-and-drop area
Add file picker button
Display list of imported files
Add "Proceed to Analysis" button


Create File Preview View

Create FilePreviewView.swift
Display file name, size, date
Show text preview (first 200 characters)
Add remove button


Create File Import ViewModel

Create FileImportViewModel.swift
Implement file selection handling
Implement document parsing
Implement file removal
Update project with imported files
Add error handling for invalid files



Phase 9: UI - Content Analysis (Tasks 49-55)

Create Key Point List View

Create KeyPointsListView.swift
Display list of key points with drag handles
Add checkboxes to include/exclude points
Make reorderable


Create Key Point Edit View

Create KeyPointEditView.swift
Allow inline editing of key point text
Add character count
Add save/cancel buttons


Create Content Analysis View

Create ContentAnalysisView.swift
Display analysis progress
Show KeyPointsListView
Add Stepper for slide count
Add "Regenerate Analysis" button
Add "Proceed to Generation" button


Create Content Analysis ViewModel

Create ContentAnalysisViewModel.swift
Implement analyzeContent method
Implement addKeyPoint method
Implement removeKeyPoint method
Implement updateSlideCount method
Implement proceedToSlideGeneration method
Add loading and error states



Phase 10: UI - Slide Generation (Tasks 53-60)

Create Slide Preview View

Create SlidePreviewView.swift
Display slide with image and text
Show design styling
Make it look like actual slide


Create Image Editor View

Create ImageEditorView.swift
Display current image
Add "Regenerate Image" button
Add "Upload Custom Image" button
Show loading state during generation


Create Slide Editor View

Create SlideEditorView.swift
Add TextEditor for title
Add TextEditor for content
Add ImageEditorView
Add design customization options
Add "Save" button


Create Slide Generation View

Create SlideGenerationView.swift
Show overall progress bar
Display current slide being generated
Show SlidePreviewView
Add Previous/Next navigation buttons
Add slide counter (X of Y)
Add "Edit This Slide" button
Add "Proceed to Overview" button


Create Slide Generation ViewModel

Create SlideGenerationViewModel.swift
Implement generateAllSlides method
Implement nextSlide/previousSlide methods
Implement regenerateCurrentSlideImage method
Implement updateSlideContent method
Add progress tracking
Add loading and error states



Phase 11: UI - Slide Overview & Export (Tasks 58-63)

Create Slide Thumbnail View

Create SlideThumbnailView.swift
Display miniature version of slide
Show slide number
Make clickable and draggable


Create Slide Overview View

Create SlideOverviewView.swift
Display grid of slide thumbnails
Add drag-and-drop reordering
Add "Add Slide" button
Add "Delete Slide" button
Add "Edit Slide" button
Add "Export to PowerPoint" button


Create Slide Overview ViewModel

Create SlideOverviewViewModel.swift
Implement slide reordering logic
Implement addSlide method
Implement deleteSlide method
Implement editSlide navigation
Implement exportToPowerPoint method
Add export progress tracking
Add loading and error states


Create Export Progress View

Create ExportProgressView.swift
Show progress bar
Display current step (rendering, saving, etc.)
Show success/error message



Phase 12: UI - Common Components (Tasks 62-67)

Create Loading View Component

Create LoadingView.swift
Add spinner with message
Make reusable with customizable text


Create Error View Component

Create ErrorView.swift
Display error message
Add retry button
Add dismiss button


Create Progress View Component

Create ProgressView.swift
Show progress bar with percentage
Add cancellation option
Display estimated time remaining


Create Toast View Component

Create ToastView.swift
Show temporary success/error messages
Auto-dismiss after delay
Position at top or bottom of screen


Create Confirmation Dialog Component

Create reusable confirmation dialogs
Use for destructive actions (delete project, etc.)


Create Settings View

Create SettingsView.swift
Display current API key (masked)
Add "Change API Key" button
Add app version info
Add "Clear Cache" button



Phase 13: App Initialization (Tasks 68-72)

Create App Delegate

Create AppDelegate.swift if needed
Handle app lifecycle events
Set up logging


Create Main App File

Create PresentationGeneratorApp.swift
Initialize DependencyContainer
Initialize AppCoordinator
Set up RootView with coordinator


Implement app launch logic

Check for API key on launch
Create projects directory if not exists
Initialize image cache


Add app icon and assets

Design and add app icon
Add placeholder images if needed
Add color assets for themes



Phase 14: Integration & Polish (Tasks 72-80)

Wire up navigation between all screens

Ensure all coordinator methods are called correctly
Test navigation flow from start to finish


Implement auto-save functionality

Add auto-save timer in ViewModels
Save project after every significant change


Add keyboard shortcuts

Command+N for new project
Command+S for save/export
Command+W for close
Escape for cancel/back


Implement drag-and-drop for file import

Add drop delegate to FileImportView
Handle dropped files


Add undo/redo support (optional)

Implement for text editing
Implement for slide reordering


Optimize performance

Add image lazy loading
Implement proper cancellation for API calls
Add debouncing for search/filter


Add accessibility labels

Add VoiceOver support
Ensure all interactive elements are accessible


Implement error recovery

Add retry mechanisms for failed API calls
Save partial progress on crashes


Add user preferences

Create preferences storage
Allow customization of default settings



Phase 15: Testing & Documentation (Tasks 81-90)

Write unit tests for models

Test Project, Slide, KeyPoint encoding/decoding
Test model validation logic


Write unit tests for repositories

Test ProjectRepository with mock file system
Test KeychainRepository
Test FileRepository


Write unit tests for services

Test ContentAnalyzer with mock OpenAI service
Test SlideGenerator with mock services
Test ContentFilter logic


Write unit tests for ViewModels

Test all ViewModel methods
Test state transitions
Test error handling


Write integration tests

Test complete flow from project creation to export
Test file import and parsing
Test OpenAI integration (with real API or good mocks)


Write UI tests

Test critical user paths
Test navigation flows
Test error states


Manual testing checklist

Test with various document formats
Test with different audience types
Test error scenarios (no internet, invalid API key)
Test with large projects (many slides)


Create inline code documentation

Add doc comments to all public APIs
Document complex algorithms
Add usage examples where appropriate


Create README documentation

Add setup instructions
Document architecture
Add troubleshooting section


Create user guide

Document how to use the app
Add screenshots
Create FAQ section



Phase 16: Final Polish (Tasks 91-95)

Design polish pass

Refine spacing, colors, fonts
Ensure consistent design language
Add animations and transitions


Performance profiling

Use Instruments to find bottlenecks
Optimize slow operations
Reduce memory usage


Code review and refactoring

Remove dead code
Improve naming consistency
Extract reusable components


Build release version

Configure release build settings
Add code signing
Create app bundle


Final testing and bug fixes

Fix any remaining bugs
Test on multiple macOS versions
Prepare for distribution



