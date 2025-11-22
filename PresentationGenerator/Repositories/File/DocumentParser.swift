import Foundation
import UniformTypeIdentifiers

/// Parser for extracting text from various document formats
class DocumentParser {
    private let fileManager: FileManager
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    // MARK: - Public Methods
    
    func parse(_ url: URL) async throws -> String {
        guard fileManager.fileExists(atPath: url.path) else {
            throw AppError.fileImportError(
                NSError(domain: "DocumentParser", code: 404, userInfo: [
                    NSLocalizedDescriptionKey: "File not found at \(url.path)"
                ])
            )
        }
        
        // Check file size
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        guard let fileSize = attributes[.size] as? Int64 else {
            throw AppError.fileImportError(
                NSError(domain: "DocumentParser", code: 500, userInfo: [
                    NSLocalizedDescriptionKey: "Could not determine file size"
                ])
            )
        }
        
        guard fileSize <= AppConstants.maxFileSize else {
            throw AppError.fileImportError(
                NSError(domain: "DocumentParser", code: 413, userInfo: [
                    NSLocalizedDescriptionKey: "File size exceeds maximum allowed size"
                ])
            )
        }
        
        // Determine file type and parse accordingly
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "txt":
            return try await parsePlainText(from: url)
        case "rtf":
            return try await parseRTF(from: url)
        case "doc", "docx":
            return try await parseWordDocument(from: url)
        default:
            throw AppError.invalidFileFormat(fileExtension)
        }
    }
    
    // MARK: - Private Parsing Methods
    
    private func parsePlainText(from url: URL) async throws -> String {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            return cleanText(content)
        } catch {
            Logger.shared.error("Failed to parse plain text file", error: error, category: .fileImport)
            throw AppError.fileImportError(error)
        }
    }
    
    private func parseRTF(from url: URL) async throws -> String {
        do {
            guard let attributedString = try? NSAttributedString(
                url: url,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
            ) else {
                throw AppError.fileImportError(
                    NSError(domain: "DocumentParser", code: 500, userInfo: [
                        NSLocalizedDescriptionKey: "Failed to parse RTF document"
                    ])
                )
            }
            
            return cleanText(attributedString.string)
        } catch {
            Logger.shared.error("Failed to parse RTF file", error: error, category: .fileImport)
            throw AppError.fileImportError(error)
        }
    }
    
    private func parseWordDocument(from url: URL) async throws -> String {
        // For Word documents, we'll use NSAttributedString which can handle .doc and .docx on macOS
        do {
            // Try to read as Word document
            guard let attributedString = try? NSAttributedString(
                url: url,
                options: [.documentType: NSAttributedString.DocumentType.docFormat],
                documentAttributes: nil
            ) else {
                // If that fails, try as DOCX
                guard let docxString = try? NSAttributedString(
                    url: url,
                    options: [.documentType: NSAttributedString.DocumentType.officeOpenXML],
                    documentAttributes: nil
                ) else {
                    throw AppError.fileImportError(
                        NSError(domain: "DocumentParser", code: 500, userInfo: [
                            NSLocalizedDescriptionKey: "Failed to parse Word document. The file may be corrupted or in an unsupported format."
                        ])
                    )
                }
                return cleanText(docxString.string)
            }
            
            return cleanText(attributedString.string)
        } catch {
            Logger.shared.error("Failed to parse Word document", error: error, category: .fileImport)
            throw AppError.fileImportError(error)
        }
    }
    
    // MARK: - Text Cleaning
    
    private func cleanText(_ text: String) -> String {
        var cleaned = text
        
        // Remove excessive whitespace
        cleaned = cleaned.condensedWhitespace
        
        // Remove excessive newlines (more than 2 consecutive)
        cleaned = cleaned.replacingOccurrences(
            of: "\n{3,}",
            with: "\n\n",
            options: .regularExpression
        )
        
        // Trim whitespace from start and end
        cleaned = cleaned.trimmed
        
        // Remove zero-width characters and other invisible characters
        cleaned = cleaned.replacingOccurrences(
            of: "[\u{200B}-\u{200D}\u{FEFF}]",
            with: "",
            options: .regularExpression
        )
        
        return cleaned
    }
    
    // MARK: - Validation
    
    func validate(text: String) throws {
        guard text.count >= AppConstants.minTextLength else {
            throw AppError.insufficientContent
        }
        
        guard text.count <= AppConstants.maxTextLength else {
            throw AppError.fileImportError(
                NSError(domain: "DocumentParser", code: 413, userInfo: [
                    NSLocalizedDescriptionKey: "Document content exceeds maximum allowed length"
                ])
            )
        }
    }
    
    // MARK: - Helper Methods
    
    func extractMetadata(from url: URL) throws -> [String: Any] {
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        
        return [
            "filename": url.lastPathComponent,
            "size": attributes[.size] as? Int64 ?? 0,
            "creationDate": attributes[.creationDate] as? Date ?? Date(),
            "modificationDate": attributes[.modificationDate] as? Date ?? Date(),
            "type": url.pathExtension
        ]
    }
}
