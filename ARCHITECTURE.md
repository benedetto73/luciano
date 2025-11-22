# PresentationGenerator - Architecture Documentation

**Version:** 1.0.0  
**Last Updated:** November 22, 2025

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Patterns](#architecture-patterns)
3. [Layer Architecture](#layer-architecture)
4. [Component Design](#component-design)
5. [Data Flow](#data-flow)
6. [Design Decisions](#design-decisions)
7. [Technology Stack](#technology-stack)
8. [Directory Structure](#directory-structure)

---

## Overview

PresentationGenerator is a macOS SwiftUI application built using **MVVM architecture** with **dependency injection** and a **repository pattern** for data access. The app follows modern Swift concurrency patterns (async/await) and reactive programming with Combine.

### Core Principles

1. **Separation of Concerns** - Clear boundaries between UI, business logic, and data
2. **Testability** - Protocol-based design enables comprehensive testing
3. **Maintainability** - Modular structure with single responsibility
4. **Scalability** - Easy to extend with new features
5. **Type Safety** - Leverages Swift's strong type system

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     SwiftUI Views                       │
│              (User Interface Layer)                     │
└────────────────────┬────────────────────────────────────┘
                     │ @ObservedObject
┌────────────────────▼────────────────────────────────────┐
│                   ViewModels                            │
│         (Presentation Logic Layer)                      │
└────────────────────┬────────────────────────────────────┘
                     │ Dependencies
┌────────────────────▼────────────────────────────────────┐
│              AppCoordinator                             │
│            ProjectManager                               │
│         (Coordination Layer)                            │
└────────────────────┬────────────────────────────────────┘
                     │ Business Logic
┌────────────────────▼────────────────────────────────────┐
│    Services (Business Logic Layer)                      │
│  ContentAnalyzer │ SlideGenerator │ SlideDesigner       │
│    ImageService  │ SlideRenderer  │ PowerPointExporter  │
└────────────────────┬────────────────────────────────────┘
                     │ Data Access
┌────────────────────▼────────────────────────────────────┐
│         Repositories (Data Layer)                       │
│  ProjectRepository │ FileRepository │ KeychainRepository │
└────────────────────┬────────────────────────────────────┘
                     │ Persistence
┌────────────────────▼────────────────────────────────────┐
│              Models (Domain Layer)                      │
│    Project │ Slide │ KeyPoint │ DesignSpec │ Audience   │
└─────────────────────────────────────────────────────────┘
```

---

## Architecture Patterns

### MVVM (Model-View-ViewModel)

**Why MVVM?**
- Natural fit for SwiftUI's declarative syntax
- Clear separation between UI and business logic
- Enables comprehensive unit testing
- Supports reactive updates via Combine

**Implementation:**

```swift
// View - Pure SwiftUI, no business logic
struct ProjectListView: View {
    @ObservedObject var viewModel: ProjectListViewModel
    
    var body: some View {
        List(viewModel.projects) { project in
            ProjectRow(project: project)
        }
    }
}

// ViewModel - Presentation logic, @Published properties
@MainActor
class ProjectListViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var isLoading = false
    
    private let projectManager: ProjectManager
    
    func loadProjects() async {
        isLoading = true
        projects = try await projectManager.loadAllProjects()
        isLoading = false
    }
}

// Model - Pure data, no logic
struct Project: Identifiable, Codable {
    let id: UUID
    var name: String
    var audience: Audience
    // ...
}
```

### Dependency Injection

**Pattern:** Constructor Injection via Container

**Benefits:**
- Loose coupling between components
- Easy to test with mocks
- Centralized dependency management
- Lazy initialization for performance

**Implementation:**

```swift
@MainActor
class DependencyContainer: ObservableObject {
    // Singleton
    static let shared = DependencyContainer()
    
    // Lazy dependencies
    private lazy var keychainRepository: KeychainRepositoryProtocol = {
        KeychainRepository()
    }()
    
    private lazy var projectRepository: ProjectRepositoryProtocol = {
        ProjectRepository()
    }()
    
    // Factory methods
    func makeProjectListViewModel() -> ProjectListViewModel {
        ProjectListViewModel(
            projectManager: projectManager,
            coordinator: appCoordinator
        )
    }
}
```

### Repository Pattern

**Purpose:** Abstract data access and persistence

**Benefits:**
- Centralizes data access logic
- Hides implementation details
- Enables easy swapping of storage mechanisms
- Improves testability

**Implementation:**

```swift
// Protocol defines contract
protocol ProjectRepositoryProtocol {
    func save(_ project: Project) async throws
    func load(id: UUID) async throws -> Project
    func loadAll() async throws -> [Project]
    func delete(id: UUID) async throws
}

// Implementation handles actual storage
class ProjectRepository: ProjectRepositoryProtocol {
    private let storageManager: ProjectStorageManager
    
    func save(_ project: Project) async throws {
        try storageManager.save(project)
        Logger.shared.info("Project saved")
    }
    // ...
}
```

### Coordinator Pattern

**Purpose:** Centralize navigation logic

**Benefits:**
- Decouples navigation from view logic
- Single source of truth for app state
- Easy to modify navigation flow
- Supports deep linking

**Implementation:**

```swift
@MainActor
class AppCoordinator: ObservableObject {
    @Published var navigationPath: [AppScreen] = []
    @Published var appState: AppState = .splash
    
    enum AppScreen {
        case projectList
        case projectCreation
        case projectDetail(UUID)
        case settings
    }
    
    func navigate(to screen: AppScreen) {
        navigationPath.append(screen)
    }
    
    func navigateBack() {
        _ = navigationPath.popLast()
    }
}
```

---

## Layer Architecture

### 1. Presentation Layer (Views)

**Responsibility:** User interface and user interaction

**Components:**
- SwiftUI Views
- View modifiers
- Reusable components

**Rules:**
- No business logic
- No direct data access
- Only communicate with ViewModel
- Pure functions for rendering

**Example Directories:**
```
Views/
├── ProjectList/
│   └── ProjectListView.swift
├── ProjectCreation/
│   ├── ProjectCreationView.swift
│   └── AudienceSelectionView.swift
├── Components/
│   ├── LoadingView.swift
│   ├── ErrorView.swift
│   └── CustomProgressView.swift
```

### 2. ViewModel Layer

**Responsibility:** Presentation logic and state management

**Components:**
- ViewModels (one per major screen)
- @Published properties for reactive updates
- User action handlers

**Rules:**
- @MainActor for thread safety
- No UI components
- Communicate via Coordinator/Services
- Manage only view-related state

**Example:**
```swift
@MainActor
class ProjectDetailViewModel: ObservableObject {
    @Published var project: Project?
    @Published var isLoading = false
    @Published var error: AppError?
    
    private let projectManager: ProjectManager
    private let coordinator: AppCoordinator
    
    func loadProject(id: UUID) async {
        isLoading = true
        do {
            project = try await projectManager.loadProject(id: id)
        } catch {
            self.error = error as? AppError
        }
        isLoading = false
    }
}
```

### 3. Coordination Layer

**Responsibility:** App-wide orchestration and navigation

**Components:**
- AppCoordinator - Navigation state machine
- ProjectManager - High-level workflows
- DependencyContainer - Dependency injection

**Rules:**
- Manage app-level state
- Coordinate between services
- Handle complex workflows
- No UI dependencies

### 4. Service Layer

**Responsibility:** Business logic and external integrations

**Components:**
- ContentAnalyzer - Extracts key points
- SlideGenerator - Creates slides
- SlideDesigner - Generates design specs
- ImageService - Image management
- OpenAI Service - API integration
- PowerPointExporter - Export logic

**Rules:**
- Single responsibility per service
- Protocol-based for testability
- Async/await for operations
- Proper error handling

**Example:**
```swift
@MainActor
class ContentAnalyzer: ObservableObject {
    private let openAIService: OpenAIServiceProtocol
    
    func analyze(
        sourceFile: SourceFile,
        preferredAudience: Audience? = nil
    ) async throws -> ContentAnalysisResult {
        // 1. Validate input
        // 2. Call OpenAI API
        // 3. Process results
        // 4. Return structured data
    }
}
```

### 5. Repository Layer

**Responsibility:** Data persistence and retrieval

**Components:**
- ProjectRepository - Project CRUD
- FileRepository - File operations
- KeychainRepository - Secure storage

**Rules:**
- Protocol-based interfaces
- Hide implementation details
- Handle data validation
- Manage transactions

### 6. Domain Layer (Models)

**Responsibility:** Core business entities

**Components:**
- Domain models (Project, Slide, etc.)
- DTOs for API communication
- Value objects (Audience, DesignSpec)

**Rules:**
- Codable for serialization
- Identifiable where needed
- Immutable when possible
- No business logic

---

## Component Design

### Models

**Domain Models:**
```swift
struct Project: Identifiable, Codable {
    let id: UUID
    var name: String
    var audience: Audience
    var createdDate: Date
    var modifiedDate: Date
    var sourceFiles: [SourceFile]
    var keyPoints: [KeyPoint]
    var slides: [Slide]
    var settings: ProjectSettings?
}
```

**Design Principles:**
- Value semantics (struct)
- Immutable by default (let)
- Codable for persistence
- Identifiable for SwiftUI

### Services

**Service Pattern:**
```swift
@MainActor
class ServiceName: ObservableObject {
    // Published state
    @Published var isProcessing = false
    @Published var lastError: Error?
    
    // Dependencies
    private let dependency: DependencyProtocol
    
    // Public API
    func performOperation() async throws -> Result {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let result = try await actualWork()
            return result
        } catch {
            lastError = error
            throw error
        }
    }
}
```

### ViewModels

**ViewModel Pattern:**
```swift
@MainActor
class ScreenViewModel: ObservableObject {
    // UI State
    @Published var data: [Item] = []
    @Published var isLoading = false
    @Published var error: AppError?
    
    // Dependencies
    private let service: ServiceProtocol
    private let coordinator: AppCoordinator
    
    // Initialization
    init(service: ServiceProtocol, coordinator: AppCoordinator) {
        self.service = service
        self.coordinator = coordinator
    }
    
    // User Actions
    func onAppear() async {
        await loadData()
    }
    
    func handleAction() {
        coordinator.navigate(to: .nextScreen)
    }
    
    // Private Helpers
    private func loadData() async {
        isLoading = true
        do {
            data = try await service.fetchData()
        } catch {
            self.error = error as? AppError
        }
        isLoading = false
    }
}
```

---

## Data Flow

### Workflow: Creating a Presentation

```
User Input → View → ViewModel → Coordinator → ProjectManager
                                                     ↓
                              ┌──────────────────────┴────────────┐
                              ↓                                   ↓
                     ContentAnalyzer                    SlideGenerator
                              ↓                                   ↓
                       OpenAI Service                    ImageService
                              ↓                                   ↓
                     ContentAnalysisResult              Generated Slides
                              ↓                                   ↓
                              └──────────────────┬────────────────┘
                                                 ↓
                                         ProjectRepository
                                                 ↓
                                           JSON Storage
                                                 ↓
                                      View Updates (Reactive)
```

### State Management

**Reactive Updates with Combine:**

```swift
// 1. ViewModel publishes state
@MainActor
class ListViewModel: ObservableObject {
    @Published var items: [Item] = []
}

// 2. View observes changes
struct ListView: View {
    @ObservedObject var viewModel: ListViewModel
    
    var body: some View {
        List(viewModel.items) { item in
            // Automatically updates when items change
        }
    }
}

// 3. State update triggers view refresh
viewModel.items.append(newItem)  // View re-renders
```

### Error Handling Flow

```
Operation → Error Thrown → Catch in Service → Store in lastError
                                                      ↓
                                              ViewModel @Published
                                                      ↓
                                                View Shows Error
                                                      ↓
                                              User Can Retry
```

---

## Design Decisions

### 1. Why SwiftUI Over UIKit?

**Decision:** Use SwiftUI for UI layer

**Rationale:**
- Modern, declarative syntax
- Less boilerplate code
- Built-in state management
- Better suited for macOS 13+
- Future-proof

**Trade-offs:**
- Less mature than UIKit
- Some features require AppKit bridging
- Learning curve for team

### 2. Why Async/Await Over Completion Handlers?

**Decision:** Use async/await for asynchronous operations

**Rationale:**
- More readable code
- Better error handling
- Avoids callback hell
- Native Swift concurrency
- Easier to reason about

**Example:**
```swift
// Old way (completion handlers)
func loadProject(id: UUID, completion: @escaping (Result<Project, Error>) -> Void) {
    // nested callbacks...
}

// New way (async/await)
func loadProject(id: UUID) async throws -> Project {
    // linear flow
}
```

### 3. Why JSON Over Core Data?

**Decision:** Use JSON files for project storage

**Rationale:**
- Simpler implementation
- Human-readable format
- Easy export/import
- No migration complexity
- Sufficient for use case

**Trade-offs:**
- Less efficient for large datasets
- No built-in relationships
- Manual querying

### 4. Why Protocol-Based Design?

**Decision:** Use protocols for all service interfaces

**Rationale:**
- Enables dependency injection
- Facilitates testing with mocks
- Loose coupling
- Flexible implementations

**Example:**
```swift
protocol ProjectRepositoryProtocol {
    func save(_ project: Project) async throws
}

// Easy to mock for testing
class MockProjectRepository: ProjectRepositoryProtocol {
    var savedProjects: [Project] = []
    
    func save(_ project: Project) async throws {
        savedProjects.append(project)
    }
}
```

### 5. Why @MainActor for ViewModels?

**Decision:** Mark all ViewModels with @MainActor

**Rationale:**
- Ensures UI updates on main thread
- Prevents data races
- Simplifies concurrency
- SwiftUI requirement

**Warning Without @MainActor:**
```
Publishing changes from background threads is not allowed
```

---

## Technology Stack

### Core Frameworks

- **SwiftUI** - UI framework (macOS 13+)
- **Combine** - Reactive programming
- **Foundation** - Core utilities
- **AppKit** - macOS-specific features

### External Dependencies

- **OpenAI SDK** (MacPaw/OpenAI v0.2.4)
  - GPT-4 for content generation
  - DALL-E for image generation
  - Chat completions API

### Swift Features Used

- **Async/Await** - Concurrency
- **Actors** - Thread safety (@MainActor)
- **Generics** - Type-safe code
- **Protocols** - Abstraction
- **Codable** - Serialization
- **Result Type** - Error handling
- **Property Wrappers** - @Published, @ObservedObject

---

## Directory Structure

```
PresentationGenerator/
├── App/
│   ├── PresentationGeneratorApp.swift     # App entry point
│   └── AppCoordinator.swift               # Navigation
│
├── Models/
│   ├── Domain/                            # Business models
│   │   ├── Project.swift
│   │   ├── Slide.swift
│   │   ├── KeyPoint.swift
│   │   ├── Audience.swift
│   │   └── DesignSpec.swift
│   └── DTOs/                              # API data transfer
│       ├── ChatCompletionDTO.swift
│       └── ImageGenerationDTO.swift
│
├── ViewModels/                            # Presentation logic
│   ├── ProjectListViewModel.swift
│   ├── ProjectCreationViewModel.swift
│   ├── ProjectDetailViewModel.swift
│   ├── ContentImportViewModel.swift
│   ├── SlideGenerationViewModel.swift
│   └── SettingsViewModel.swift
│
├── Views/                                 # UI components
│   ├── ProjectList/
│   ├── ProjectCreation/
│   ├── ContentImport/
│   ├── SlideGeneration/
│   ├── Settings/
│   └── Components/                        # Reusable UI
│       ├── LoadingView.swift
│       ├── ErrorView.swift
│       └── CustomProgressView.swift
│
├── Services/                              # Business logic
│   ├── BusinessLogic/
│   │   ├── ContentAnalyzer.swift
│   │   ├── SlideGenerator.swift
│   │   ├── SlideDesigner.swift
│   │   └── ProjectManager.swift
│   ├── OpenAI/
│   │   ├── OpenAIService.swift
│   │   └── ContentFilter.swift
│   ├── Export/
│   │   └── PowerPointExporter.swift
│   └── Image/
│       └── ImageService.swift
│
├── Repositories/                          # Data access
│   ├── Project/
│   │   ├── ProjectRepository.swift
│   │   └── ProjectStorageManager.swift
│   ├── File/
│   │   ├── FileRepository.swift
│   │   └── DocumentParser.swift
│   └── Keychain/
│       └── KeychainRepository.swift
│
├── DependencyInjection/
│   └── DependencyContainer.swift          # DI container
│
├── Utilities/
│   ├── Constants/                         # App constants
│   ├── Extensions/                        # Swift extensions
│   ├── Helpers/                           # Helper functions
│   └── Prompts/                           # AI prompts
│
└── Testing/
    └── MockOpenAIService.swift            # Testing mocks
```

**Total:** 89 Swift files organized in 10 main directories

---

## Key Architectural Benefits

### 1. Testability
- Protocol-based design enables mocking
- Dependency injection simplifies testing
- Separation of concerns isolates components
- 100+ unit tests covering core services

### 2. Maintainability
- Clear layer boundaries
- Single responsibility principle
- Modular structure
- Comprehensive documentation

### 3. Scalability
- Easy to add new screens
- Simple service extension
- Flexible data models
- Pluggable components

### 4. Performance
- Lazy dependency initialization
- Async operations don't block UI
- Efficient state management
- Minimal re-renders

### 5. Safety
- Type-safe throughout
- @MainActor prevents threading issues
- Comprehensive error handling
- Validation at boundaries

---

## Future Enhancements

### Potential Architectural Improvements

1. **Core Data Migration**
   - For better query performance
   - Complex relationships
   - iCloud sync support

2. **Modularization**
   - Extract services to Swift packages
   - Shared framework for macOS/iOS
   - Plugin architecture

3. **Caching Layer**
   - In-memory cache for projects
   - Image cache management
   - API response caching

4. **Event Sourcing**
   - Audit trail for changes
   - Undo/redo support
   - Collaboration features

5. **Background Processing**
   - Queue for slide generation
   - Batch processing
   - Priority scheduling

---

**For more information:**
- User Guide: `USER_GUIDE.md`
- API Documentation: `API_DOCUMENTATION.md`
- Testing Summary: `TESTING_SUMMARY.md`
