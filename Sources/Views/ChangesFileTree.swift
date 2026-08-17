// ABOUTME: Pure file-tree model + builder for the Changes tab "Files changed" sidebar.
// ABOUTME: Turns a flat [DiffFile] into a sorted, fully-nested directory tree (dirs before files).

import SwiftUI

/// A node in the Changes "Files changed" tree. Directories carry `children`;
/// leaves carry the associated `DiffFile`. `id` is the full slash-joined path so
/// it is stable across rebuilds and unique within the tree.
struct FileTreeNode: Identifiable, Equatable {
    /// Full path from the tree root (e.g. "Sources/Models/Git.swift"). For the
    /// synthetic root node this is the empty string.
    let id: String
    /// Last path component (the display name). Empty for the synthetic root.
    let name: String
    let isDirectory: Bool
    /// Child nodes for directories; nil for leaves.
    let children: [FileTreeNode]?
    /// The changed file for leaves; nil for directories and the root.
    let diffFile: DiffFile?

    /// Build a sorted, fully-nested tree from a flat list of changed files.
    ///
    /// Sort order at every level: directories before files, each alphabetical
    /// (case-insensitive). The returned node is a synthetic root whose
    /// `children` are the top-level entries.
    static func build(from files: [DiffFile]) -> FileTreeNode {
        // Mutable builder mirror of the immutable node, assembled bottom-up.
        final class Builder {
            let name: String
            let path: String
            var children: [String: Builder] = [:]
            var diffFile: DiffFile?

            init(name: String, path: String) {
                self.name = name
                self.path = path
            }

            var isDirectory: Bool { diffFile == nil }
        }

        let root = Builder(name: "", path: "")

        for file in files {
            let components = file.relativePath
                .split(separator: "/", omittingEmptySubsequences: true)
                .map(String.init)
            guard !components.isEmpty else { continue }

            var node = root
            var prefix = ""
            for (index, component) in components.enumerated() {
                prefix = prefix.isEmpty ? component : "\(prefix)/\(component)"
                if let existing = node.children[component] {
                    node = existing
                } else {
                    let child = Builder(name: component, path: prefix)
                    node.children[component] = child
                    node = child
                }
                // The final component is the leaf — attach the file.
                if index == components.count - 1 {
                    node.diffFile = file
                }
            }
        }

        func freeze(_ builder: Builder) -> FileTreeNode {
            if builder.isDirectory {
                let sorted = builder.children.values
                    .map(freeze)
                    .sorted(by: order)
                return FileTreeNode(
                    id: builder.path,
                    name: builder.name,
                    isDirectory: true,
                    children: sorted,
                    diffFile: nil
                )
            }
            return FileTreeNode(
                id: builder.path,
                name: builder.name,
                isDirectory: false,
                children: nil,
                diffFile: builder.diffFile
            )
        }

        return freeze(root)
    }

    /// Sort comparator: directories before files, then alphabetical case-insensitive.
    private static func order(_ lhs: FileTreeNode, _ rhs: FileTreeNode) -> Bool {
        if lhs.isDirectory != rhs.isDirectory {
            return lhs.isDirectory && !rhs.isDirectory
        }
        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }
}

// MARK: - Sidebar view

/// GitHub-PR-style "Files changed" navigator for the Changes tab. Renders the
/// tree built from `files` as a collapsible outline; selecting a leaf invokes
/// `onSelect` with its relative path (the diff webview scrolls to that block).
struct ChangesFileTreeSidebar: View {
    let files: [DiffFile]
    @Binding var selectedFilePath: String?
    let onSelect: (String) -> Void

    private var rootChildren: [FileTreeNode] {
        FileTreeNode.build(from: files).children ?? []
    }

    var body: some View {
        List(selection: $selectedFilePath) {
            Section {
                ForEach(rootChildren) { node in
                    ChangesFileTreeRow(node: node)
                }
            } header: {
                Text("Files changed")
            }
        }
        .listStyle(.sidebar)
        .accessibilityLabel(Text("Files changed"))
        // Selection drives the scroll — works for both mouse clicks and keyboard
        // navigation. Skipped when selection is cleared (mode switch / reload).
        .onChange(of: selectedFilePath) { _, newValue in
            if let newValue { onSelect(newValue) }
        }
    }
}

/// One row in the file tree. Directories render a `DisclosureGroup` over their
/// children; leaves render a selectable file row with a status badge and counts.
private struct ChangesFileTreeRow: View {
    let node: FileTreeNode
    // Directories start expanded so the tree shows files all the way down on
    // load (no clicking through each level). Users can still collapse manually.
    @State private var isExpanded = true

    var body: some View {
        if node.isDirectory {
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(node.children ?? []) { child in
                    ChangesFileTreeRow(node: child)
                }
            } label: {
                Label {
                    Text(node.name).lineLimit(1).truncationMode(.middle)
                } icon: {
                    Image(systemName: "folder")
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            ChangesFileLeafRow(node: node)
                .tag(node.id)
        }
    }
}

/// A single changed-file leaf: name, status badge, and `+a −d` counts (or a
/// "Bin" indicator for binary files).
private struct ChangesFileLeafRow: View {
    let node: FileTreeNode

    @State private var isHovering = false
    /// Brief checkmark confirmation after a copy, cleared by a delayed reset.
    @State private var copied = false

    private var file: DiffFile? { node.diffFile }

    var body: some View {
        HStack(spacing: 6) {
            statusBadge
            Text(node.name)
                .lineLimit(1)
                .truncationMode(.middle)
            copyButton
            Spacer(minLength: 4)
            counts
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }

    /// GitHub-PR-style copy control: reveals on hover, copies the file's full
    /// relative path, and flashes a checkmark as confirmation.
    @ViewBuilder
    private var copyButton: some View {
        Group {
            if copied {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.green)
                    .help(Text("File path copied"))
                    .accessibilityLabel(Text("File path copied"))
            } else {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(node.id, forType: .string)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        copied = false
                    }
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(Text("Copy File Path"))
                .accessibilityLabel(Text("Copy File Path"))
            }
        }
        .opacity(isHovering || copied ? 1 : 0)
        .animation(.easeInOut(duration: 0.12), value: isHovering)
        .animation(.easeInOut(duration: 0.12), value: copied)
    }

    @ViewBuilder
    private var statusBadge: some View {
        if let status = file?.status {
            Text(status.rawValue)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Self.badgeColor(for: status))
                .frame(width: 14)
                .accessibilityLabel(Text(Self.accessibilityLabel(for: status)))
                .help(Text(Self.accessibilityLabel(for: status)))
        }
    }

    @ViewBuilder
    private var counts: some View {
        if let file, file.isBinary {
            Text("Bin")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
                .help(Text("Binary file"))
                .accessibilityLabel(Text("Binary file"))
        } else if let file, file.added > 0 || file.deleted > 0 {
            HStack(spacing: 4) {
                if file.added > 0 {
                    Text("+\(file.added)")
                        .foregroundStyle(Color(red: 0.25, green: 0.72, blue: 0.31))
                }
                if file.deleted > 0 {
                    (Text("−") + Text("\(file.deleted)"))
                        .foregroundStyle(Color(red: 0.97, green: 0.32, blue: 0.29))
                }
            }
            .font(.system(size: 10, design: .monospaced))
        }
    }

    /// Status badge color matching the diff webview conventions (GitHub palette).
    static func badgeColor(for status: DiffFile.Status) -> Color {
        switch status {
        case .added: return Color(red: 0.25, green: 0.72, blue: 0.31)
        case .modified: return Color(red: 0.82, green: 0.60, blue: 0.13)
        case .deleted: return Color(red: 0.97, green: 0.32, blue: 0.29)
        case .renamed: return Color(red: 0.35, green: 0.65, blue: 1.0)
        }
    }

    /// Localized accessibility/tooltip label for a status (badge letters stay A/M/D/R).
    static func accessibilityLabel(for status: DiffFile.Status) -> String {
        switch status {
        case .added: return NSLocalizedString("Added", comment: "Changes sidebar: file status")
        case .modified: return NSLocalizedString("Modified", comment: "Changes sidebar: file status")
        case .deleted: return NSLocalizedString("Deleted", comment: "Changes sidebar: file status")
        case .renamed: return NSLocalizedString("Renamed", comment: "Changes sidebar: file status")
        }
    }
}
