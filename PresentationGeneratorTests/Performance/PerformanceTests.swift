import XCTest
@testable import PresentationGenerator

/// Performance tests for handling large projects and intensive operations
@MainActor
final class PerformanceTests: XCTestCase {
    
    var projectManager: ProjectManager!
    var slideGenerator: SlideGenerator!
    var contentAnalyzer: ContentAnalyzer!
    var powerPointExporter: PowerPointExporter!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize real services for performance testing
        let container = DependencyContainer()
        projectManager = container.projectManager
        slideGenerator = container.slideGenerator
        contentAnalyzer = container.contentAnalyzer
        powerPointExporter = container.powerPointExporter
    }
    
    override func tearDown() async throws {
        projectManager = nil
        slideGenerator = nil
        contentAnalyzer = nil
        powerPointExporter = nil
        try await super.tearDown()
    }
    
    // MARK: - Content Analysis Performance
    
    func testLargeDocumentAnalysisPerformance() throws {
        // Generate large document (10,000 words)
        let largeContent = (0..<10_000).map { "word\($0)" }.joined(separator: " ")
        
        measure {
            Task {
                do {
                    _ = try await contentAnalyzer.analyze(content: largeContent, audience: .business)
                } catch {
                    XCTFail("Analysis failed: \(error)")
                }
            }
        }
    }
    
    func testMultipleDocumentAnalysisPerformance() throws {
        let documents = (0..<10).map { index in
            (0..<1000).map { "word\($0)_doc\(index)" }.joined(separator: " ")
        }
        
        measure {
            Task {
                for document in documents {
                    do {
                        _ = try await contentAnalyzer.analyze(content: document, audience: .business)
                    } catch {
                        XCTFail("Analysis failed: \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - Slide Generation Performance
    
    func testLargeSlideSetGenerationPerformance() throws {
        // Generate 50+ key points
        let keyPoints = (0..<50).map { index in
            KeyPoint(
                text: "Key point \(index) with some detailed content to make it realistic",
                importance: index % 3 == 0 ? .high : .medium
            )
        }
        
        measure {
            Task {
                do {
                    let slides = try await slideGenerator.generateSlides(from: keyPoints, audience: .business)
                    XCTAssertEqual(slides.count, 50)
                } catch {
                    XCTFail("Generation failed: \(error)")
                }
            }
        }
    }
    
    func testSlideGenerationWithImagesPerformance() throws {
        let keyPoints = (0..<20).map { index in
            KeyPoint(
                text: "Point \(index) requiring image generation",
                importance: .high,
                suggestedVisuals: ["chart", "diagram"]
            )
        }
        
        measure {
            Task {
                do {
                    _ = try await slideGenerator.generateSlides(from: keyPoints, audience: .business)
                } catch {
                    XCTFail("Generation failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Export Performance
    
    func testLargePresentationExportPerformance() throws {
        // Create presentation with 50+ slides
        let slides = (0..<50).map { index in
            Slide(
                id: UUID(),
                title: "Slide \(index)",
                content: "This is the content for slide \(index). " + String(repeating: "Lorem ipsum dolor sit amet. ", count: 20),
                order: index,
                designSpec: DesignSpec(
                    colorScheme: .business,
                    fontFamily: "Helvetica",
                    fontSize: 24,
                    layout: .titleAndContent
                )
            )
        }
        
        let exportURL = URL(fileURLWithPath: "/tmp/performance_test.pptx")
        
        measure {
            Task {
                do {
                    _ = try await powerPointExporter.export(
                        slides: slides,
                        to: exportURL,
                        options: ExportOptions(
                            includeNotes: true,
                            includeImages: true,
                            compressionLevel: .medium
                        )
                    )
                } catch {
                    XCTFail("Export failed: \(error)")
                }
            }
        }
    }
    
    func testExportWithHighResolutionImagesPerformance() throws {
        // Create slides with high-resolution images
        let slides = (0..<10).map { index in
            var slide = Slide(
                id: UUID(),
                title: "Slide \(index)",
                content: "Content with image",
                order: index
            )
            
            // Add large image data (simulated)
            slide.imageData = ImageData(
                data: Data(count: 1_000_000), // 1MB per image
                format: .png
            )
            
            return slide
        }
        
        let exportURL = URL(fileURLWithPath: "/tmp/high_res_test.pptx")
        
        measure {
            Task {
                do {
                    _ = try await powerPointExporter.export(
                        slides: slides,
                        to: exportURL,
                        options: ExportOptions(
                            includeNotes: true,
                            includeImages: true,
                            compressionLevel: .high
                        )
                    )
                } catch {
                    XCTFail("Export failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Project Operations Performance
    
    func testMultipleProjectCreationPerformance() throws {
        measure {
            Task {
                for i in 0..<20 {
                    do {
                        _ = try await projectManager.createProject(
                            name: "Performance Test Project \(i)",
                            description: "Test project for performance testing",
                            audience: .business
                        )
                    } catch {
                        XCTFail("Project creation failed: \(error)")
                    }
                }
            }
        }
    }
    
    func testProjectListLoadingPerformance() throws {
        // Create multiple projects first
        Task {
            for i in 0..<50 {
                do {
                    _ = try await projectManager.createProject(
                        name: "Project \(i)",
                        description: nil,
                        audience: .business
                    )
                } catch {
                    XCTFail("Setup failed: \(error)")
                }
            }
        }
        
        measure {
            Task {
                do {
                    let projects = try await projectManager.listProjects()
                    XCTAssertGreaterThanOrEqual(projects.count, 50)
                } catch {
                    XCTFail("List projects failed: \(error)")
                }
            }
        }
    }
    
    func testProjectDuplicationPerformance() throws {
        // Create a large project
        let project = Task {
            do {
                let proj = try await projectManager.createProject(
                    name: "Large Project",
                    description: nil,
                    audience: .business
                )
                
                // Add 50 slides
                let slides = (0..<50).map { index in
                    Slide(
                        id: UUID(),
                        title: "Slide \(index)",
                        content: String(repeating: "Content ", count: 100),
                        order: index
                    )
                }
                
                try await projectManager.updateProject(proj.id, slides: slides)
                return proj
            } catch {
                XCTFail("Setup failed: \(error)")
                return nil
            }
        }.value
        
        measure {
            Task {
                if let proj = await project {
                    do {
                        _ = try await projectManager.duplicateProject(proj.id)
                    } catch {
                        XCTFail("Duplication failed: \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - Memory Performance
    
    func testMemoryUsageWithLargeProject() throws {
        let memoryBefore = reportMemoryUsage()
        
        // Create and load large project
        Task {
            do {
                let project = try await projectManager.createProject(
                    name: "Memory Test",
                    description: nil,
                    audience: .business
                )
                
                // Generate 100 slides with content
                let slides = (0..<100).map { index in
                    Slide(
                        id: UUID(),
                        title: "Slide \(index)",
                        content: String(repeating: "Lorem ipsum dolor sit amet. ", count: 50),
                        order: index,
                        designSpec: DesignSpec(
                            colorScheme: .business,
                            fontFamily: "Helvetica",
                            fontSize: 24,
                            layout: .titleAndContent
                        )
                    )
                }
                
                try await projectManager.updateProject(project.id, slides: slides)
                
                let memoryAfter = reportMemoryUsage()
                let memoryIncrease = memoryAfter - memoryBefore
                
                // Assert memory increase is reasonable (< 100MB for 100 slides)
                XCTAssertLessThan(memoryIncrease, 100_000_000, "Memory usage too high")
                
            } catch {
                XCTFail("Memory test failed: \(error)")
            }
        }
    }
    
    // MARK: - Concurrent Operations Performance
    
    func testConcurrentSlideGenerationPerformance() throws {
        let keyPointSets = (0..<5).map { setIndex in
            (0..<10).map { index in
                KeyPoint(
                    text: "Point \(index) in set \(setIndex)",
                    importance: .medium
                )
            }
        }
        
        measure {
            Task {
                await withTaskGroup(of: Void.self) { group in
                    for keyPoints in keyPointSets {
                        group.addTask {
                            do {
                                _ = try await self.slideGenerator.generateSlides(from: keyPoints, audience: .business)
                            } catch {
                                XCTFail("Concurrent generation failed: \(error)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func testConcurrentProjectOperationsPerformance() throws {
        measure {
            Task {
                await withTaskGroup(of: Void.self) { group in
                    // Concurrent creates
                    for i in 0..<5 {
                        group.addTask {
                            do {
                                _ = try await self.projectManager.createProject(
                                    name: "Concurrent Project \(i)",
                                    description: nil,
                                    audience: .business
                                )
                            } catch {
                                XCTFail("Concurrent create failed: \(error)")
                            }
                        }
                    }
                    
                    // Concurrent reads
                    for _ in 0..<5 {
                        group.addTask {
                            do {
                                _ = try await self.projectManager.listProjects()
                            } catch {
                                XCTFail("Concurrent read failed: \(error)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func reportMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        }
        return 0
    }
}
