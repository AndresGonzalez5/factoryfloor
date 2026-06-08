// ABOUTME: Data model for spaces, which group projects (like Zen browser spaces).
// ABOUTME: Each project belongs to exactly one space; spaces persist to UserDefaults as JSON.

import Foundation

struct Space: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var name: String
    var emoji: String

    init(name: String, emoji: String, id: UUID = UUID()) {
        self.id = id
        self.name = name
        self.emoji = emoji
    }

    static func == (lhs: Space, rhs: Space) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum SpaceStore {
    private static let userDefaultsKey = "factoryfloor.spaces"

    static func load(defaults: UserDefaults = .standard) -> [Space] {
        guard let data = defaults.data(forKey: userDefaultsKey),
              let spaces = try? JSONDecoder().decode([Space].self, from: data)
        else { return [] }
        return spaces
    }

    static func save(_ spaces: [Space], defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(spaces) else { return }
        defaults.set(data, forKey: userDefaultsKey)
    }
}

/// One-shot migration that must run before any view renders so the sidebar's
/// first paint already sees migrated data. Operates directly on UserDefaults
/// via the static stores. Idempotent and safe to call on every launch.
enum SpacesBootstrap {
    static let currentSpaceKey = "factoryfloor.currentSpace"

    static func migrateIfNeeded(defaults: UserDefaults = .standard) {
        var spaces = SpaceStore.load(defaults: defaults)
        if spaces.isEmpty {
            spaces = [Space(name: NSLocalizedString("Personal", comment: ""), emoji: "🗂️")]
            SpaceStore.save(spaces, defaults: defaults)
        }

        let defaultSpaceID = spaces[0].id
        let validIDs = Set(spaces.map(\.id))

        var projects = ProjectStore.load(defaults: defaults)
        var changed = false
        for index in projects.indices {
            let current = projects[index].spaceID
            if current == nil || !validIDs.contains(current!) {
                projects[index].spaceID = defaultSpaceID
                changed = true
            }
        }
        if changed {
            ProjectStore.save(projects, defaults: defaults)
        }

        let currentSpaceID = defaults.string(forKey: currentSpaceKey) ?? ""
        if let uuid = UUID(uuidString: currentSpaceID), validIDs.contains(uuid) {
            // Already valid.
        } else {
            defaults.set(defaultSpaceID.uuidString, forKey: currentSpaceKey)
        }
    }
}
