# PresentationGenerator - API Documentation

**Version:** 1.0.0  
**Last Updated:** November 22, 2025

---

## Table of Contents

1. [Services API](#services-api)
2. [Repositories API](#repositories-api)
3. [Models Reference](#models-reference)
4. [Protocols](#protocols)
5. [Error Handling](#error-handling)
6. [Usage Examples](#usage-examples)

---

## Services API

### ContentAnalyzer

**Purpose:** Analyzes source documents and extracts teaching points.

#### Methods

```swift
func analyze(
    sourceFile: SourceFile,
    preferredAudience: Audience? = nil
) async throws -> ContentAnalysisResult
```

Analyzes a source file and extracts key teaching points.

**Parameters:**
- `sourceFile`: The file to analyze
- `preferredAudience`: Optional audience preference

**Returns:** `ContentAnalysisResult` with key points and suggested slide count

**Throws:** `OpenAIError`, `AppError.insufficientContent`

**Example:**
```swift
let analyzer = ContentAnalyzer(openAIService: service, fileRepository: repo)
let result = try await analyzer.analyze(sourceFile: file, preferredAudience: .kids)
print("Found \(result.keyPoints.count) key points")
```

---

```swift
func analyzeText(
    _ text: String,
    preferredAudience: Audience? = nil
) async throws -> ContentAnalysisResult
```

Analyzes text content directly without a file.

**Parameters:**
- `text`: Content to analyze
- `preferredAudience`: Optional audience preference

**Returns:** `ContentAnalysisResult`

**Throws:** `OpenAIError`, `AppError.insufficientContent`

---

```swift
func statistics(for result: ContentAnalysisResult) -> AnalysisStatistics
```

Gets statistics for an analysis result.

**Parameters:**
- `result`: Analysis result to get statistics for

**Returns:** `AnalysisStatistics` with metrics

**Example:**
```swift
let stats = analyzer.statistics(for: result)
if stats.needsReview {
    print("Slide count seems unusual: \(stats.suggestedSlideCount)")
}
```

#### Published Properties

```swift
@Published var isAnalyzing: Bool
@Published var analysisProgress: Double
@Published var lastError: Error?
```

---

### SlideDesigner

**Purpose:** Generates design specifications for presentations.

#### Methods

```swift
func createDesignSpec(for audience: Audience) async throws -> DesignSpec
```

Creates a design specification for a presentation.

**Parameters:**
- `audience`: Target audience

**Returns:** Complete `DesignSpec`

**Example:**
```swift
let designer = SlideDesigner()
let spec = try await designer.createDesignSpec(for: .kids)
// Kids get large fonts, bright colors, simple layouts
```

---

```swift
func validate(_ spec: DesignSpec) -> DesignValidationResult
```

Validates a design specification.

**Parameters:**
- `spec`: Design spec to validate

**Returns:** `DesignValidationResult` with issues if any

**Example:**
```swift
let result = designer.validate(spec)
if !result.isValid {
    print("Issues: \(result.issues)")
}
```

#### Published Properties

```swift
@Published var isDesigning: Bool
@Published var lastError: Error?
```

---

### SlideGenerator

**Purpose:** Generates complete presentation slides.

#### Methods

```swift
func generateSlides(
    from analysis: ContentAnalysisResult,
    designSpec: DesignSpec,
    audience: Audience,
    progressCallback: ((Int, Int) -> Void)? = nil
) async throws -> [Slide]
```

Generates all slides for a project.

**Parameters:**
- `analysis`: Content analysis result
- `designSpec`: Design specification
- `audience`: Target audience
- `progressCallback`: Optional progress callback (current, total)

**Returns:** Array of generated `Slide` objects

**Throws:** `OpenAIError`, `AppError`

**Example:**
```swift
let generator = SlideGenerator(openAIService: service, imageService: imageService)
let slides = try await generator.generateSlides(
    from: analysis,
    designSpec: spec,
    audience: .adults,
    progressCallback: { current, total in
        print("Generating slide \(current) of \(total)")
    }
)
```

---

```swift
func generateSingleSlide(
    keyPoint: KeyPoint,
    slideNumber: Int,
    totalSlides: Int,
    designSpec: DesignSpec,
    audience: Audience
) async throws -> Slide
```

Generates a single slide.

**Parameters:**
- `keyPoint`: Key point for the slide
- `slideNumber`: Slide number
- `totalSlides`: Total slides in presentation
- `designSpec`: Design specification
- `audience`: Target audience

**Returns:** Generated `Slide`

**Throws:** `OpenAIError`, `AppError`

---

```swift
func regenerateSlide(
    _ slide: Slide,
    totalSlides: Int,
    audience: Audience
) async throws -> Slide
```

Regenerates an existing slide with new content.

**Parameters:**
- `slide`: Slide to regenerate
- `totalSlides`: Total slides
- `audience`: Target audience

**Returns:** New `Slide` with same number

---

```swift
func reorderSlides(_ slides: [Slide]) async throws -> [Slide]
```

Reorders slides and updates slide numbers.

**Parameters:**
- `slides`: Slides in new order

**Returns:** Slides with updated numbers

#### Published Properties

```swift
@Published var isGenerating: Bool
@Published var generationProgress: (current: Int, total: Int)
@Published var lastError: Error?
```

---

### ProjectManager

**Purpose:** High-level orchestration of project workflows.

#### Methods

```swift
func createProject(name: String, audience: Audience) async throws -> Project
```

Creates a new project.

**Parameters:**
- `name`: Project name
- `audience`: Target audience

**Returns:** New `Project`

---

```swift
func loadProject(id: UUID) async throws -> Project
```

Loads an existing project.

**Parameters:**
- `id`: Project ID

**Returns:** Loaded `Project`

---

```swift
func saveProject(_ project: Project) async throws
```

Saves project changes.

**Parameters:**
- `project`: Project to save

---

```swift
func deleteProject(id: UUID) async throws
```

Deletes a project and associated files.

**Parameters:**
- `id`: Project ID to delete

---

```swift
func analyzeContent(
    for project: Project,
    sourceFiles: [SourceFile]
) async throws -> Project
```

Analyzes content and updates project with key points.

**Parameters:**
- `project`: Project to update
- `sourceFiles`: Source files to analyze

**Returns:** Updated `Project` with analysis results

---

```swift
func generateSlides(for project: Project) async throws -> Project
```

Generates slides from key points.

**Parameters:**
- `project`: Project with key points

**Returns:** Updated `Project` with generated slides

---

```swift
func exportPresentation(
    project: Project,
    to url: URL
) async throws
```

Exports project to PowerPoint format.

**Parameters:**
- `project`: Project to export
- `url`: Export destination URL

#### Published Properties

```swift
@Published var currentProject: Project?
@Published var isProcessing: Bool
@Published var lastError: Error?
```

---

## Repositories API

### ProjectRepository

**Purpose:** Manages project persistence.

#### Methods

```swift
func save(_ project: Project) async throws
```

Saves a project (updates modifiedDate automatically).

---

```swift
func load(id: UUID) async throws -> Project
```

Loads a project by ID.

**Throws:** `AppError.fileOperationFailed` if not found

---

```swift
func loadAll() async throws -> [Project]
```

Loads all projects.

**Returns:** Array of all projects

---

```swift
func delete(id: UUID) async throws
```

Deletes a project and associated images.

---

```swift
func create(name: String, audience: Audience) async throws -> Project
```

Creates and saves a new project.

---

```swift
func exists(id: UUID) -> Bool
```

Checks if a project exists.

---

```swift
func duplicate(projectID: UUID, newName: String? = nil) async throws -> Project
```

Duplicates a project with all data and images.

**Parameters:**
- `projectID`: Project to duplicate
- `newName`: Optional new name (defaults to "Original (Copy)")

---

### FileRepository

**Purpose:** Manages file operations.

#### Methods

```swift
func importDocument(from url: URL) async throws -> String
```

Imports a document and extracts text.

**Supported Formats:** TXT, RTF, DOC, DOCX

**Returns:** Extracted text content

**Throws:** `AppError.fileOperationFailed`, `AppError.insufficientContent`

---

```swift
func saveImage(_ data: Data, for slideId: UUID) async throws -> URL
```

Saves image data for a slide.

**Returns:** URL where image was saved

---

```swift
func loadImage(for slideId: UUID) async throws -> Data
```

Loads image data for a slide.

**Throws:** `AppError.imageProcessingError` if not found

---

```swift
func deleteImage(for slideId: UUID) async throws
```

Deletes image for a slide (no error if doesn't exist).

---

```swift
func saveCustomImage(_ image: NSImage, for slideId: UUID) async throws -> URL
```

Converts NSImage to PNG and saves.

---

### KeychainRepository

**Purpose:** Manages secure credential storage.

#### Methods

```swift
func saveAPIKey(_ apiKey: String) throws
```

Saves OpenAI API key to Keychain.

---

```swift
func getAPIKey() throws -> String?
```

Retrieves API key from Keychain.

**Returns:** API key or nil if not set

---

```swift
func deleteAPIKey() throws
```

Deletes API key from Keychain.

---

```swift
func hasAPIKey() -> Bool
```

Checks if API key exists.

---

## Models Reference

### Project

```swift
struct Project: Identifiable, Codable {
    let id: UUID
    var name: String
    var audience: Audience
    let createdDate: Date
    var modifiedDate: Date
    var sourceFiles: [SourceFile]
    var keyPoints: [KeyPoint]
    var slides: [Slide]
    var settings: ProjectSettings?
}
```

**Properties:**
- `id`: Unique identifier
- `name`: Project name
- `audience`: Target audience type
- `createdDate`: Creation timestamp
- `modifiedDate`: Last modification timestamp
- `sourceFiles`: Imported source documents
- `keyPoints`: Extracted teaching points
- `slides`: Generated presentation slides
- `settings`: Optional project settings

---

### Slide

```swift
struct Slide: Identifiable, Codable {
    let id: UUID
    var slideNumber: Int
    var title: String
    var content: String
    var imageData: ImageData?
    var designSpec: DesignSpec
    var notes: String?
}
```

**Properties:**
- `id`: Unique identifier
- `slideNumber`: Position in presentation (1-based)
- `title`: Slide heading
- `content`: Main text content
- `imageData`: Associated image
- `designSpec`: Design specification
- `notes`: Speaker notes

---

### KeyPoint

```swift
struct KeyPoint: Identifiable, Codable {
    let id: UUID
    var content: String
    var order: Int
}
```

**Properties:**
- `id`: Unique identifier
- `content`: Teaching point text
- `order`: Display order

---

### Audience

```swift
enum Audience: String, Codable, CaseIterable {
    case kids = "Kids (6-12)"
    case teenagers = "Teenagers (13-17)"
    case adults = "Adults (18-64)"
    case seniors = "Seniors (65+)"
    case professionals = "Professionals"
}
```

**Design Preferences by Audience:**

| Audience | Font Size | Layout | Colors |
|----------|-----------|--------|--------|
| Kids | Large | Simple | Bright |
| Teenagers | Medium | Moderate | Engaging |
| Adults | Medium | Moderate | Professional |
| Seniors | Extra Large | Simple | High Contrast |
| Professionals | Small | Detailed | Minimal |

---

### DesignSpec

```swift
struct DesignSpec: Codable {
    var layout: LayoutType
    var backgroundColor: String  // Hex color
    var textColor: String        // Hex color
    var fontSize: FontSizeSpec
    var fontFamily: String
    var imagePosition: ImagePosition
    var bulletStyle: BulletStyle
}
```

---

### ContentAnalysisResult

```swift
struct ContentAnalysisResult {
    let keyPoints: [KeyPoint]
    let suggestedSlideCount: Int
}
```

---

## Protocols

### OpenAIServiceProtocol

```swift
protocol OpenAIServiceProtocol: AnyObject {
    var isProcessing: Bool { get }
    var lastError: Error? { get }
    
    func analyzeContent(
        _ content: String,
        preferredAudience: Audience?
    ) async throws -> ContentAnalysisResult
    
    func generateSlides(
        for analysis: ContentAnalysisResult,
        progressCallback: ((Int, Int) -> Void)?
    ) async throws -> [SlideContentResult]
    
    func generateImage(
        prompt: String,
        audience: Audience
    ) async throws -> Data
}
```

---

### ProjectRepositoryProtocol

```swift
protocol ProjectRepositoryProtocol {
    func save(_ project: Project) async throws
    func load(id: UUID) async throws -> Project
    func loadAll() async throws -> [Project]
    func delete(id: UUID) async throws
    func update(_ project: Project) async throws
}
```

---

### FileRepositoryProtocol

```swift
protocol FileRepositoryProtocol {
    func importDocument(from url: URL) async throws -> String
    func saveImage(_ data: Data, for slideId: UUID) async throws -> URL
    func loadImage(for slideId: UUID) async throws -> Data
}
```

---

## Error Handling

### AppError

```swift
enum AppError: Error, Equatable {
    case invalidAPIKey
    case insufficientContent
    case fileOperationFailed(String)
    case imageProcessingError(String)
    case exportFailed(String)
    case networkError(String)
    case unknownError(String)
}
```

**Usage:**
```swift
do {
    let project = try await projectManager.createProject(name: "Test", audience: .kids)
} catch AppError.invalidAPIKey {
    // Show API key setup
} catch AppError.networkError(let message) {
    // Show network error with message
} catch {
    // Handle other errors
}
```

---

### OpenAIError

```swift
enum OpenAIError: Error {
    case invalidAPIKey
    case apiError(String)
    case rateLimitExceeded
    case networkError
    case invalidResponse
    case contentFilterTriggered
}
```

---

### KeychainError

```swift
enum KeychainError: Error {
    case itemNotFound
    case duplicateItem
    case unexpectedStatus(OSStatus)
}
```

---

## Usage Examples

### Complete Workflow

```swift
// 1. Setup
let container = DependencyContainer.shared
let projectManager = container.projectManager

// 2. Create Project
let project = try await projectManager.createProject(
    name: "The Beatitudes",
    audience: .kids
)

// 3. Import Content
let fileRepo = container.fileRepository
let text = try await fileRepo.importDocument(from: documentURL)
let sourceFile = SourceFile(
    id: UUID(),
    filename: "beatitudes.txt",
    fileType: .txt,
    content: text,
    importedDate: Date()
)

// 4. Analyze Content
var updatedProject = try await projectManager.analyzeContent(
    for: project,
    sourceFiles: [sourceFile]
)

// 5. Generate Slides
updatedProject = try await projectManager.generateSlides(
    for: updatedProject
)

// 6. Export
try await projectManager.exportPresentation(
    project: updatedProject,
    to: exportURL
)
```

---

### Custom Service Usage

```swift
// Direct service access
let analyzer = ContentAnalyzer(
    openAIService: openAIService,
    fileRepository: fileRepo
)

// Monitor progress
analyzer.$analysisProgress
    .sink { progress in
        print("Progress: \(Int(progress * 100))%")
    }
    .store(in: &cancellables)

// Perform analysis
let result = try await analyzer.analyze(
    sourceFile: file,
    preferredAudience: .adults
)

// Get statistics
let stats = analyzer.statistics(for: result)
print("Key points: \(stats.keyPointCount)")
print("Avg length: \(stats.averagePointLength)")
```

---

### Error Handling Pattern

```swift
@MainActor
class MyViewModel: ObservableObject {
    @Published var error: AppError?
    @Published var isLoading = false
    
    func performAction() async {
        isLoading = true
        error = nil
        
        do {
            try await service.doSomething()
        } catch let appError as AppError {
            self.error = appError
        } catch {
            self.error = .unknownError(error.localizedDescription)
        }
        
        isLoading = false
    }
}

// In View
if let error = viewModel.error {
    ErrorView(error: error) {
        Task {
            await viewModel.performAction()
        }
    }
}
```

---

**For more information:**
- User Guide: `USER_GUIDE.md`
- Architecture: `ARCHITECTURE.md`
- Testing: `TESTING_SUMMARY.md`
