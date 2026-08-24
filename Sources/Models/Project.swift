// ABOUTME: Data models for projects and workstreams.
// ABOUTME: Each project has a directory and multiple workstreams, each with its own terminal.

import Foundation

struct Workstream: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var name: String
    var displayName: String?
    var worktreePath: String?
    var bypassPermissions: Bool
    var lastAccessedAt: Date
    var harness: CodingHarness

    init(name: String, displayName: String? = nil, worktreePath: String? = nil, bypassPermissions: Bool = false, id: UUID = UUID(), lastAccessedAt: Date = Date(), harness: CodingHarness = .claudeCode) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.worktreePath = worktreePath
        self.bypassPermissions = bypassPermissions
        self.lastAccessedAt = lastAccessedAt
        self.harness = harness
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        worktreePath = try container.decodeIfPresent(String.self, forKey: .worktreePath)
        bypassPermissions = try container.decode(Bool.self, forKey: .bypassPermissions)
        lastAccessedAt = try container.decode(Date.self, forKey: .lastAccessedAt)
        // Older persisted blobs predate harness selection; they were all Claude Code.
        harness = try container.decodeIfPresent(CodingHarness.self, forKey: .harness) ?? .claudeCode
    }

    /// The user-facing label. Falls back to the branch-tracked `name` when no override is set.
    var label: String {
        let trimmed = displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, !trimmed.isEmpty { return trimmed }
        return name
    }

    /// The working directory for this workstream's terminals.
    /// Uses the worktree path if available, otherwise falls back to the project directory.
    func workingDirectory(projectDirectory: String) -> String {
        worktreePath ?? projectDirectory
    }

    static func == (lhs: Workstream, rhs: Workstream) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct Project: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var name: String
    var directory: String
    var workstreams: [Workstream]
    var lastAccessedAt: Date
    var spaceID: UUID? = nil

    init(name: String, directory: String, id: UUID = UUID(), workstreams: [Workstream] = [], lastAccessedAt: Date = Date(), spaceID: UUID? = nil) {
        self.id = id
        self.name = name
        self.directory = directory
        self.workstreams = workstreams
        self.lastAccessedAt = lastAccessedAt
        self.spaceID = spaceID
    }

    static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum ProjectSortOrder: String, CaseIterable, Sendable {
    case recent = "Recent"
    case alphabetical = "A-Z"
}
