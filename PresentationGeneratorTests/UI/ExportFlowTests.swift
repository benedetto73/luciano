import XCTest
@testable import PresentationGenerator

/// UI tests for the export flow
@MainActor
final class ExportFlowTests: XCTestCase {
    
    var viewModel: ExportViewModel!
    var mockPowerPointExporter: MockPowerPointExporter!
    var mockFileRepository: MockFileRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        mockPowerPointExporter = MockPowerPointExporter()
        mockFileRepository = MockFileRepository()
        
        let project = Project(
            id: UUID(),
            name: "Test Project",
            createdAt: Date(),
            modifiedAt: Date(),
            settings: ProjectSettings(audience: .business)
        )
        
        let slides = [
            Slide(id: UUID(), title: "Slide 1", content: "Content 1", order: 0),
            Slide(id: UUID(), title: "Slide 2", content: "Content 2", order: 1)
        ]
        
        viewModel = ExportViewModel(
            project: project,
            slides: slides,
            powerPointExporter: mockPowerPointExporter,
            fileRepository: mockFileRepository
        )
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockPowerPointExporter = nil
        mockFileRepository = nil
        try await super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertEqual(viewModel.exportFormat, .powerPoint)
        XCTAssertNil(viewModel.exportURL)
        XCTAssertFalse(viewModel.isExporting)
        XCTAssertEqual(viewModel.progress, 0.0)
        XCTAssertNil(viewModel.error)
    }
    
    // MARK: - Format Selection Tests
    
    func testFormatSelection() {
        viewModel.exportFormat = .pdf
        XCTAssertEqual(viewModel.exportFormat, .pdf)
        
        viewModel.exportFormat = .keynote
        XCTAssertEqual(viewModel.exportFormat, .keynote)
        
        viewModel.exportFormat = .powerPoint
        XCTAssertEqual(viewModel.exportFormat, .powerPoint)
    }
    
    // MARK: - Export Tests
    
    func testSuccessfulPowerPointExport() async throws {
        let exportURL = URL(fileURLWithPath: "/tmp/presentation.pptx")
        
        mockPowerPointExporter.exportResult = .success(exportURL)
        
        await viewModel.export(to: exportURL)
        
        XCTAssertFalse(viewModel.isExporting)
        XCTAssertEqual(viewModel.exportURL, exportURL)
        XCTAssertEqual(viewModel.progress, 1.0)
        XCTAssertNil(viewModel.error)
        XCTAssertTrue(mockPowerPointExporter.exportCalled)
    }
    
    func testExportFailure() async throws {
        let exportURL = URL(fileURLWithPath: "/tmp/presentation.pptx")
        
        mockPowerPointExporter.exportResult = .failure(.fileSystemError("Export failed"))
        
        await viewModel.export(to: exportURL)
        
        XCTAssertFalse(viewModel.isExporting)
        XCTAssertNil(viewModel.exportURL)
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(mockPowerPointExporter.exportCalled)
    }
    
    func testExportProgress() async throws {
        let exportURL = URL(fileURLWithPath: "/tmp/presentation.pptx")
        
        mockPowerPointExporter.exportDelay = 0.5
        mockPowerPointExporter.exportResult = .success(exportURL)
        
        let expectation = XCTestExpectation(description: "Export complete")
        
        Task {
            await viewModel.export(to: exportURL)
            expectation.fulfill()
        }
        
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(viewModel.isExporting)
        XCTAssertGreaterThan(viewModel.progress, 0.0)
        
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(viewModel.progress, 1.0)
    }
    
    // MARK: - PDF Export Tests
    
    func testPDFExport() async throws {
        viewModel.exportFormat = .pdf
        let exportURL = URL(fileURLWithPath: "/tmp/presentation.pdf")
        
        mockPowerPointExporter.exportResult = .success(exportURL)
        
        await viewModel.export(to: exportURL)
        
        XCTAssertEqual(viewModel.exportURL, exportURL)
        XCTAssertNil(viewModel.error)
    }
    
    // MARK: - File Name Generation Tests
    
    func testDefaultFileName() {
        let fileName = viewModel.suggestedFileName()
        
        XCTAssertTrue(fileName.contains("Test Project"))
        XCTAssertTrue(fileName.hasSuffix(".pptx"))
    }
    
    func testFileNameWithDifferentFormats() {
        viewModel.exportFormat = .pdf
        XCTAssertTrue(viewModel.suggestedFileName().hasSuffix(".pdf"))
        
        viewModel.exportFormat = .keynote
        XCTAssertTrue(viewModel.suggestedFileName().hasSuffix(".key"))
        
        viewModel.exportFormat = .powerPoint
        XCTAssertTrue(viewModel.suggestedFileName().hasSuffix(".pptx"))
    }
    
    func testFileNameSanitization() {
        let project = Project(
            id: UUID(),
            name: "My/Project:With*Special?Chars",
            createdAt: Date(),
            modifiedAt: Date(),
            settings: ProjectSettings(audience: .business)
        )
        
        viewModel.project = project
        let fileName = viewModel.suggestedFileName()
        
        XCTAssertFalse(fileName.contains("/"))
        XCTAssertFalse(fileName.contains(":"))
        XCTAssertFalse(fileName.contains("*"))
        XCTAssertFalse(fileName.contains("?"))
    }
    
    // MARK: - Export Options Tests
    
    func testIncludeNotesOption() {
        viewModel.includeNotes = true
        XCTAssertTrue(viewModel.includeNotes)
        
        viewModel.includeNotes = false
        XCTAssertFalse(viewModel.includeNotes)
    }
    
    func testIncludeImagesOption() {
        viewModel.includeImages = true
        XCTAssertTrue(viewModel.includeImages)
        
        viewModel.includeImages = false
        XCTAssertFalse(viewModel.includeImages)
    }
    
    func testCompressionOption() {
        viewModel.compressionLevel = .high
        XCTAssertEqual(viewModel.compressionLevel, .high)
        
        viewModel.compressionLevel = .none
        XCTAssertEqual(viewModel.compressionLevel, .none)
    }
    
    // MARK: - Preview Tests
    
    func testGeneratePreview() async throws {
        let slide = viewModel.slides[0]
        
        mockPowerPointExporter.generatePreviewResult = .success(Data())
        
        await viewModel.generatePreview(for: slide)
        
        XCTAssertNotNil(viewModel.previewData)
        XCTAssertTrue(mockPowerPointExporter.generatePreviewCalled)
    }
    
    func testPreviewFailure() async throws {
        let slide = viewModel.slides[0]
        
        mockPowerPointExporter.generatePreviewResult = .failure(.unknown("Preview failed"))
        
        await viewModel.generatePreview(for: slide)
        
        XCTAssertNil(viewModel.previewData)
        XCTAssertNotNil(viewModel.error)
    }
    
    // MARK: - Save Location Tests
    
    func testCustomSaveLocation() {
        let customURL = URL(fileURLWithPath: "/custom/path/presentation.pptx")
        
        viewModel.exportURL = customURL
        
        XCTAssertEqual(viewModel.exportURL, customURL)
    }
    
    func testDefaultSaveLocation() {
        let defaultURL = viewModel.defaultExportURL()
        
        XCTAssertNotNil(defaultURL)
        XCTAssertTrue(defaultURL.path.contains("Downloads") || defaultURL.path.contains("Documents"))
    }
    
    // MARK: - Cancel Tests
    
    func testCancelExport() async throws {
        let exportURL = URL(fileURLWithPath: "/tmp/presentation.pptx")
        
        mockPowerPointExporter.exportDelay = 1.0
        mockPowerPointExporter.exportResult = .success(exportURL)
        
        let expectation = XCTestExpectation(description: "Export cancelled")
        
        Task {
            await viewModel.export(to: exportURL)
            expectation.fulfill()
        }
        
        try await Task.sleep(nanoseconds: 100_000_000)
        viewModel.cancelExport()
        
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertFalse(viewModel.isExporting)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorDismissal() async throws {
        mockPowerPointExporter.exportResult = .failure(.fileSystemError("Error"))
        
        await viewModel.export(to: URL(fileURLWithPath: "/tmp/test.pptx"))
        XCTAssertNotNil(viewModel.error)
        
        viewModel.dismissError()
        XCTAssertNil(viewModel.error)
    }
    
    func testDiskSpaceError() async throws {
        let exportURL = URL(fileURLWithPath: "/tmp/presentation.pptx")
        
        mockPowerPointExporter.exportResult = .failure(.fileSystemError("Insufficient disk space"))
        
        await viewModel.export(to: exportURL)
        
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.error!.localizedDescription.contains("disk space"))
    }
    
    // MARK: - Edge Cases
    
    func testExportEmptyPresentation() async throws {
        viewModel.slides = []
        
        mockPowerPointExporter.exportResult = .success(URL(fileURLWithPath: "/tmp/empty.pptx"))
        
        await viewModel.export(to: URL(fileURLWithPath: "/tmp/empty.pptx"))
        
        XCTAssertTrue(mockPowerPointExporter.exportCalled)
    }
    
    func testExportLargePresentation() async throws {
        let largeSlideSet = (0..<100).map {
            Slide(id: UUID(), title: "Slide \($0)", content: "Content \($0)", order: $0)
        }
        viewModel.slides = largeSlideSet
        
        mockPowerPointExporter.exportResult = .success(URL(fileURLWithPath: "/tmp/large.pptx"))
        
        await viewModel.export(to: URL(fileURLWithPath: "/tmp/large.pptx"))
        
        XCTAssertNotNil(viewModel.exportURL)
    }
    
    func testExportWithSpecialCharactersInPath() async throws {
        let specialURL = URL(fileURLWithPath: "/tmp/プレゼン 演示.pptx")
        
        mockPowerPointExporter.exportResult = .success(specialURL)
        
        await viewModel.export(to: specialURL)
        
        XCTAssertEqual(viewModel.exportURL, specialURL)
    }
    
    func testConcurrentExports() async throws {
        let url1 = URL(fileURLWithPath: "/tmp/export1.pptx")
        let url2 = URL(fileURLWithPath: "/tmp/export2.pptx")
        
        mockPowerPointExporter.exportResult = .success(url1)
        
        async let export1 = viewModel.export(to: url1)
        async let export2 = viewModel.export(to: url2)
        
        await export1
        await export2
        
        XCTAssertNotNil(viewModel.exportURL)
    }
}

// MARK: - Mock PowerPoint Exporter

@MainActor
class MockPowerPointExporter {
    var exportCalled = false
    var exportResult: Result<URL, AppError>?
    var exportDelay: TimeInterval = 0
    
    var generatePreviewCalled = false
    var generatePreviewResult: Result<Data, AppError>?
    
    func export(slides: [Slide], to url: URL, options: ExportOptions) async throws -> URL {
        exportCalled = true
        
        if exportDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(exportDelay * 1_000_000_000))
        }
        
        switch exportResult {
        case .success(let url):
            return url
        case .failure(let error):
            throw error
        case .none:
            throw AppError.unknown("No result configured")
        }
    }
    
    func generatePreview(for slide: Slide) async throws -> Data {
        generatePreviewCalled = true
        
        switch generatePreviewResult {
        case .success(let data):
            return data
        case .failure(let error):
            throw error
        case .none:
            throw AppError.unknown("No result configured")
        }
    }
}

// MARK: - Export Options

struct ExportOptions {
    let includeNotes: Bool
    let includeImages: Bool
    let compressionLevel: CompressionLevel
}

enum CompressionLevel {
    case none
    case low
    case medium
    case high
}

enum ExportFormat {
    case powerPoint
    case pdf
    case keynote
}
