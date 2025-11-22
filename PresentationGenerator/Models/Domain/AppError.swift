import Foundation

/// Application-wide error types
enum AppError: LocalizedError {
    case apiKeyInvalid
    case apiKeyNotFound
    case networkError(Error)
    case openAIError(String)
    case fileImportError(Error)
    case exportError(Error)
    case contentFilterViolation(String)
    case projectNotFound(UUID)
    case projectSaveError(Error)
    case projectLoadError(Error)
    case invalidProjectData
    case invalidFileFormat(String)
    case insufficientContent
    case generationCancelled
    case imageProcessingError(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .apiKeyInvalid:
            return "The OpenAI API key is invalid. Please check your key and try again."
        case .apiKeyNotFound:
            return "No API key found. Please enter your OpenAI API key in settings."
        case .networkError(let error):
            return "Network error occurred: \(error.localizedDescription)"
        case .openAIError(let message):
            return "OpenAI API error: \(message)"
        case .fileImportError(let error):
            return "Failed to import file: \(error.localizedDescription)"
        case .exportError(let error):
            return "Failed to export presentation: \(error.localizedDescription)"
        case .contentFilterViolation(let reason):
            return "Content filter violation: \(reason)"
        case .projectNotFound(let id):
            return "Project with ID \(id) not found."
        case .projectSaveError(let error):
            return "Failed to save project: \(error.localizedDescription)"
        case .projectLoadError(let error):
            return "Failed to load project: \(error.localizedDescription)"
        case .invalidProjectData:
            return "Project data is corrupted or invalid."
        case .invalidFileFormat(let format):
            return "Invalid or unsupported file format: \(format)"
        case .insufficientContent:
            return "Not enough content to generate slides. Please import more text."
        case .generationCancelled:
            return "Slide generation was cancelled."
        case .imageProcessingError(let message):
            return "Image processing error: \(message)"
        case .unknownError(let message):
            return "An unknown error occurred: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .apiKeyInvalid, .apiKeyNotFound:
            return "Go to Settings and enter a valid OpenAI API key."
        case .networkError:
            return "Check your internet connection and try again."
        case .openAIError:
            return "This might be a temporary issue with OpenAI's service. Please try again later."
        case .fileImportError:
            return "Make sure the file is not corrupted and is a supported format (.doc, .docx)."
        case .exportError:
            return "Check that you have write permissions to the destination folder."
        case .contentFilterViolation:
            return "Please review your content to ensure it's appropriate."
        case .projectNotFound:
            return "The project may have been deleted. Try creating a new project."
        case .projectSaveError, .projectLoadError:
            return "Check available disk space and file permissions."
        case .invalidProjectData:
            return "Try recreating the project from scratch."
        case .invalidFileFormat:
            return "Please use .doc or .docx files."
        case .insufficientContent:
            return "Import additional documents or add more content to existing ones."
        case .generationCancelled:
            return "You can restart the generation process when ready."
        case .imageProcessingError:
            return "Try regenerating the image or uploading a custom one."
        case .unknownError:
            return "Please try again or contact support if the issue persists."
        }
    }
    
    var failureReason: String? {
        switch self {
        case .apiKeyInvalid:
            return "The provided API key was rejected by OpenAI."
        case .apiKeyNotFound:
            return "No API key has been stored in the system."
        case .networkError:
            return "Unable to connect to the server."
        case .openAIError:
            return "The OpenAI service returned an error."
        case .fileImportError:
            return "The file could not be read or parsed."
        case .exportError:
            return "The PowerPoint file could not be created."
        case .contentFilterViolation:
            return "The content did not pass the appropriateness filter."
        case .projectNotFound:
            return "The project does not exist in storage."
        case .projectSaveError:
            return "The project could not be written to disk."
        case .projectLoadError:
            return "The project file could not be read."
        case .invalidProjectData:
            return "The project data structure is invalid."
        case .invalidFileFormat:
            return "The file format is not supported."
        case .insufficientContent:
            return "Not enough text to create meaningful slides."
        case .generationCancelled:
            return "User cancelled the operation."
        case .imageProcessingError:
            return "The image could not be processed."
        case .unknownError:
            return "An unexpected error occurred."
        }
    }
}
