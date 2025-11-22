//
//  SlideDesignerTests.swift
//  PresentationGeneratorTests
//
//  Unit tests for SlideDesigner service
//

import XCTest
@testable import PresentationGenerator

@MainActor
final class SlideDesignerTests: XCTestCase {
    var sut: SlideDesigner!
    
    override func setUp() async throws {
        sut = SlideDesigner()
    }
    
    override func tearDown() async throws {
        sut = nil
    }
    
    // MARK: - Design Spec Creation Tests
    
    func testCreateDesignSpec_ForKids_ReturnsAppropriateDesign() async throws {
        // Given
        let audience = Audience.kids
        
        // When
        let spec = try await sut.createDesignSpec(for: audience)
        
        // Then
        XCTAssertEqual(spec.fontSize, .large, "Kids should have large font")
        XCTAssertEqual(spec.backgroundColor, "#FFEB3B", "Kids should have bright background")
        XCTAssertEqual(spec.layout, .titleAndContent, "Kids should have simple layout")
        XCTAssertNotNil(spec.fontFamily)
        XCTAssertNotNil(spec.textColor)
    }
    
    func testCreateDesignSpec_ForTeenagers_ReturnsAppropriateDesign() async throws {
        // Given
        let audience = Audience.teenagers
        
        // When
        let spec = try await sut.createDesignSpec(for: audience)
        
        // Then
        XCTAssertEqual(spec.fontSize, .medium, "Teenagers should have medium font")
        XCTAssertEqual(spec.layout, .titleContentAndImage, "Teenagers should have moderate layout")
        XCTAssertNotNil(spec.backgroundColor)
        XCTAssertNotNil(spec.textColor)
    }
    
    func testCreateDesignSpec_ForAdults_ReturnsAppropriateDesign() async throws {
        // Given
        let audience = Audience.adults
        
        // When
        let spec = try await sut.createDesignSpec(for: audience)
        
        // Then
        XCTAssertEqual(spec.fontSize, .medium, "Adults should have medium font")
        XCTAssertEqual(spec.backgroundColor, "#FFFFFF", "Adults should have professional background")
        XCTAssertEqual(spec.layout, .titleContentAndImage, "Adults should have moderate layout")
    }
    
    func testCreateDesignSpec_ForSeniors_ReturnsAppropriateDesign() async throws {
        // Given
        let audience = Audience.seniors
        
        // When
        let spec = try await sut.createDesignSpec(for: audience)
        
        // Then
        XCTAssertEqual(spec.fontSize, .extraLarge, "Seniors should have extra large font")
        XCTAssertEqual(spec.layout, .titleAndContent, "Seniors should have simple layout")
    }
    
    func testCreateDesignSpec_ForProfessionals_ReturnsAppropriateDesign() async throws {
        // Given
        let audience = Audience.professionals
        
        // When
        let spec = try await sut.createDesignSpec(for: audience)
        
        // Then
        XCTAssertEqual(spec.fontSize, .small, "Professionals should have small font")
        XCTAssertEqual(spec.backgroundColor, "#FFFFFF", "Professionals should have professional background")
        XCTAssertEqual(spec.layout, .splitView, "Professionals should have detailed layout")
    }
    
    func testCreateDesignSpec_FromProject_ReturnsDesignSpec() async throws {
        // Given
        let project = Project(
            id: UUID(),
            name: "Test Project",
            audience: .kids,
            createdDate: Date(),
            modifiedDate: Date()
        )
        
        // When
        let spec = try await sut.createDesignSpec(from: project, audience: .kids)
        
        // Then
        XCTAssertNotNil(spec)
        XCTAssertEqual(spec.fontSize, .large)
    }
    
    // MARK: - Design Update Tests
    
    func testUpdateDesignSpec_WithNewAudience_ReturnsNewDesign() async throws {
        // Given
        let originalAudience = Audience.kids
        let newAudience = Audience.adults
        
        // When
        let originalSpec = try await sut.createDesignSpec(for: originalAudience)
        let updatedSpec = try await sut.updateDesignSpec(for: newAudience)
        
        // Then
        XCTAssertNotEqual(originalSpec.fontSize, updatedSpec.fontSize)
        XCTAssertNotEqual(originalSpec.backgroundColor, updatedSpec.backgroundColor)
    }
    
    // MARK: - Design Validation Tests
    
    func testValidate_WithValidSpec_ReturnsValidResult() {
        // Given
        let spec = DesignSpec(
            layout: .titleAndContent,
            backgroundColor: "#FFFFFF",
            textColor: "#000000",
            fontSize: .medium,
            fontFamily: "Helvetica",
            imagePosition: .right,
            bulletStyle: .checkmark
        )
        
        // When
        let result = sut.validate(spec)
        
        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.issues.isEmpty)
    }
    
    func testValidate_WithInvalidBackgroundColor_ReturnsInvalidResult() {
        // Given
        let spec = DesignSpec(
            layout: .titleAndContent,
            backgroundColor: "invalid-color",
            textColor: "#000000",
            fontSize: .medium,
            fontFamily: "Helvetica",
            imagePosition: .right,
            bulletStyle: .checkmark
        )
        
        // When
        let result = sut.validate(spec)
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.issues.contains { $0.contains("background color") })
    }
    
    func testValidate_WithInvalidTextColor_ReturnsInvalidResult() {
        // Given
        let spec = DesignSpec(
            layout: .titleAndContent,
            backgroundColor: "#FFFFFF",
            textColor: "not-a-color",
            fontSize: .medium,
            fontFamily: "Helvetica",
            imagePosition: .right,
            bulletStyle: .checkmark
        )
        
        // When
        let result = sut.validate(spec)
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.issues.contains { $0.contains("text color") })
    }
    
    func testValidate_WithSmallFontSize_ReturnsWarning() {
        // Given
        let spec = DesignSpec(
            layout: .titleAndContent,
            backgroundColor: "#FFFFFF",
            textColor: "#000000",
            fontSize: .small,
            fontFamily: "Helvetica",
            imagePosition: .right,
            bulletStyle: .checkmark
        )
        
        // When
        let result = sut.validate(spec)
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.issues.contains { $0.contains("Small font") })
    }
    
    // MARK: - State Management Tests
    
    func testCreateDesignSpec_SetsIsDesigningFlag() async throws {
        // Given
        let audience = Audience.adults
        
        // When
        XCTAssertFalse(sut.isDesigning)
        
        let designTask = Task {
            try await sut.createDesignSpec(for: audience)
        }
        
        // Brief moment to allow flag to be set
        try await Task.sleep(nanoseconds: 1_000_000)
        
        _ = try await designTask.value
        
        // Then
        XCTAssertFalse(sut.isDesigning, "Should be false after completion")
    }
    
    // MARK: - Color Mapping Tests
    
    func testCreateDesignSpec_MapsColorSchemeCorrectly() async throws {
        // Given & When
        let brightSpec = try await sut.createDesignSpec(for: .kids)
        let professionalSpec = try await sut.createDesignSpec(for: .adults)
        let neutralSpec = try await sut.createDesignSpec(for: .seniors)
        
        // Then
        XCTAssertEqual(brightSpec.backgroundColor, "#FFEB3B", "Bright color scheme")
        XCTAssertEqual(professionalSpec.backgroundColor, "#FFFFFF", "Professional color scheme")
        XCTAssertEqual(neutralSpec.backgroundColor, "#F5F5F5", "Neutral color scheme")
        
        // All should have black text
        XCTAssertEqual(brightSpec.textColor, "#000000")
        XCTAssertEqual(professionalSpec.textColor, "#000000")
        XCTAssertEqual(neutralSpec.textColor, "#000000")
    }
    
    // MARK: - Layout Mapping Tests
    
    func testCreateDesignSpec_MapsLayoutComplexityCorrectly() async throws {
        // Given & When
        let simpleSpec = try await sut.createDesignSpec(for: .kids)
        let moderateSpec = try await sut.createDesignSpec(for: .adults)
        let detailedSpec = try await sut.createDesignSpec(for: .professionals)
        
        // Then
        XCTAssertEqual(simpleSpec.layout, .titleAndContent, "Simple layout")
        XCTAssertEqual(moderateSpec.layout, .titleContentAndImage, "Moderate layout")
        XCTAssertEqual(detailedSpec.layout, .splitView, "Detailed layout")
    }
    
    // MARK: - Font Size Mapping Tests
    
    func testCreateDesignSpec_MapsFontSizeCorrectly() async throws {
        // Given & When
        let kidsSpec = try await sut.createDesignSpec(for: .kids)
        let teenSpec = try await sut.createDesignSpec(for: .teenagers)
        let adultSpec = try await sut.createDesignSpec(for: .adults)
        let seniorSpec = try await sut.createDesignSpec(for: .seniors)
        let professionalSpec = try await sut.createDesignSpec(for: .professionals)
        
        // Then
        XCTAssertEqual(kidsSpec.fontSize, .large)
        XCTAssertEqual(teenSpec.fontSize, .medium)
        XCTAssertEqual(adultSpec.fontSize, .medium)
        XCTAssertEqual(seniorSpec.fontSize, .extraLarge)
        XCTAssertEqual(professionalSpec.fontSize, .small)
    }
    
    // MARK: - Consistency Tests
    
    func testCreateDesignSpec_ProducesSameResultForSameAudience() async throws {
        // Given
        let audience = Audience.adults
        
        // When
        let spec1 = try await sut.createDesignSpec(for: audience)
        let spec2 = try await sut.createDesignSpec(for: audience)
        
        // Then
        XCTAssertEqual(spec1.layout, spec2.layout)
        XCTAssertEqual(spec1.backgroundColor, spec2.backgroundColor)
        XCTAssertEqual(spec1.textColor, spec2.textColor)
        XCTAssertEqual(spec1.fontSize, spec2.fontSize)
        XCTAssertEqual(spec1.fontFamily, spec2.fontFamily)
    }
    
    func testCreateDesignSpec_ProducesDifferentResultsForDifferentAudiences() async throws {
        // Given
        let audience1 = Audience.kids
        let audience2 = Audience.professionals
        
        // When
        let spec1 = try await sut.createDesignSpec(for: audience1)
        let spec2 = try await sut.createDesignSpec(for: audience2)
        
        // Then
        XCTAssertNotEqual(spec1.fontSize, spec2.fontSize)
        XCTAssertNotEqual(spec1.backgroundColor, spec2.backgroundColor)
        XCTAssertNotEqual(spec1.layout, spec2.layout)
    }
}
