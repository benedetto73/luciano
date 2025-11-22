//
//  AutoSaveManager.swift
//  PresentationGenerator
//
//  Manages auto-save functionality for ViewModels
//

import Foundation
import Combine

/// Manages auto-save functionality with debouncing
@MainActor
class AutoSaveManager: ObservableObject {
    private var saveTask: Task<Void, Never>?
    private let debounceInterval: TimeInterval
    
    /// Callback to execute when auto-save is triggered
    var saveAction: (() async -> Void)?
    
    init(debounceInterval: TimeInterval = 2.0) {
        self.debounceInterval = debounceInterval
    }
    
    /// Schedules an auto-save operation
    /// Cancels any pending save and schedules a new one after the debounce interval
    func scheduleSave() {
        // Cancel any existing save task
        saveTask?.cancel()
        
        // Schedule new save after debounce interval
        saveTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(debounceInterval * 1_000_000_000))
            
            guard !Task.isCancelled else { return }
            
            Logger.shared.debug("Auto-save triggered", category: .business)
            await saveAction?()
        }
    }
    
    /// Immediately executes a save operation
    /// Cancels any pending debounced save
    func saveNow() async {
        saveTask?.cancel()
        await saveAction?()
    }
    
    /// Cancels any pending save operation
    func cancel() {
        saveTask?.cancel()
        saveTask = nil
    }
    
    deinit {
        saveTask?.cancel()
    }
}

// MARK: - Publisher Extension for Auto-Save

extension Published.Publisher {
    /// Triggers auto-save when the published value changes
    /// - Parameters:
    ///   - autoSaveManager: The auto-save manager to use
    ///   - debounceInterval: How long to wait before saving (default: 2 seconds)
    /// - Returns: A publisher that triggers auto-save
    func autoSave(
        using autoSaveManager: AutoSaveManager,
        debounceInterval: TimeInterval = 2.0
    ) -> AnyPublisher<Output, Failure> {
        self
            .debounce(for: .seconds(debounceInterval), scheduler: RunLoop.main)
            .handleEvents(receiveOutput: { _ in
                Task { @MainActor in
                    autoSaveManager.scheduleSave()
                }
            })
            .eraseToAnyPublisher()
    }
}
