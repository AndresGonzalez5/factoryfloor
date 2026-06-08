// ABOUTME: Horizontal emoji row at the top of the sidebar that switches the active space.
// ABOUTME: Supports adding, renaming, reordering, and deleting spaces (Zen-browser style).

import AppKit
import SwiftUI

struct SpaceSwitcher: View {
    @Binding var spaces: [Space]
    @Binding var currentSpaceID: String
    @Binding var projects: [Project]
    let onChanged: () -> Void
    let onSpacesChanged: () -> Void

    private enum EditMode: Equatable {
        case add
        case edit(Space)
    }

    @State private var editMode: EditMode?
    @State private var editName = ""
    @State private var editEmoji = ""
    @State private var spaceToDelete: Space?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(spaces) { space in
                    SpaceButton(
                        space: space,
                        isActive: space.id.uuidString == currentSpaceID,
                        onTap: { currentSpaceID = space.id.uuidString }
                    )
                    .contextMenu {
                        Button("Rename Space") { beginEdit(space) }
                        Button("Change Emoji") { beginEdit(space) }
                        Divider()
                        Button("Move Left") { move(space, by: -1) }
                            .disabled(isFirst(space))
                        Button("Move Right") { move(space, by: 1) }
                            .disabled(isLast(space))
                        Divider()
                        Button("Delete Space", role: .destructive) { requestDelete(space) }
                            .disabled(spaces.count <= 1)
                    }
                }

                Button(action: beginAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Add Space")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .sheet(isPresented: Binding(get: { editMode != nil }, set: { if !$0 { editMode = nil } })) {
            SpaceEditSheet(
                title: isAddMode ? "New Space" : "Edit Space",
                name: $editName,
                emoji: $editEmoji,
                onSave: { saveEdit() },
                onCancel: { editMode = nil }
            )
        }
        .confirmationDialog(
            "Move projects to…",
            isPresented: Binding(get: { spaceToDelete != nil }, set: { if !$0 { spaceToDelete = nil } }),
            titleVisibility: .visible
        ) {
            if let space = spaceToDelete {
                ForEach(spaces.filter { $0.id != space.id }) { destination in
                    Button("\(destination.emoji) \(destination.name)") {
                        deleteSpace(space, reassigningTo: destination.id)
                    }
                }
                Button("Cancel", role: .cancel) { spaceToDelete = nil }
            }
        }
    }

    // MARK: - Helpers

    private var isAddMode: Bool {
        if case .add = editMode { return true }
        return false
    }

    private func isFirst(_ space: Space) -> Bool {
        spaces.first?.id == space.id
    }

    private func isLast(_ space: Space) -> Bool {
        spaces.last?.id == space.id
    }

    private func beginAdd() {
        editName = ""
        editEmoji = "🗂️"
        editMode = .add
    }

    private func beginEdit(_ space: Space) {
        editName = space.name
        editEmoji = space.emoji
        editMode = .edit(space)
    }

    private func saveEdit() {
        let trimmedName = editName.trimmingCharacters(in: .whitespacesAndNewlines)
        let emoji = lastGrapheme(editEmoji)
        switch editMode {
        case .add:
            let space = Space(name: trimmedName.isEmpty ? NSLocalizedString("Personal", comment: "") : trimmedName, emoji: emoji.isEmpty ? "🗂️" : emoji)
            spaces.append(space)
            currentSpaceID = space.id.uuidString
            onSpacesChanged()
        case let .edit(space):
            if let index = spaces.firstIndex(where: { $0.id == space.id }) {
                if !trimmedName.isEmpty { spaces[index].name = trimmedName }
                if !emoji.isEmpty { spaces[index].emoji = emoji }
                onSpacesChanged()
            }
        case .none:
            break
        }
        editMode = nil
    }

    private func move(_ space: Space, by offset: Int) {
        guard let index = spaces.firstIndex(where: { $0.id == space.id }) else { return }
        let target = index + offset
        guard spaces.indices.contains(target) else { return }
        spaces.swapAt(index, target)
        onSpacesChanged()
    }

    private func requestDelete(_ space: Space) {
        guard spaces.count > 1 else { return }
        let hasProjects = projects.contains { $0.spaceID == space.id }
        if hasProjects {
            spaceToDelete = space
        } else {
            deleteSpace(space, reassigningTo: nil)
        }
    }

    private func deleteSpace(_ space: Space, reassigningTo destinationID: UUID?) {
        if let destinationID {
            var changed = false
            for index in projects.indices where projects[index].spaceID == space.id {
                projects[index].spaceID = destinationID
                changed = true
            }
            if changed { onChanged() }
        }
        spaces.removeAll { $0.id == space.id }
        onSpacesChanged()
        if currentSpaceID == space.id.uuidString, let first = spaces.first {
            currentSpaceID = first.id.uuidString
        }
        spaceToDelete = nil
    }

    /// Keeps the last grapheme cluster so a single emoji survives even if the
    /// palette or typing inserts multiple characters.
    private func lastGrapheme(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let last = trimmed.last else { return "" }
        return String(last)
    }
}

private struct SpaceButton: View {
    let space: Space
    let isActive: Bool
    let onTap: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onTap) {
            Text(space.emoji)
                .font(.system(size: 16))
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isActive ? Color.accentColor.opacity(0.2) : (isHovering ? Color.primary.opacity(0.06) : .clear))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(isActive ? Color.accentColor : .clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.borderless)
        .onHover { isHovering = $0 }
        .help(space.name)
        .accessibilityLabel(space.name)
    }
}

extension Character {
    /// Whether this grapheme reads as an emoji (so the space icon field rejects
    /// plain letters/digits/punctuation).
    var isEmojiLike: Bool {
        unicodeScalars.contains { $0.properties.isEmojiPresentation || ($0.properties.isEmoji && $0.value > 0x238C) }
    }
}

private struct SpaceEditSheet: View {
    let title: LocalizedStringKey
    @Binding var name: String
    @Binding var emoji: String
    let onSave: () -> Void
    let onCancel: () -> Void

    /// Last accepted emoji; used to revert if the user types a non-emoji.
    @State private var lastValidEmoji = ""

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.headline)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Emoji")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button {
                        NSApp.orderFrontCharacterPalette(nil)
                    } label: {
                        Text(emoji.isEmpty ? "🗂️" : emoji)
                            .font(.system(size: 22))
                            .frame(width: 44, height: 44)
                            .background(Color.primary.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.borderless)
                    TextField("", text: $emoji)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 44)
                        .multilineTextAlignment(.center)
                        .onAppear { lastValidEmoji = emoji }
                        .onChange(of: emoji) { _, newValue in
                            // Keep only the last grapheme if it's an emoji; revert
                            // to the previous valid emoji otherwise (e.g. "abc" → c
                            // would be a letter, so it's rejected).
                            if let last = newValue.last, last.isEmojiLike {
                                let normalized = String(last)
                                lastValidEmoji = normalized
                                if emoji != normalized { emoji = normalized }
                            } else if !newValue.isEmpty {
                                emoji = lastValidEmoji
                            }
                        }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Name")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { onSave() }
                }
            }

            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save", action: onSave)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 340)
    }
}
