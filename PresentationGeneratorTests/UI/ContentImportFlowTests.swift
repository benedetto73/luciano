import XCTest
@testable import PresentationGenerator

/// UI tests for the content import flow
@MainActor
final class ContentImportFlowTests: XCTestCase {
    
    var viewModel: ContentImportViewModel!
    var mockFileRepository: MockFileRepository!
    var mockContentAnalyzer: MockContentAnalyzer!
    
    override func setUp() async throws {
        try await super.setUp()
        mockFileRepository = MockFileRepository()
        mockContentAnalyzer = MockContentAnalyzer()
        viewModel = ContentImportViewModel(
            fileRepository: mockFileRepository,
            contentAnalyzer: mockContentAnalyzer
        )
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockFileRepository = nil
        mockContentAnalyzer = nil
        try await super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertNil(viewModel.selectedFileURL)
        XCTAssertNil(viewModel.importedContent)
        XCTAssertNil(viewModel.analysisResult)
        XCTAssertFalse(viewModel.isImporting)
        XCTAssertFalse(viewModel.isAnalyzing)
        XCTAssertNil(viewModel.error)
    }
    
    // MARK: - File Selection Tests
    
    func testFileSelection() {
        let fileURL = URL(fileURLWithPath: "/tmp/test.txt")
        
        viewModel.selectFile(url: fileURL)
        
        XCTAssertEqual(viewModel.selectedFileURL, fileURL)
        XCTAssertNil(viewModel.importedContent)
    }
    
    func testMultipleFileSelection() {
        let url1 = URL(fileURLWithPath: "/tmp/test1.txt")
        let url2 = URL(fileURLWithPath: "/tmp/test2.txt")
        
        viewModel.selectFile(url: url1)
        XCTAssertEqual(viewModel.selectedFileURL, url1)
        
        viewModel.selectFile(url: url2)
        XCTAssertEqual(viewModel.selectedFileURL, url2)
    }
    
    // MARK: - File Import Tests
    
    func testSuccessfulTextFileImport() async throws {
        let fileURL = URL(fileURLWithPath: "/tmp/test.txt")
        let expectedContent = "Test content"
        
        mockFileRepository.readTextFileResult = .success(expectedContent)
        
        await viewModel.importFile(url: fileURL)
        
        XCTAssertFalse(viewModel.isImporting)
        XCTAssertEqual(viewModel.importedContent, expectedContent)
        XCTAssertNil(viewModel.error)
        XCTAssertTrue(mockFileRepository.readTextFileCalled)
    }
    
    func testSuccessfulDocumentImport() async throws {
        let fileURL = URL(fileURLWithPath: "/tmp/test.pdf")
        let sourceFile = SourceFile(url: fileURL, content: "PDF content", metadata: [:])
        
        mockFileRepository.parseDocumentResult = .success(sourceFile)
        
        await viewModel.importFile(url: fileURL)
        
        XCTAssertFalse(viewModel.isImporting)
        XCTAssertEqual(viewModel.importedContent, sourceFile.content)
        XCTAssertNil(viewModel.error)
        XCTAssertTrue(mockFileRepository.parseDocumentCalled)
    }
    
    func testFileImportFailure() async throws {
        let fileURL = URL(fileURLWithPath: "/tmp/test.txt")
        
        mockFileRepository.readTextFileResult = .failure(.fileNotFound(fileURL.path))
        
        await viewModel.importFile(url: fileURL)
        
        XCTAssertFalse(viewModel.isImporting)
        XCTAssertNil(viewModel.importedContent)
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(mockFileRepository.readTextFileCalled)
    }
    
    func testImportLoadingState() async throws {
        let fileURL = URL(fileURLWithPath: "/tmp/test.txt")
        
        mockFileRepository.readTextFileDelay = 0.5
        mockFileRepository.readTextFileResult = .success("Content")
        
        let expectation = XCTestExpectation(description: "Import complete")
        
        Task {
            await viewModel.importFile(url: fileURL)
            expectation.fulfill()
        }
        
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        XCTAssertTrue(viewModel.isImporting)
        
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertFalse(viewModel.isImporting)
    }
    
    // MARK: - Content Analysis Tests
    
    func testSuccessfulContentAnalysis() async throws {
        let content = "Test content for analysis"
        viewModel.importedContent = content
        
        let expectedResult = ContentAnalysisResult(
            keyPoints: [KeyPoint(text: "Point 1", importance: .high)],
            suggestedSlideCount: 5,
            detectedTopics: ["Topic 1"],
            recommendedStructure: ["Intro", "Body", "Conclusion"]
        )
        
        mockContentAnalyzer.analyzeResult = .success(expectedResult)
        
        await viewModel.analyzeContent()
        
        XCTAssertFalse(viewModel.isAnalyzing)
        XCTAssertNotNil(viewModel.analysisResult)
        XCTAssertEqual(viewModel.analysisResult?.keyPoints.count, 1)
        XCTAssertNil(viewModel.error)
        XCTAssertTrue(mockContentAnalyzer.analyzeCalled)
    }
    
    func testContentAnalysisFailure() async throws {
        viewModel.importedContent = "Test content"
        
        mockContentAnalyzer.analyzeResult = .failure(.apiError("Analysis failed"))
        
        await viewModel.analyzeContent()
        
        XCTAssertFalse(viewModel.isAnalyzing)
        XCTAssertNil(viewModel.analysisResult)
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(mockContentAnalyzer.analyzeCalled)
    }
    
    func testAnalysisLoadingState() async throws {
        viewModel.importedContent = "Test content"
        
        mockContentAnalyzer.analyzeDelay = 0.5
        mockContentAnalyzer.analyzeResult = .success(ContentAnalysisResult(
            keyPoints: [],
            suggestedSlideCount: 5,
            detectedTopics: [],
            recommendedStructure: []
        ))
        
        let expectation = XCTestExpectation(description: "Analysis complete")
        
        Task {
            await viewModel.analyzeContent()
            expectation.fulfill()
        }
        
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(viewModel.isAnalyzing)
        
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertFalse(viewModel.isAnalyzing)
    }
    
    // MARK: - Complete Flow Tests
    
    func testCompleteImportAndAnalysisFlow() async throws {
        let fileURL = URL(fileURLWithPath: "/tmp/test.txt")
        let content = "Test content"
        
        mockFileRepository.readTextFileResult = .success(content)
        mockContentAnalyzer.analyzeResult = .success(ContentAnalysisResult(
            keyPoints: [KeyPoint(text: "Point 1", importance: .high)],
            suggestedSlideCount: 5,
            detectedTopics: ["Topic 1"],
            recommendedStructure: ["Intro"]
        ))
        
        // Import file
        await viewModel.importFile(url: fileURL)
        XCTAssertEqual(viewModel.importedContent, content)
        
        // Analyze content
        await viewModel.analyzeContent()
        XCTAssertNotNil(viewModel.analysisResult)
        
        XCTAssertTrue(mockFileRepository.readTextFileCalled)
        XCTAssertTrue(mockContentAnalyzer.analyzeCalled)
    }
    
    // MARK: - Reset Tests
    
    func testResetFlow() {
        viewModel.selectedFileURL = URL(fileURLWithPath: "/tmp/test.txt")
        viewModel.importedContent = "Content"
        viewModel.analysisResult = ContentAnalysisResult(
            keyPoints: [],
            suggestedSlideCount: 5,
            detectedTopics: [],
            recommendedStructure: []
        )
        
        viewModel.reset()
        
        XCTAssertNil(viewModel.selectedFileURL)
        XCTAssertNil(viewModel.importedContent)
        XCTAssertNil(viewModel.analysisResult)
        XCTAssertNil(viewModel.error)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorDismissal() async throws {
        mockFileRepository.readTextFileResult = .failure(.fileNotFound("/tmp/test.txt"))
        
        await viewModel.importFile(url: URL(fileURLWithPath: "/tmp/test.txt"))
        XCTAssertNotNil(viewModel.error)
        
        viewModel.dismissError()
        XCTAssertNil(viewModel.error)
    }
    
    // MARK: - Supported File Types Tests
    
    func testSupportedFileTypes() {
        let supportedExtensions = ["txt", "md", "pdf", "doc", "docx"]
        
        for ext in supportedExtensions {
            let url = URL(fileURLWithPath: "/tmp/test.\(ext)")
            XCTAssertTrue(viewModel.isFileTypeSupported(url: url))
        }
    }
    
    func testUnsupportedFileType() {
        let url = URL(fileURLWithPath: "/tmp/test.xyz")
        XCTAssertFalse(viewModel.isFileTypeSupported(url: url))
    }
    
    // MARK: - Edge Cases
    
    func testEmptyFileImport() async throws {
        mockFileRepository.readTextFileResult = .success("")
        
        await viewModel.importFile(url: URL(fileURLWithPath: "/tmp/empty.txt"))
        
        XCTAssertEqual(viewModel.importedContent, "")
    }
    
    func testLargeFileImport() async throws {
        let largeContent = String(repeating: "A", count: 1_000_000)
        mockFileRepository.readTextFileResult = .success(largeContent)
        
        await viewModel.importFile(url: URL(fileURLWithPath: "/tmp/large.txt"))
        
        XCTAssertEqual(viewModel.importedContent, largeContent)
    }
    
    func testConcurrentImports() async throws {
        let url1 = URL(fileURLWithPath: "/tmp/test1.txt")
        let url2 = URL(fileURLWithPath: "/tmp/test2.txt")
        
        mockFileRepository.readTextFileResult = .success("Content")
        
        async let import1 = viewModel.importFile(url: url1)
        async let import2 = viewModel.importFile(url: url2)
        
        await import1
        await import2
        
        XCTAssertNotNil(viewModel.importedContent)
    }
}

// MARK: - Mock Content Analyzer

@MainActor
class MockContentAnalyzer {
    var analyzeCalled = false
    var analyzeResult: Result<ContentAnalysisResult, AppError>?
    var analyzeDelay: TimeInterval = 0
    
    func analyze(content: String, audience: Audience) async throws -> ContentAnalysisResult {
        analyzeCalled = true
        
        if analyzeDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(analyzeDelay * 1_000_000_000))
        }
        
        switch analyzeResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        case .none:
            throw AppError.unknown("No result configured")
        }
    }
}

// MARK: - Content Analysis Result

struct ContentAnalysisResult {
    let keyPoints: [KeyPoint]
    let suggestedSlideCount: Int
    let detectedTopics: [String]
    let recommendedStructure: [String]
}
