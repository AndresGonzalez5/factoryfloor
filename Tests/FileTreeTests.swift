// ABOUTME: Tests for the pure flat-paths -> nested file tree builder used by the Changes sidebar.
// ABOUTME: Validates nesting, sort order (dirs before files, case-insensitive), and leaf metadata.

@testable import FactoryFloor
import XCTest

final class FileTreeTests: XCTestCase {
    // MARK: - Helpers

    private func file(
        _ path: String,
        _ status: DiffFile.Status = .modified,
        added: Int = 0,
        deleted: Int = 0,
        isBinary: Bool = false
    ) -> DiffFile {
        DiffFile(
            relativePath: path,
            status: status,
            isBinary: isBinary,
            changedLines: added + deleted,
            added: added,
            deleted: deleted,
            sizeHint: 0
        )
    }

    /// Names of a node's children in order.
    private func childNames(_ node: FileTreeNode) -> [String] {
        (node.children ?? []).map(\.name)
    }

    // MARK: - Nesting

    func testFlatPathsNestCorrectly() {
        let tree = FileTreeNode.build(from: [
            file("Sources/Models/Git.swift"),
            file("Sources/Views/ChangesView.swift"),
            file("README.md"),
        ])

        // Root: directories first (Sources), then files (README.md).
        XCTAssertEqual(childNames(tree), ["Sources", "README.md"])

        let sources = tree.children!.first { $0.name == "Sources" }!
        XCTAssertTrue(sources.isDirectory)
        XCTAssertNil(sources.diffFile)
        XCTAssertEqual(childNames(sources), ["Models", "Views"])

        let models = sources.children!.first { $0.name == "Models" }!
        XCTAssertEqual(childNames(models), ["Git.swift"])
        XCTAssertTrue(models.children!.first!.diffFile != nil)
        XCTAssertFalse(models.children!.first!.isDirectory)

        let views = sources.children!.first { $0.name == "Views" }!
        XCTAssertEqual(childNames(views), ["ChangesView.swift"])
    }

    func testSingleRootLevelFileIsRootLeaf() {
        let tree = FileTreeNode.build(from: [file("README.md")])
        XCTAssertEqual(tree.children?.count, 1)
        let leaf = tree.children!.first!
        XCTAssertEqual(leaf.name, "README.md")
        XCTAssertFalse(leaf.isDirectory)
        XCTAssertNil(leaf.children)
        XCTAssertEqual(leaf.diffFile?.relativePath, "README.md")
    }

    func testEmptyInputYieldsEmptyRoot() {
        let tree = FileTreeNode.build(from: [])
        XCTAssertTrue((tree.children ?? []).isEmpty)
    }

    // MARK: - Sort order

    func testDirectoriesSortBeforeFiles() {
        let tree = FileTreeNode.build(from: [
            file("alpha.txt"),
            file("zeta/inner.txt"),
        ])
        // Directory "zeta" sorts before file "alpha.txt" despite alphabetical order.
        XCTAssertEqual(childNames(tree), ["zeta", "alpha.txt"])
    }

    func testAlphabeticalCaseInsensitive() {
        let tree = FileTreeNode.build(from: [
            file("dir/Banana.txt"),
            file("dir/apple.txt"),
            file("dir/Cherry.txt"),
        ])
        let dir = tree.children!.first { $0.name == "dir" }!
        XCTAssertEqual(childNames(dir), ["apple.txt", "Banana.txt", "Cherry.txt"])
    }

    func testDirectoriesAmongThemselvesAlphabetical() {
        let tree = FileTreeNode.build(from: [
            file("Zoo/a.txt"),
            file("apple/b.txt"),
            file("Mango/c.txt"),
        ])
        XCTAssertEqual(childNames(tree), ["apple", "Mango", "Zoo"])
    }

    // MARK: - Leaf metadata propagation

    func testStatusAndCountsPropagateToCorrectLeaf() {
        let tree = FileTreeNode.build(from: [
            file("src/added.swift", .added, added: 10, deleted: 0),
            file("src/removed.swift", .deleted, added: 0, deleted: 7),
            file("src/renamed.swift", .renamed, added: 3, deleted: 1),
            file("src/binary.png", .modified, isBinary: true),
        ])
        let src = tree.children!.first { $0.name == "src" }!
        let leaves = Dictionary(uniqueKeysWithValues: src.children!.map { ($0.name, $0) })

        XCTAssertEqual(leaves["added.swift"]?.diffFile?.status, .added)
        XCTAssertEqual(leaves["added.swift"]?.diffFile?.added, 10)
        XCTAssertEqual(leaves["added.swift"]?.diffFile?.deleted, 0)

        XCTAssertEqual(leaves["removed.swift"]?.diffFile?.status, .deleted)
        XCTAssertEqual(leaves["removed.swift"]?.diffFile?.deleted, 7)

        XCTAssertEqual(leaves["renamed.swift"]?.diffFile?.status, .renamed)
        XCTAssertEqual(leaves["renamed.swift"]?.diffFile?.added, 3)
        XCTAssertEqual(leaves["renamed.swift"]?.diffFile?.deleted, 1)

        XCTAssertEqual(leaves["binary.png"]?.diffFile?.isBinary, true)
    }

    func testLeafIdIsFullPath() {
        let tree = FileTreeNode.build(from: [file("a/b/c.swift")])
        let a = tree.children!.first!
        let b = a.children!.first!
        let c = b.children!.first!
        XCTAssertEqual(c.id, "a/b/c.swift")
        XCTAssertEqual(b.id, "a/b")
        XCTAssertEqual(a.id, "a")
    }

    func testDirectoryNodesHaveNoDiffFile() {
        let tree = FileTreeNode.build(from: [file("deep/nested/file.txt")])
        let deep = tree.children!.first!
        XCTAssertTrue(deep.isDirectory)
        XCTAssertNil(deep.diffFile)
        XCTAssertNil(deep.children!.first!.diffFile) // "nested" dir
    }
}
