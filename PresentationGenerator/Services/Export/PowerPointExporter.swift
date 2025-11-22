//
//  PowerPointExporter.swift
//  PresentationGenerator
//
//  Exports presentations to PowerPoint (.pptx) format
//

import Foundation
import AppKit

/// Service for exporting presentations to PowerPoint format
@MainActor
class PowerPointExporter: ObservableObject, PowerPointExporterProtocol {
    private let slideRenderer: SlideRenderer
    
    @Published var isExporting = false
    @Published var exportProgress: Double = 0.0
    @Published var lastError: Error?
    
    // MARK: - Initialization
    
    init(slideRenderer: SlideRenderer) {
        self.slideRenderer = slideRenderer
    }
    
    // MARK: - Export
    
    /// Exports a project to PowerPoint format (Protocol conformance)
    /// - Parameters:
    ///   - project: Project to export
    ///   - url: Output file URL
    func export(project: Project, to url: URL) async throws {
        try await exportPresentation(
            slides: project.slides,
            title: project.name,
            to: url,
            progressCallback: nil
        )
    }
    
    /// Exports a presentation to PowerPoint format
    /// - Parameters:
    ///   - slides: Slides to export
    ///   - title: Presentation title
    ///   - outputURL: Output file URL
    ///   - progressCallback: Progress callback (current, total)
    func exportPresentation(
        slides: [Slide],
        title: String,
        to outputURL: URL,
        progressCallback: ((Int, Int) -> Void)? = nil
    ) async throws {
        isExporting = true
        exportProgress = 0.0
        defer { 
            isExporting = false
            exportProgress = 0.0
        }
        
        Logger.shared.info("Exporting presentation '\(title)' with \(slides.count) slides", category: .export)
        
        do {
            // Create temporary directory for PPTX structure
            let tempDir = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            defer {
                try? FileManager.default.removeItem(at: tempDir)
            }
            
            // Create PPTX structure
            try createPPTXStructure(
                slides: slides,
                title: title,
                at: tempDir,
                progressCallback: { current, total in
                    self.exportProgress = Double(current) / Double(total)
                    progressCallback?(current, total)
                }
            )
            
            // Create ZIP archive
            try createZIPArchive(from: tempDir, to: outputURL)
            
            Logger.shared.info("Presentation exported successfully to \(outputURL.path)", category: .export)
            
        } catch {
            let appError = error as? AppError ?? AppError.exportError(error)
            lastError = appError
            Logger.shared.error("Presentation export failed", error: error, category: .export)
            throw appError
        }
    }
    
    // MARK: - PPTX Structure Creation
    
    private func createPPTXStructure(
        slides: [Slide],
        title: String,
        at baseURL: URL,
        progressCallback: ((Int, Int) -> Void)?
    ) throws {
        let totalSteps = slides.count + 5 // slides + structure files
        var currentStep = 0
        
        // Create [Content_Types].xml
        try createContentTypesXML(slideCount: slides.count)
            .write(to: baseURL.appendingPathComponent("[Content_Types].xml"), atomically: true, encoding: .utf8)
        currentStep += 1
        progressCallback?(currentStep, totalSteps)
        
        // Create _rels/.rels
        let relsDir = baseURL.appendingPathComponent("_rels")
        try FileManager.default.createDirectory(at: relsDir, withIntermediateDirectories: true)
        try createRelsXML()
            .write(to: relsDir.appendingPathComponent(".rels"), atomically: true, encoding: .utf8)
        currentStep += 1
        progressCallback?(currentStep, totalSteps)
        
        // Create ppt folder structure
        let pptDir = baseURL.appendingPathComponent("ppt")
        try FileManager.default.createDirectory(at: pptDir, withIntermediateDirectories: true)
        
        // Create ppt/_rels/presentation.xml.rels
        let pptRelsDir = pptDir.appendingPathComponent("_rels")
        try FileManager.default.createDirectory(at: pptRelsDir, withIntermediateDirectories: true)
        try createPresentationRelsXML(slideCount: slides.count)
            .write(to: pptRelsDir.appendingPathComponent("presentation.xml.rels"), atomically: true, encoding: .utf8)
        currentStep += 1
        progressCallback?(currentStep, totalSteps)
        
        // Create ppt/presentation.xml
        try createPresentationXML(slides: slides, title: title)
            .write(to: pptDir.appendingPathComponent("presentation.xml"), atomically: true, encoding: .utf8)
        currentStep += 1
        progressCallback?(currentStep, totalSteps)
        
        // Create slides
        let slidesDir = pptDir.appendingPathComponent("slides")
        try FileManager.default.createDirectory(at: slidesDir, withIntermediateDirectories: true)
        
        let slideRelsDir = slidesDir.appendingPathComponent("_rels")
        try FileManager.default.createDirectory(at: slideRelsDir, withIntermediateDirectories: true)
        
        let mediaDir = pptDir.appendingPathComponent("media")
        try FileManager.default.createDirectory(at: mediaDir, withIntermediateDirectories: true)
        
        for (index, slide) in slides.enumerated() {
            // Create slide XML
            let slideXML = try createSlideXML(slide: slide, slideNumber: index + 1)
            try slideXML.write(
                to: slidesDir.appendingPathComponent("slide\(index + 1).xml"),
                atomically: true,
                encoding: .utf8
            )
            
            // Create slide relationships
            let slideRelsXML = createSlideRelsXML(hasImage: slide.imageData != nil)
            try slideRelsXML.write(
                to: slideRelsDir.appendingPathComponent("slide\(index + 1).xml.rels"),
                atomically: true,
                encoding: .utf8
            )
            
            // Save image if present
            if let imageData = slide.imageData, let localURL = imageData.localURL {
                let destURL = mediaDir.appendingPathComponent("image\(index + 1).png")
                try FileManager.default.copyItem(at: localURL, to: destURL)
            }
            
            currentStep += 1
            progressCallback?(currentStep, totalSteps)
        }
        
        currentStep += 1
        progressCallback?(currentStep, totalSteps)
    }
    
    // MARK: - XML Generation
    
    private func createContentTypesXML(slideCount: Int) -> String {
        var slideOverrides = ""
        for i in 1...slideCount {
            slideOverrides += """
                <Override PartName="/ppt/slides/slide\(i).xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>
            """
        }
        
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
            <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
            <Default Extension="xml" ContentType="application/xml"/>
            <Default Extension="png" ContentType="image/png"/>
            <Default Extension="jpeg" ContentType="image/jpeg"/>
            <Default Extension="jpg" ContentType="image/jpeg"/>
            <Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>
            \(slideOverrides)
        </Types>
        """
    }
    
    private func createRelsXML() -> String {
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
            <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>
        </Relationships>
        """
    }
    
    private func createPresentationRelsXML(slideCount: Int) -> String {
        var slideRels = ""
        for i in 1...slideCount {
            slideRels += """
                <Relationship Id="rId\(i)" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide\(i).xml"/>
            """
        }
        
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
            \(slideRels)
        </Relationships>
        """
    }
    
    private func createPresentationXML(slides: [Slide], title: String) -> String {
        var slideIdList = ""
        for i in 1...slides.count {
            slideIdList += """
                <p:sldId id="\(255 + i)" r:id="rId\(i)"/>
            """
        }
        
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <p:presentation xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
            <p:sldSz cx="9144000" cy="6858000"/>
            <p:notesSz cx="6858000" cy="9144000"/>
            <p:sldIdLst>
                \(slideIdList)
            </p:sldIdLst>
        </p:presentation>
        """
    }
    
    private func createSlideXML(slide: Slide, slideNumber: Int) throws -> String {
        let bgColor = slide.designSpec.backgroundColor
        let textColor = slide.designSpec.textColor
        
        // Title
        let titleXML = """
            <p:sp>
                <p:nvSpPr>
                    <p:cNvPr id="2" name="Title"/>
                    <p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr>
                    <p:nvPr><p:ph type="title"/></p:nvPr>
                </p:nvSpPr>
                <p:spPr/>
                <p:txBody>
                    <a:bodyPr/>
                    <a:lstStyle/>
                    <a:p>
                        <a:r>
                            <a:rPr sz="\(titleFontSize(slide.designSpec.fontSize))" b="1">
                                <a:solidFill><a:srgbClr val="\(textColor)"/></a:solidFill>
                            </a:rPr>
                            <a:t>\(xmlEscape(slide.title))</a:t>
                        </a:r>
                    </a:p>
                </p:txBody>
            </p:sp>
        """
        
        // Content bullets
        let contentLines = slide.content.components(separatedBy: "\n").filter { !$0.isEmpty }
        var bulletsXML = ""
        for line in contentLines {
            let bulletStyle = slide.designSpec.bulletStyle ?? .disc
            bulletsXML += """
                <a:p>
                    <a:pPr lvl="0" marL="342900" indent="-342900">
                        <a:buFont typeface="\(bulletFont(bulletStyle))"/>
                        <a:buChar char="\(bulletChar(bulletStyle))"/>
                    </a:pPr>
                    <a:r>
                        <a:rPr sz="\(contentFontSize(slide.designSpec.fontSize))">
                            <a:solidFill><a:srgbClr val="\(textColor)"/></a:solidFill>
                        </a:rPr>
                        <a:t>\(xmlEscape(line))</a:t>
                    </a:r>
                </a:p>
            """
        }
        
        let contentXML = """
            <p:sp>
                <p:nvSpPr>
                    <p:cNvPr id="3" name="Content"/>
                    <p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr>
                    <p:nvPr><p:ph type="body" idx="1"/></p:nvPr>
                </p:nvSpPr>
                <p:spPr/>
                <p:txBody>
                    <a:bodyPr/>
                    <a:lstStyle/>
                    \(bulletsXML)
                </p:txBody>
            </p:sp>
        """
        
        // Image (if present)
        let imageXML: String
        if slide.imageData != nil {
            imageXML = """
                <p:pic>
                    <p:nvPicPr>
                        <p:cNvPr id="4" name="Picture"/>
                        <p:cNvPicPr><a:picLocks noChangeAspect="1"/></p:cNvPicPr>
                        <p:nvPr/>
                    </p:nvPicPr>
                    <p:blipFill>
                        <a:blip r:embed="rId2"/>
                        <a:stretch><a:fillRect/></a:stretch>
                    </p:blipFill>
                    <p:spPr>
                        <a:xfrm>
                            <a:off x="4572000" y="1828800"/>
                            <a:ext cx="3657600" cy="2743200"/>
                        </a:xfrm>
                        <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
                    </p:spPr>
                </p:pic>
            """
        } else {
            imageXML = ""
        }
        
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
            <p:cSld>
                <p:bg>
                    <p:bgPr>
                        <a:solidFill><a:srgbClr val="\(bgColor)"/></a:solidFill>
                    </p:bgPr>
                </p:bg>
                <p:spTree>
                    <p:nvGrpSpPr>
                        <p:cNvPr id="1" name=""/>
                        <p:cNvGrpSpPr/>
                        <p:nvPr/>
                    </p:nvGrpSpPr>
                    <p:grpSpPr>
                        <a:xfrm>
                            <a:off x="0" y="0"/>
                            <a:ext cx="0" cy="0"/>
                            <a:chOff x="0" y="0"/>
                            <a:chExt cx="0" cy="0"/>
                        </a:xfrm>
                    </p:grpSpPr>
                    \(titleXML)
                    \(contentXML)
                    \(imageXML)
                </p:spTree>
            </p:cSld>
        </p:sld>
        """
    }
    
    private func createSlideRelsXML(hasImage: Bool) -> String {
        let imageRel = hasImage ? """
            <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="../media/image1.png"/>
        """ : ""
        
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
            \(imageRel)
        </Relationships>
        """
    }
    
    // MARK: - ZIP Creation
    
    private func createZIPArchive(from sourceURL: URL, to destinationURL: URL) throws {
        // Use system zip command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.arguments = ["-r", "-X", destinationURL.path, "."]
        process.currentDirectoryURL = sourceURL
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AppError.unknownError("ZIP creation failed: \(output)")
        }
    }
    
    // MARK: - Helpers
    
    private func titleFontSize(_ fontSize: FontSizeSpec) -> Int {
        switch fontSize {
        case .small: return 3200  // 32pt
        case .medium: return 4400 // 44pt
        case .large: return 5600  // 56pt
        case .extraLarge: return 7200 // 72pt
        }
    }
    
    private func contentFontSize(_ fontSize: FontSizeSpec) -> Int {
        switch fontSize {
        case .small: return 1800  // 18pt
        case .medium: return 2400 // 24pt
        case .large: return 2800  // 28pt
        case .extraLarge: return 3200 // 32pt
        }
    }
    
    private func bulletChar(_ style: BulletStyle) -> String {
        switch style {
        case .disc: return "●"
        case .circle: return "○"
        case .square: return "■"
        case .dash: return "–"
        case .arrow: return "→"
        case .checkmark: return "✓"
        }
    }
    
    private func bulletFont(_ style: BulletStyle) -> String {
        return "Arial"
    }
    
    private func xmlEscape(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
