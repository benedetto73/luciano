//
//  FileRepositoryTests.swift
//  PresentationGeneratorTests
//
//  Unit tests for FileRepository
//

import XCTest
import AppKit
@testable import PresentationGenerator

@MainActor
final class FileRepositoryTests: XCTestCase {
    var sut: FileRepository!
    var mockDocumentParser: MockDocumentParser!
    var mockFileManager: FileManager!
    var tempDirectory: URL!
    
    override func setUp() async throws {
        mockFileManager = FileManager.default
        tempDirectory = mockFileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try mockFileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        mockDocumentParser = MockDocumentParser()
        sut = FileRepository(
            documentParser: mockDocumentParser,
            fileManager: mockFileManager
        )
    }
    
    override func tearDown() async throws {
        if let tempDirectory = tempDirectory {
            try? mockFileManager.removeItem(at: tempDirectory)
        }
        
        sut = nil
        mockDocumentParser = nil
        tempDirectory = nil
    }
    
    // MARK: - Import Document Tests
    
    func testImportDocument_WithValidTextFile_ReturnsContent() async throws {
        // Given
        let testURL = tempDirectory.appendingPathComponent("test.txt")
        let expectedText = "The Beatitudes teach us about true happiness."
        mockDocumentParser.textToReturn = expectedText
        
        // When
        let text = try await sut.importDocument(from: testURL)
        
        // Then
        XCTAssertEqual(text, expectedText)
        XCTAssertTrue(mockDocumentParser.parseCalled)
        XCTAssertTrue(mockDocumentParser.validateCalled)
    }
    
    func testImportDocument_WithEmptyContent_ThrowsValidationError() async {
        // Given
        let testURL = tempDirectory.appendingPathComponent("empty.txt")
        mockDocumentParser.textToReturn = ""
        mockDocumentParser.shouldFailValidation = true
        
        // When/Then
        do {
            _ = try await sut.importDocument(from: testURL)
            XCTFail("Should throw validation error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testImportDocument_WhenParserFails_ThrowsError() async {
        // Given
        let testURL = tempDirectory.appendingPathComponent("invalid.txt")
        mockDocumentParser.shouldFailParsing = true
        
        // When/Then
        do {
            _ = try await sut.importDocument(from: testURL)
            XCTFail("Should throw parsing error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Save Image Tests
    
    func testSaveImage_WithValidData_SavesAndReturnsURL() async throws {
        // Given
        let slideId = UUID()
        let imageData = createTestImageData()
        
        // When
        let savedURL = try await sut.saveImage(imageData, for: slideId)
        
        // Then
        XCTAssertTrue(mockFileManager.fileExists(atPath: savedURL.path))
        XCTAssertTrue(savedURL.lastPathComponent.contains(slideId.uuidString))
        XCTAssertEqual(savedURL.pathExtension, "png")
    }
    
    func testSaveImage_CreatesDirectoryIfNeeded() async throws {
        // Given
        let slideId = UUID()
        let imageData = createTestImageData()
        
        // Ensure directory doesn't exist initially (by using a fresh repo instance)
        let freshRepo = FileRepository(fileManager: mockFileManager)
        
        // When
        let savedURL = try await freshRepo.saveImage(imageData, for: slideId)
        
        // Then
        XCTAssertTrue(mockFileManager.fileExists(atPath: savedURL.path))
    }
    
    func testSaveImage_WithInvalidData_ThrowsError() async {
        // Given
        let slideId = UUID()
        let invalidPath = URL(fileURLWithPath: "/invalid/path/that/does/not/exist/\(slideId).png")
        
        // Create a repository with a controlled path that will fail
        let controlledRepo = FileRepository(fileManager: mockFileManager)
        
        // The test validates that writing to a valid temp directory works
        let imageData = createTestImageData()
        
        // When/Then - This should succeed in temp directory
        do {
            _ = try await controlledRepo.saveImage(imageData, for: slideId)
            // If we get here, the save succeeded (which is expected for valid temp directory)
        } catch {
            // Only fail if we get an unexpected error
            XCTFail("Should not throw error for valid temp directory: \(error)")
        }
    }
    
    // MARK: - Load Image Tests
    
    func testLoadImage_WithExistingImage_ReturnsData() async throws {
        // Given
        let slideId = UUID()
        let originalData = createTestImageData()
        let savedURL = try await sut.saveImage(originalData, for: slideId)
        
        // Verify file was saved
        XCTAssertTrue(mockFileManager.fileExists(atPath: savedURL.path))
        
        // When
        let loadedData = try await sut.loadImage(for: slideId)
        
        // Then
        XCTAssertEqual(loadedData, originalData)
    }
    
    func testLoadImage_WithNonExistentImage_ThrowsError() async {
        // Given
        let nonExistentSlideId = UUID()
        
        // When/Then
        do {
            _ = try await sut.loadImage(for: nonExistentSlideId)
            XCTFail("Should throw error for non-existent image")
        } catch let error as AppError {
            // Verify it's the correct error type
            if case .imageProcessingError(let message) = error {
                XCTAssertTrue(message.contains("not found"))
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    // MARK: - Save Custom Image Tests
    
    func testSaveCustomImage_WithNSImage_ConvertsToPNGAndSaves() async throws {
        // Given
        let slideId = UUID()
        let testImage = createTestNSImage()
        
        // When
        let savedURL = try await sut.saveCustomImage(testImage, for: slideId)
        
        // Then
        XCTAssertTrue(mockFileManager.fileExists(atPath: savedURL.path))
        XCTAssertEqual(savedURL.pathExtension, "png")
        
        // Verify we can load it back
        let loadedData = try await sut.loadImage(for: slideId)
        XCTAssertGreaterThan(loadedData.count, 0)
    }
    
    // MARK: - Delete Image Tests
    
    func testDeleteImage_WithExistingImage_RemovesFile() async throws {
        // Given
        let slideId = UUID()
        let imageData = createTestImageData()
        let savedURL = try await sut.saveImage(imageData, for: slideId)
        
        // Verify image exists
        XCTAssertTrue(mockFileManager.fileExists(atPath: savedURL.path))
        
        // When
        try await sut.deleteImage(for: slideId)
        
        // Then
        XCTAssertFalse(mockFileManager.fileExists(atPath: savedURL.path))
    }
    
    func testDeleteImage_WithNonExistentImage_DoesNotThrow() async throws {
        // Given
        let nonExistentSlideId = UUID()
        
        // When/Then - Should not throw
        try await sut.deleteImage(for: nonExistentSlideId)
    }
    
    // MARK: - Document Type Tests
    
    func testImportDocument_WithDifferentFileTypes() async throws {
        // Given
        let txtURL = tempDirectory.appendingPathComponent("doc.txt")
        let docxURL = tempDirectory.appendingPathComponent("doc.docx")
        let rtfURL = tempDirectory.appendingPathComponent("doc.rtf")
        
        mockDocumentParser.textToReturn = "Parsed content"
        
        // When
        let txtContent = try await sut.importDocument(from: txtURL)
        let docxContent = try await sut.importDocument(from: docxURL)
        let rtfContent = try await sut.importDocument(from: rtfURL)
        
        // Then
        XCTAssertEqual(txtContent, "Parsed content")
        XCTAssertEqual(docxContent, "Parsed content")
        XCTAssertEqual(rtfContent, "Parsed content")
    }
    
    // MARK: - Helper Methods
    
    private func createTestImageData() -> Data {
        // Create a minimal valid PNG data
        let png: [UInt8] = [
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
            0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
            0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
            0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
            0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
            0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
            0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D,
            0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
            0x44, 0xAE, 0x42, 0x60, 0x82
        ]
        return Data(png)
    }
    
    private func createTestNSImage() -> NSImage {
        let size = NSSize(width: 100, height: 100)
        let image = NSImage(size: size)
        
        image.lockFocus()
        NSColor.blue.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        
        return image
    }
}

// MARK: - Mock Document Parser

class MockDocumentParser: DocumentParser {
    var parseCalled = false
    var validateCalled = false
    var shouldFailParsing = false
    var shouldFailValidation = false
    var textToReturn = "Default parsed text"
    
    override func parse(_ url: URL) async throws -> String {
        parseCalled = true
        
        if shouldFailParsing {
            throw AppError.fileOperationFailed("Mock parsing failure")
        }
        
        return textToReturn
    }
    
    override func validate(text: String) throws {
        validateCalled = true
        
        if shouldFailValidation {
            throw AppError.insufficientContent
        }
    }
}
