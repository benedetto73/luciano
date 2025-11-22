//
//  WorkflowPhase.swift
//  PresentationGenerator
//
//  Workflow phase enumeration for workspace UI
//

import Foundation

enum WorkflowPhase: String, CaseIterable, Codable {
    case importPhase = "import"
    case analyze
    case generate
    case edit
    case preview
    case exportPhase = "export"
    
    var title: String {
        switch self {
        case .importPhase: return "Import"
        case .analyze: return "Analyze"
        case .generate: return "Generate"
        case .edit: return "Edit"
        case .preview: return "Preview"
        case .exportPhase: return "Export"
        }
    }
    
    var icon: String {
        switch self {
        case .importPhase: return "doc.badge.plus"
        case .analyze: return "sparkles"
        case .generate: return "wand.and.stars"
        case .edit: return "pencil.and.list.clipboard"
        case .preview: return "play.rectangle"
        case .exportPhase: return "square.and.arrow.down"
        }
    }
    
    var description: String {
        switch self {
        case .importPhase: return "Add source files"
        case .analyze: return "Extract key points"
        case .generate: return "Create slides"
        case .edit: return "Customize content"
        case .preview: return "Review presentation"
        case .exportPhase: return "Export to PowerPoint"
        }
    }
    
    var keyboardShortcut: String {
        switch self {
        case .importPhase: return "1"
        case .analyze: return "2"
        case .generate: return "3"
        case .edit: return "4"
        case .preview: return "5"
        case .exportPhase: return "6"
        }
    }
}
