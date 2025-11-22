MacOS Presentation Generator - Software Architecture
1. Architecture Overview
Architecture Pattern: MVVM + Coordinator + Repository

MVVM: Separation of UI, business logic, and data
Coordinator: Navigation and flow management
Repository: Data access abstraction
Dependency Injection: For testability and modularity

┌─────────────────────────────────────────────────────────────┐
│                         Presentation Layer                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  SwiftUI     │  │  SwiftUI     │  │  SwiftUI     │      │
│  │  Views       │  │  Views       │  │  Views       │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │              │
│  ┌──────▼──────────────────▼──────────────────▼───────┐    │
│  │              ViewModels (Observable)               │    │
│  └──────┬─────────────────────────────────────────────┘    │
└─────────┼──────────────────────────────────────────────────┘
          │
┌─────────▼──────────────────────────────────────────────────┐
│                      Coordinator Layer                      │
│  ┌───────────────────────────────────────────────────┐     │
│  │         AppCoordinator (Navigation Flow)          │     │
│  └───────────────────────────────────────────────────┘     │
└─────────┬──────────────────────────────────────────────────┘
          │
┌─────────▼──────────────────────────────────────────────────┐
│                      Business Logic Layer                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Content    │  │    Slide     │  │   Export     │     │
│  │   Analyzer   │  │  Generator   │  │   Service    │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
└─────────┼──────────────────┼──────────────────┼────────────┘
          │                  │                  │
┌─────────▼──────────────────▼──────────────────▼────────────┐
│                       Service Layer                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   OpenAI     │  │    Image     │  │   Content    │     │
│  │   Service    │  │   Service    │  │   Filter     │     │
│  └──────┬───────┘  └──────┬───────┘  └──────────────┘     │
└─────────┼──────────────────┼─────────────────────────────┘
          │                  │
┌─────────▼──────────────────▼─────────────────────────────┐
│                      Repository Layer                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │   Project    │  │   Keychain   │  │    File      │   │
│  │  Repository  │  │  Repository  │  │  Repository  │   │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘   │
└─────────┼──────────────────┼──────────────────┼──────────┘
          │                  │                  │
┌─────────▼──────────────────▼──────────────────▼──────────┐
│                      Data Layer                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │    Local     │  │   Keychain   │  │  FileSystem  │   │
│  │   Storage    │  │              │  │              │   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
└───────────────────────────────────────────────────────────┘
2. Directory Structure
PresentationGenerator/
├── App/
│   ├── PresentationGeneratorApp.swift
│   ├── AppDelegate.swift
│   └── AppCoordinator.swift
│
├── Models/
│   ├── Domain/
│   │   ├── Project.swift
│   │   ├── Slide.swift
│   │   ├── KeyPoint.swift
│   │   ├── Audience.swift
│   │   └── DesignSpec.swift
│   └── DTOs/
│       ├── OpenAIRequest.swift
│       ├── OpenAIResponse.swift
│       └── DALLEResponse.swift
│
├── Views/
│   ├── Root/
│   │   └── RootView.swift
│   ├── Setup/
│   │   ├── APIKeySetupView.swift
│   │   └── APIKeySetupViewModel.swift
│   ├── ProjectList/
│   │   ├── ProjectListView.swift
│   │   ├── ProjectListViewModel.swift
│   │   └── ProjectCardView.swift
│   ├── ProjectCreation/
│   │   ├── ProjectCreationView.swift
│   │   ├── ProjectCreationViewModel.swift
│   │   └── AudienceSelectionView.swift
│   ├── Import/
│   │   ├── FileImportView.swift
│   │   ├── FileImportViewModel.swift
│   │   └── FilePreviewView.swift
│   ├── Analysis/
│   │   ├── ContentAnalysisView.swift
│   │   ├── ContentAnalysisViewModel.swift
│   │   ├── KeyPointsListView.swift
│   │   └── KeyPointEditView.swift
│   ├── SlideGeneration/
│   │   ├── SlideGenerationView.swift
│   │   ├── SlideGenerationViewModel.swift
│   │   ├── SlideEditorView.swift
│   │   ├── SlidePreviewView.swift
│   │   └── ImageEditorView.swift
│   ├── SlideOverview/
│   │   ├── SlideOverviewView.swift
│   │   ├── SlideOverviewViewModel.swift
│   │   └── SlideThumbnailView.swift
│   └── Components/
│       ├── LoadingView.swift
│       ├── ErrorView.swift
│       ├── ProgressView.swift
│       └── ToastView.swift
│
├── ViewModels/
│   └── (ViewModels are colocated with Views)
│
├── Services/
│   ├── OpenAI/
│   │   ├── OpenAIService.swift
│   │   ├── OpenAIServiceProtocol.swift
│   │   ├── GPTService.swift
│   │   ├── DALLEService.swift
│   │   └── OpenAIError.swift
│   ├── Content/
│   │   ├── ContentAnalyzer.swift
│   │   ├── ContentFilter.swift
│   │   └── ContentFilterProtocol.swift
│   ├── Slide/
│   │   ├── SlideGenerator.swift
│   │   ├── SlideDesigner.swift
│   │   └── SlideGeneratorProtocol.swift
│   ├── Export/
│   │   ├── PowerPointExporter.swift
│   │   ├── PowerPointExporterProtocol.swift
│   │   └── SlideRenderer.swift
│   └── Image/
│       ├── ImageService.swift
│       ├── ImageCache.swift
│       └── ImageProcessor.swift
│
├── Repositories/
│   ├── Project/
│   │   ├── ProjectRepository.swift
│   │   ├── ProjectRepositoryProtocol.swift
│   │   └── ProjectStorageManager.swift
│   ├── Keychain/
│   │   ├── KeychainRepository.swift
│   │   └── KeychainRepositoryProtocol.swift
│   └── File/
│       ├── FileRepository.swift
│       ├── FileRepositoryProtocol.swift
│       └── DocumentParser.swift
│
├── Utilities/
│   ├── Extensions/
│   │   ├── String+Extensions.swift
│   │   ├── Date+Extensions.swift
│   │   ├── View+Extensions.swift
│   │   └── Color+Extensions.swift
│   ├── Helpers/
│   │   ├── Logger.swift
│   │   ├── NetworkMonitor.swift
│   │   └── ErrorHandler.swift
│   └── Constants/
│       ├── AppConstants.swift
│       ├── APIConstants.swift
│       └── DesignConstants.swift
│
├── DependencyInjection/
│   ├── DependencyContainer.swift
│   ├── ServiceFactory.swift
│   └── RepositoryFactory.swift
│
└── Resources/
    ├── Assets.xcassets/
    ├── Prompts/
    │   ├── ContentAnalysisPrompts.swift
    │   ├── SlideGenerationPrompts.swift
    │   └── ContentFilterPrompts.swift
    └── Localizable.strings
3. Core Components Detail
3.1 Models
swift// Domain/Project.swift

'''
struct Project: Codable, Identifiable {
    let id: UUID
    var name: String
    var audience: Audience
    var createdDate: Date
    var modifiedDate: Date
    var sourceFiles: [SourceFile]
    var keyPoints: [KeyPoint]
    var slides: [Slide]
    var settings: ProjectSettings
}

// Domain/Slide.swift
struct Slide: Codable, Identifiable {
    let id: UUID
    var slideNumber: Int
    var title: String
    var content: String
    var imageData: ImageData?
    var designSpec: DesignSpec
    var notes: String?
}

// Domain/Audience.swift
enum Audience: String, Codable, CaseIterable {
    case kids = "Kids"
    case adults = "Adults"
    
    var designPreferences: DesignPreferences {
        // Returns appropriate design preferences
    }
}

// Domain/DesignSpec.swift
struct DesignSpec: Codable {
    var layout: LayoutType
    var backgroundColor: String
    var textColor: String
    var fontSize: FontSize
    var fontFamily: String
    var imagePosition: ImagePosition
    var bulletStyle: BulletStyle?
}

// Domain/KeyPoint.swift
struct KeyPoint: Codable, Identifiable {
    let id: UUID
    var content: String
    var order: Int
    var isIncluded: Bool
}
'''

3.2 Services Layer
swift// Services/OpenAI/OpenAIServiceProtocol.swift

'''
protocol OpenAIServiceProtocol {
    func analyzeContent(
        text: String, 
        audience: Audience
    ) async throws -> ContentAnalysisResult
    
    func generateSlideContent(
        keyPoint: KeyPoint,
        audience: Audience,
        slideNumber: Int,
        totalSlides: Int
    ) async throws -> SlideContent
    
    func generateImage(
        prompt: String,
        style: ImageStyle
    ) async throws -> Data
    
    func validateAPIKey(_ key: String) async throws -> Bool
}

// Services/OpenAI/OpenAIService.swift
class OpenAIService: OpenAIServiceProtocol {
    private let apiKey: String
    private let gptService: GPTService
    private let dalleService: DALLEService
    private let contentFilter: ContentFilterProtocol
    
    init(
        apiKey: String,
        gptService: GPTService,
        dalleService: DALLEService,
        contentFilter: ContentFilterProtocol
    ) {
        self.apiKey = apiKey
        self.gptService = gptService
        self.dalleService = dalleService
        self.contentFilter = contentFilter
    }
    
    // Implementation
}

// Services/Content/ContentAnalyzer.swift
class ContentAnalyzer {
    private let openAIService: OpenAIServiceProtocol
    private let contentFilter: ContentFilterProtocol
    
    func analyzeAndExtractKeyPoints(
        from text: String,
        audience: Audience
    ) async throws -> [KeyPoint] {
        // Implementation
    }
    
    func suggestSlideCount(
        for keyPoints: [KeyPoint],
        audience: Audience
    ) -> Int {
        // Implementation
    }
}

// Services/Slide/SlideGenerator.swift
class SlideGenerator {
    private let openAIService: OpenAIServiceProtocol
    private let imageService: ImageService
    private let slideDesigner: SlideDesigner
    
    func generateSlide(
        from keyPoint: KeyPoint,
        audience: Audience,
        slideNumber: Int,
        totalSlides: Int
    ) async throws -> Slide {
        // Implementation
    }
}

// Services/Export/PowerPointExporter.swift
protocol PowerPointExporterProtocol {
    func export(
        project: Project,
        to url: URL
    ) async throws
}

class PowerPointExporter: PowerPointExporterProtocol {
    private let slideRenderer: SlideRenderer
    
    func export(
        project: Project,
        to url: URL
    ) async throws {
        // Implementation using python-pptx bridge or native solution
    }
}
'''

3.3 Repository Layer
swift// Repositories/Project/ProjectRepositoryProtocol.swift

'''
protocol ProjectRepositoryProtocol {
    func save(_ project: Project) async throws
    func load(id: UUID) async throws -> Project
    func loadAll() async throws -> [Project]
    func delete(id: UUID) async throws
    func update(_ project: Project) async throws
}

// Repositories/Project/ProjectRepository.swift
class ProjectRepository: ProjectRepositoryProtocol {
    private let storageManager: ProjectStorageManager
    private let fileManager: FileManager
    
    private var projectsDirectory: URL {
        fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("PresentationProjects")
    }
    
    // Implementation
}

// Repositories/Keychain/KeychainRepository.swift
protocol KeychainRepositoryProtocol {
    func save(apiKey: String) throws
    func retrieve() throws -> String?
    func delete() throws
}

class KeychainRepository: KeychainRepositoryProtocol {
    private let service = "com.presentationgenerator.apikey"
    private let account = "openai-api-key"
    
    func save(apiKey: String) throws {
        let data = apiKey.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed
        }
    }
    
    // Other implementations
}

// Repositories/File/FileRepository.swift
protocol FileRepositoryProtocol {
    func importDocument(from url: URL) async throws -> String
    func saveImage(_ data: Data, for slideId: UUID) async throws -> URL
    func loadImage(for slideId: UUID) async throws -> Data
}

class FileRepository: FileRepositoryProtocol {
    private let documentParser: DocumentParser
    
    func importDocument(from url: URL) async throws -> String {
        return try await documentParser.parse(url)
    }
    
    // Implementation
}
'''

3.4 ViewModels
swift// Views/ProjectList/ProjectListViewModel.swift

'''
@MainActor
class ProjectListViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let projectRepository: ProjectRepositoryProtocol
    private let coordinator: AppCoordinator
    
    init(
        projectRepository: ProjectRepositoryProtocol,
        coordinator: AppCoordinator
    ) {
        self.projectRepository = projectRepository
        self.coordinator = coordinator
    }
    
    func loadProjects() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            projects = try await projectRepository.loadAll()
        } catch {
            self.error = error
        }
    }
    
    func createNewProject() {
        coordinator.showProjectCreation()
    }
    
    func openProject(_ project: Project) {
        coordinator.openProject(project)
    }
    
    func deleteProject(_ project: Project) async {
        do {
            try await projectRepository.delete(id: project.id)
            await loadProjects()
        } catch {
            self.error = error
        }
    }
}

// Views/Analysis/ContentAnalysisViewModel.swift
@MainActor
class ContentAnalysisViewModel: ObservableObject {
    @Published var keyPoints: [KeyPoint] = []
    @Published var suggestedSlideCount: Int = 0
    @Published var isAnalyzing = false
    @Published var error: Error?
    
    private let contentAnalyzer: ContentAnalyzer
    private let projectRepository: ProjectRepositoryProtocol
    private var project: Project
    
    init(
        project: Project,
        contentAnalyzer: ContentAnalyzer,
        projectRepository: ProjectRepositoryProtocol
    ) {
        self.project = project
        self.contentAnalyzer = contentAnalyzer
        self.projectRepository = projectRepository
    }
    
    func analyzeContent() async {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        do {
            let combinedText = project.sourceFiles
                .map { $0.content }
                .joined(separator: "\n\n")
            
            keyPoints = try await contentAnalyzer.analyzeAndExtractKeyPoints(
                from: combinedText,
                audience: project.audience
            )
            
            suggestedSlideCount = contentAnalyzer.suggestSlideCount(
                for: keyPoints,
                audience: project.audience
            )
            
            project.keyPoints = keyPoints
            try await projectRepository.update(project)
        } catch {
            self.error = error
        }
    }
    
    func addKeyPoint(_ content: String) {
        let newPoint = KeyPoint(
            id: UUID(),
            content: content,
            order: keyPoints.count,
            isIncluded: true
        )
        keyPoints.append(newPoint)
    }
    
    func removeKeyPoint(_ keyPoint: KeyPoint) {
        keyPoints.removeAll { $0.id == keyPoint.id }
    }
    
    func updateSlideCount(_ count: Int) {
        suggestedSlideCount = count
    }
    
    func proceedToSlideGeneration() async {
        project.keyPoints = keyPoints
        try? await projectRepository.update(project)
        // Coordinator handles navigation
    }
}

// Views/SlideGeneration/SlideGenerationViewModel.swift
@MainActor
class SlideGenerationViewModel: ObservableObject {
    @Published var slides: [Slide] = []
    @Published var currentSlideIndex = 0
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0
    @Published var error: Error?
    
    private let slideGenerator: SlideGenerator
    private let projectRepository: ProjectRepositoryProtocol
    private var project: Project
    
    var currentSlide: Slide? {
        slides.indices.contains(currentSlideIndex) 
            ? slides[currentSlideIndex] 
            : nil
    }
    
    func generateAllSlides() async {
        isGenerating = true
        defer { isGenerating = false }
        
        let totalSlides = project.keyPoints.filter(\.isIncluded).count
        
        for (index, keyPoint) in project.keyPoints.filter(\.isIncluded).enumerated() {
            do {
                let slide = try await slideGenerator.generateSlide(
                    from: keyPoint,
                    audience: project.audience,
                    slideNumber: index + 1,
                    totalSlides: totalSlides
                )
                slides.append(slide)
                generationProgress = Double(index + 1) / Double(totalSlides)
            } catch {
                self.error = error
                return
            }
        }
        
        project.slides = slides
        try? await projectRepository.update(project)
    }
    
    func regenerateCurrentSlideImage() async {
        // Implementation
    }
    
    func updateSlideContent(_ slide: Slide) async {
        if let index = slides.firstIndex(where: { $0.id == slide.id }) {
            slides[index] = slide
            project.slides = slides
            try? await projectRepository.update(project)
        }
    }
    
    func nextSlide() {
        if currentSlideIndex < slides.count - 1 {
            currentSlideIndex += 1
        }
    }
    
    func previousSlide() {
        if currentSlideIndex > 0 {
            currentSlideIndex -= 1
        }
    }
}
'''

3.5 Coordinator
swift// App/AppCoordinator.swift

'''
enum AppScreen {
    case apiKeySetup
    case projectList
    case projectCreation
    case fileImport(Project)
    case contentAnalysis(Project)
    case slideGeneration(Project)
    case slideOverview(Project)
}

@MainActor
class AppCoordinator: ObservableObject {
    @Published var currentScreen: AppScreen = .apiKeySetup
    @Published var navigationPath: [AppScreen] = []
    
    private let keychainRepository: KeychainRepositoryProtocol
    private let dependencyContainer: DependencyContainer
    
    init(
        keychainRepository: KeychainRepositoryProtocol,
        dependencyContainer: DependencyContainer
    ) {
        self.keychainRepository = keychainRepository
        self.dependencyContainer = dependencyContainer
        checkAPIKeyAndSetInitialScreen()
    }
    
    private func checkAPIKeyAndSetInitialScreen() {
        if (try? keychainRepository.retrieve()) != nil {
            currentScreen = .projectList
        } else {
            currentScreen = .apiKeySetup
        }
    }
    
    func showProjectList() {
        navigationPath.removeAll()
        currentScreen = .projectList
    }
    
    func showProjectCreation() {
        navigate(to: .projectCreation)
    }
    
    func openProject(_ project: Project) {
        if project.slides.isEmpty {
            if project.keyPoints.isEmpty {
                navigate(to: .fileImport(project))
            } else {
                navigate(to: .contentAnalysis(project))
            }
        } else {
            navigate(to: .slideOverview(project))
        }
    }
    
    func startContentAnalysis(for project: Project) {
        navigate(to: .contentAnalysis(project))
    }
    
    func startSlideGeneration(for project: Project) {
        navigate(to: .slideGeneration(project))
    }
    
    func showSlideOverview(for project: Project) {
        navigate(to: .slideOverview(project))
    }
    
    private func navigate(to screen: AppScreen) {
        navigationPath.append(screen)
        currentScreen = screen
    }
    
    func goBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
            currentScreen = navigationPath.last ?? .projectList
        }
    }
}
'''


3.6 Dependency Injection
swift// DependencyInjection/DependencyContainer.swift

'''
class DependencyContainer {
    // Repositories
    lazy var keychainRepository: KeychainRepositoryProtocol = {
        KeychainRepository()
    }()
    
    lazy var projectRepository: ProjectRepositoryProtocol = {
        ProjectRepository(
            storageManager: ProjectStorageManager(),
            fileManager: .default
        )
    }()
    
    lazy var fileRepository: FileRepositoryProtocol = {
        FileRepository(
            documentParser: DocumentParser()
        )
    }()
    
    // Services
    lazy var openAIService: OpenAIServiceProtocol = {
        guard let apiKey = try? keychainRepository.retrieve() else {
            fatalError("API Key not found")
        }
        
        return OpenAIService(
            apiKey: apiKey,
            gptService: GPTService(apiKey: apiKey),
            dalleService: DALLEService(apiKey: apiKey),
            contentFilter: ContentFilter()
        )
    }()
    
    lazy var contentAnalyzer: ContentAnalyzer = {
        ContentAnalyzer(
            openAIService: openAIService,
            contentFilter: ContentFilter()
        )
    }()
    
    lazy var slideGenerator: SlideGenerator = {
        SlideGenerator(
            openAIService: openAIService,
            imageService: ImageService(),
            slideDesigner: SlideDesigner()
        )
    }()
    
    lazy var powerPointExporter: PowerPointExporterProtocol = {
        PowerPointExporter(
            slideRenderer: SlideRenderer()
        )
    }()
    
    // Coordinator
    lazy var appCoordinator: AppCoordinator = {
        AppCoordinator(
            keychainRepository: keychainRepository,
            dependencyContainer: self
        )
    }()
    
    // ViewModels Factory Methods
    func makeProjectListViewModel() -> ProjectListViewModel {
        ProjectListViewModel(
            projectRepository: projectRepository,
            coordinator: appCoordinator
        )
    }
    
    func makeContentAnalysisViewModel(project: Project) -> ContentAnalysisViewModel {
        ContentAnalysisViewModel(
            project: project,
            contentAnalyzer: contentAnalyzer,
            projectRepository: projectRepository
        )
    }
    
    func makeSlideGenerationViewModel(project: Project) -> SlideGenerationViewModel {
        SlideGenerationViewModel(
            project: project,
            slideGenerator: slideGenerator,
            projectRepository: projectRepository,
            imageService: ImageService()
        )
    }
}
'''

## 4. Data Flow Examples

### Example 1: Project Creation Flow
```
User Action: Create New Project
    ↓
Coordinator.showProjectCreation()
    ↓
ProjectCreationView (User selects audience)
    ↓
ProjectCreationViewModel.createProject()
    ↓
ProjectRepository.save(newProject)
    ↓
Coordinator.startFileImport(project)
    ↓
FileImportView
```

### Example 2: Content Analysis Flow
```
User Action: Analyze Content
    ↓
ContentAnalysisViewModel.analyzeContent()
    ↓
ContentAnalyzer.analyzeAndExtractKeyPoints()
    ↓
OpenAIService.analyzeContent()
    ↓
GPTService (API Call with content filter)
    ↓
ContentFilter.validateResponse()
    ↓
Return KeyPoints to ViewModel
    ↓
Update UI with editable key points
```

### Example 3: Slide Generation Flow
```
User Action: Generate Slides
    ↓
SlideGenerationViewModel.generateAllSlides()
    ↓
For each KeyPoint:
    ↓
    SlideGenerator.generateSlide()
        ↓
        OpenAIService.generateSlideContent()
        ↓
        OpenAIService.generateImage()
        ↓
        ImageService.processAndCache()
        ↓
        Return complete Slide
    ↓
ProjectRepository.update(project)
    ↓
Update UI with slide preview
5. Key Design Decisions
5.1 Async/Await for Concurrency

All network operations use Swift's modern concurrency
ViewModels marked with @MainActor for UI updates
Proper error handling with typed errors

5.2 Protocol-Oriented Design

All services and repositories have protocols
Easy mocking for testing
Dependency inversion principle

5.3 Single Source of Truth

Project is the central model
Repository persists changes immediately
ViewModels observe and update project state

5.4 Image Management

Images stored locally with UUID-based filenames
ImageService handles caching and compression
Base64 encoding only for API transmission

5.5 Content Filtering

Dedicated ContentFilter service
Applied to all AI-generated content
Configurable rules for Catholic educational context

5.6 Error Handling Strategy
swiftenum AppError: LocalizedError {
    case apiKeyInvalid
    case networkError(Error)
    case openAIError(String)
    case fileImportError(Error)
    case exportError(Error)
    case contentFilterViolation(String)
    
    var errorDescription: String? {
        // User-friendly messages
    }
}
6. Testing Strategy
Unit Tests

All ViewModels (with mocked dependencies)
All Services (with mocked API responses)
All Repositories (with in-memory storage)
Content filtering logic

Integration Tests

OpenAI API integration
File import/export workflows
Project persistence

UI Tests

Critical user flows
Navigation between screens
Error state handling

7. Performance Considerations

Image Caching: LRU cache for generated images
Lazy Loading: Load project thumbnails on-demand
Background Processing: File parsing in background
Rate Limiting: Respect OpenAI API limits
Cancellation: Cancel in-flight requests when navigating away

8. Security Considerations

API key stored in Keychain (encrypted at rest)
No logging of sensitive data
Content filtering for appropriate output
Local-only storage (no cloud sync initially)


This architecture provides a solid foundation that is:

Testable: Protocol-based design with dependency injection
Maintainable: Clear separation of concerns
Scalable: Easy to add new features or modify existing ones
SwiftUI-native: Leverages modern Apple frameworks
