// ABOUTME: Routes hook events to per-project handlers.
// ABOUTME: Maps normalized project directory paths to event handler callbacks.

import Foundation
import os

private let logger = Logger(subsystem: "factoryfloor", category: "hook-router")

/// Routes `AgentEvent`s from the `HookEventReceiver` to registered handlers.
///
/// Handlers are keyed by normalized project directory. When a hook event
/// arrives, the router normalizes the path and dispatches to the matching
/// handler on the main queue.
///
/// Thread safety: protected by `NSLock`.
final class HookEventRouter: @unchecked Sendable {

    static let shared = HookEventRouter()

    private let lock = NSLock()
    private var handlers: [String: (AgentEvent) -> Void] = [:]

    private init() {}

    // MARK: - Registration

    /// Register a handler for a project directory.
    func register(projectDir: String, handler: @escaping (AgentEvent) -> Void) {
        let normalized = Self.normalizePath(projectDir)
        lock.lock()
        handlers[normalized] = handler
        lock.unlock()
        logger.info("Registered hook handler for: \(normalized, privacy: .public)")
    }

    /// Unregister the handler for a project directory.
    func unregister(projectDir: String) {
        let normalized = Self.normalizePath(projectDir)
        lock.lock()
        handlers.removeValue(forKey: normalized)
        lock.unlock()
        logger.info("Unregistered hook handler for: \(normalized, privacy: .public)")
    }

    // MARK: - Routing

    /// Route an event to the handler for the given project directory.
    /// Must be called from the main queue.
    func route(projectDir: String, event: AgentEvent) {
        let normalized = Self.normalizePath(projectDir)
        lock.lock()
        let handler = handlers[normalized]
        lock.unlock()

        if let handler {
            handler(event)
        } else {
            logger.info("No handler for project: \(normalized, privacy: .public)")
        }
    }

    // MARK: - Path Normalization

    static func normalizePath(_ path: String) -> String {
        URL(fileURLWithPath: path).standardized.path
    }
}
