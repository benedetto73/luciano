import Foundation

// MARK: - Protocol Definitions

protocol KeychainRepositoryProtocol {
    func save(apiKey: String) throws
    func retrieve() throws -> String?
    func delete() throws
}

protocol ProjectRepositoryProtocol {
    func save(_ project: Project) async throws
    func load(id: UUID) async throws -> Project
    func loadAll() async throws -> [Project]
    func delete(id: UUID) async throws
    func update(_ project: Project) async throws
}

protocol FileRepositoryProtocol {
    func importDocument(from url: URL) async throws -> String
    func saveImage(_ data: Data, for slideId: UUID) async throws -> URL
    func loadImage(for slideId: UUID) async throws -> Data
    func deleteImage(for slideId: UUID) async throws
    func cleanupUnusedImages(usedSlideIds: Set<UUID>) async throws
}

protocol PowerPointExporterProtocol {
    func export(project: Project, to url: URL) async throws
}

/// Dependency Injection Container for the application
/// Manages creation and lifecycle of all major components
@MainActor
class DependencyContainer: ObservableObject {
    // MARK: - Repositories
    
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
            documentParser: DocumentParser(),
            fileManager: .default
        )
    }()
    
    // MARK: - Services
    
    lazy var imageService: ImageService = {
        ImageService(fileRepository: fileRepository)
    }()
    
    lazy var openAIService: any OpenAIServiceProtocol = {
        // Check if user chose free models
        let useFreeModels = UserDefaults.standard.bool(forKey: "useFreeModels")
        
        if useFreeModels {
            Logger.shared.info("Using free models (mock service)", category: .api)
            return MockOpenAIService.realistic
        }
        
        // Retrieve API key from keychain
        guard let apiKey = try? keychainRepository.retrieve(), !apiKey.isEmpty else {
            Logger.shared.warning("No API key found in keychain, using mock service", category: .api)
            return MockOpenAIService.fast
        }
        
        Logger.shared.info("Initializing OpenAI service with stored API key", category: .api)
        return OpenAIService(apiKey: apiKey)
    }()
    
    lazy var contentAnalyzer: ContentAnalyzer = {
        ContentAnalyzer(
            openAIService: openAIService,
            fileRepository: fileRepository
        )
    }()
    
    lazy var slideDesigner: SlideDesigner = {
        SlideDesigner()
    }()
    
    lazy var slideGenerator: SlideGenerator = {
        SlideGenerator(
            openAIService: openAIService,
            imageService: imageService
        )
    }()
    
    lazy var slideRenderer: SlideRenderer = {
        SlideRenderer(imageService: imageService)
    }()
    
    lazy var powerPointExporter: PowerPointExporter = {
        PowerPointExporter(slideRenderer: slideRenderer)
    }()
    
    lazy var projectManager: ProjectManager = {
        ProjectManager(
            projectRepository: projectRepository,
            contentAnalyzer: contentAnalyzer,
            slideDesigner: slideDesigner,
            slideGenerator: slideGenerator,
            powerPointExporter: powerPointExporter
        )
    }()
    
    // MARK: - Coordinator
    
    lazy var appCoordinator: AppCoordinator = {
        AppCoordinator(
            keychainRepository: keychainRepository,
            dependencyContainer: self
        )
    }()
    
    // MARK: - ViewModels Factory Methods
    
    func makeProjectListViewModel() -> ProjectListViewModel {
        ProjectListViewModel(
            projectManager: projectManager,
            appCoordinator: appCoordinator
        )
    }
    
    func makeProjectCreationViewModel() -> ProjectCreationViewModel {
        ProjectCreationViewModel(
            projectManager: projectManager,
            appCoordinator: appCoordinator
        )
    }
    
    func makeProjectDetailViewModel(projectID: UUID) -> ProjectDetailViewModel {
        ProjectDetailViewModel(
            projectID: projectID,
            projectManager: projectManager,
            appCoordinator: appCoordinator,
            fileRepository: fileRepository
        )
    }
    
    func makeContentImportViewModel(projectID: UUID) -> ContentImportViewModel {
        ContentImportViewModel(
            projectID: projectID,
            projectManager: projectManager,
            fileRepository: fileRepository,
            appCoordinator: appCoordinator
        )
    }
    
    func makeSlideListViewModel(projectID: UUID) -> SlideListViewModel {
        SlideListViewModel(
            projectID: projectID,
            projectManager: projectManager,
            appCoordinator: appCoordinator
        )
    }
    
    func makeExportViewModel(projectID: UUID) -> ExportViewModel {
        ExportViewModel(
            projectID: projectID,
            projectManager: projectManager,
            appCoordinator: appCoordinator
        )
    }
    
    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            appCoordinator: appCoordinator,
            keychainRepository: keychainRepository
        )
    }
    
    func makeContentAnalysisViewModel(projectID: UUID) -> ContentAnalysisViewModel {
        ContentAnalysisViewModel(
            projectID: projectID,
            projectManager: projectManager,
            appCoordinator: appCoordinator
        )
    }
    
    func makeSlideGenerationViewModel(projectID: UUID) -> SlideGenerationViewModel {
        SlideGenerationViewModel(
            projectID: projectID,
            projectManager: projectManager,
            appCoordinator: appCoordinator
        )
    }
}

