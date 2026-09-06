// ABOUTME: Tests for the Changes-tab overhaul: nul-separated git parsing,
// ABOUTME: batched content fetch, content-limit demotion, review versions, and
// ABOUTME: the viewed/collapsed persistence store.

@testable import FactoryFloor
import XCTest

final class ChangesParsingTests: XCTestCase {
    // MARK: - stableHash

    func testStableHashIsStableAcrossCalls() {
        XCTAssertEqual(GitOperations.stableHash("hello"), GitOperations.stableHash("hello"))
    }

    func testStableHashChangesWithContent() {
        XCTAssertNotEqual(GitOperations.stableHash("a"), GitOperations.stableHash("b"))
    }

    func testStableHashIsHex16() {
        let hash = GitOperations.stableHash("x")
        XCTAssertEqual(hash.count, 16)
        XCTAssertTrue(hash.allSatisfy(\.isHexDigit))
    }

    // MARK: - parseNameStatusZ

    func testNameStatusZParsesNormalEntries() {
        let data = Data("M\0a.swift\0A\0b.swift\0D\0gone.txt\0".utf8)
        let files = GitOperations.parseNameStatusZ(data)
        XCTAssertTrue(files.contains { $0.relativePath == "a.swift" && $0.status == .modified })
        XCTAssertTrue(files.contains { $0.relativePath == "b.swift" && $0.status == .added })
        XCTAssertTrue(files.contains { $0.relativePath == "gone.txt" && $0.status == .deleted })
    }

    func testNameStatusZCapturesOldPathForRenames() {
        let data = Data("R100\0old.swift\0new.swift\0".utf8)
        let files = GitOperations.parseNameStatusZ(data)
        XCTAssertEqual(files.count, 1)
        XCTAssertEqual(files.first?.relativePath, "new.swift")
        XCTAssertEqual(files.first?.status, .renamed)
        XCTAssertEqual(files.first?.oldPath, "old.swift")
    }

    func testNameStatusZHandlesSpecialFilenames() {
        // Spaces, quotes, and unicode survive nul framing exactly.
        let tricky = "dir/my file \"quoted\" ✓.swift"
        let data = Data("M\0\(tricky)\0".utf8)
        let files = GitOperations.parseNameStatusZ(data)
        XCTAssertEqual(files.first?.relativePath, tricky)
    }

    func testNameStatusZHandlesNewlineInFilename() {
        let tricky = "weird\nname.txt"
        var bytes = Data("M\0".utf8)
        bytes.append(contentsOf: tricky.utf8)
        bytes.append(0)
        let files = GitOperations.parseNameStatusZ(bytes)
        XCTAssertEqual(files.first?.relativePath, tricky)
    }

    func testNameStatusZFallsBackToLegacyText() {
        let data = Data("M\ta.swift".utf8)
        let files = GitOperations.parseNameStatusZ(data)
        XCTAssertTrue(files.contains { $0.relativePath == "a.swift" && $0.status == .modified })
    }

    func testNameStatusZEmptyDataYieldsEmpty() {
        XCTAssertTrue(GitOperations.parseNameStatusZ(Data()).isEmpty)
    }

    // MARK: - numstatZ

    func testNumstatZReturnsEmptyForNonRepo() {
        XCTAssertTrue(GitOperations.numstatZ(args: [], in: "/nonexistent").isEmpty)
    }
}

final class ChangesContentLimitTests: XCTestCase {
    func testSmallTextPasses() {
        XCTAssertFalse(ChangesView.exceedsContentLimits(original: "a\nb\n", modified: "a\nc\n"))
    }

    func testHugeTotalCharsDemotes() {
        let big = String(repeating: "x\n", count: 600_000)
        XCTAssertTrue(ChangesView.exceedsContentLimits(original: big, modified: ""))
    }

    func testMinifiedSingleLineDemotes() {
        let minified = String(repeating: "x", count: ChangesView.largeFileSingleLineThreshold + 1)
        XCTAssertTrue(ChangesView.exceedsContentLimits(original: "", modified: minified))
    }

    func testLongLinesUnderThresholdPass() {
        let line = String(repeating: "x", count: ChangesView.largeFileSingleLineThreshold)
        XCTAssertFalse(ChangesView.exceedsContentLimits(original: line + "\n", modified: line + "\n"))
    }

    func testContentVersionStableAndSensitive() {
        let v1 = ChangesView.contentVersion(original: "a", modified: "b")
        XCTAssertEqual(v1, ChangesView.contentVersion(original: "a", modified: "b"))
        XCTAssertNotEqual(v1, ChangesView.contentVersion(original: "a", modified: "c"))
        XCTAssertNotEqual(v1, ChangesView.contentVersion(original: "z", modified: "b"))
    }

    func testReviewVersionsStrongForBodiesWeakForPlaceholders() {        var binaryFile = DiffFile(relativePath: "big.bin", status: .added, isBinary: true)
        binaryFile.mtimeHint = 1234.5
        var hugeFile = DiffFile(relativePath: "huge.txt", status: .modified, changedLines: 9999)
        hugeFile.added = 6000
        hugeFile.deleted = 3999
        hugeFile.sizeHint = 4096
        hugeFile.mtimeHint = 42
        let files = [
            DiffFile(relativePath: "a.swift", status: .modified, changedLines: 4, added: 3, deleted: 1),
            binaryFile,
            hugeFile,
        ]
        let payload: [[String: Any]] = [
            ["filePath": "a.swift", "originalText": "old", "modifiedText": "new"],
            ["filePath": "big.bin", "binary": true, "originalText": "", "modifiedText": ""],
            ["filePath": "huge.txt", "deferred": true, "originalText": "", "modifiedText": ""],
        ]
        let versions = ChangesView.reviewVersions(payload: payload, files: files)
        XCTAssertEqual(versions["a.swift"], ChangesView.contentVersion(original: "old", modified: "new"))
        XCTAssertEqual(versions["big.bin"], ChangesViewStateStore.weakVersion(for: binaryFile))
        XCTAssertEqual(
            versions["huge.txt"],
            ChangesViewStateStore.weakVersion(for: hugeFile)
        )
    }

    func testShellsStripTextsAndFlagPendingForNormalFiles() {
        let payload: [[String: Any]] = [
            ["filePath": "a.swift", "originalText": "old", "modifiedText": "new", "changedLines": 4],
            ["filePath": "big.bin", "binary": true, "originalText": "", "modifiedText": ""],
            ["filePath": "huge.txt", "deferred": true, "originalText": "", "modifiedText": ""],
        ]
        let shells = ChangesView.shells(from: payload)
        XCTAssertEqual(shells.count, 3)
        let normal = shells.first { $0["filePath"] as? String == "a.swift" }
        XCTAssertEqual(normal?["originalText"] as? String, "")
        XCTAssertEqual(normal?["modifiedText"] as? String, "")
        XCTAssertEqual(normal?["pending"] as? Bool, true)
        // Placeholders pass through untouched (no pending flag, no texts to strip).
        let binary = shells.first { $0["filePath"] as? String == "big.bin" }
        XCTAssertNil(binary?["pending"])
        let deferred = shells.first { $0["filePath"] as? String == "huge.txt" }
        XCTAssertNil(deferred?["pending"])
    }

    func testBodyEntriesContainOnlyNormalFiles() {
        let payload: [[String: Any]] = [
            ["filePath": "a.swift", "originalText": "old", "modifiedText": "new"],
            ["filePath": "big.bin", "binary": true, "originalText": "", "modifiedText": ""],
            ["filePath": "huge.txt", "deferred": true, "originalText": "", "modifiedText": ""],
        ]
        let bodies = ChangesView.bodyEntries(from: payload)
        XCTAssertEqual(bodies.count, 1)
        XCTAssertEqual(bodies.first?["filePath"] as? String, "a.swift")
        // Bodies keep their texts for streaming.
        XCTAssertEqual(bodies.first?["modifiedText"] as? String, "new")
    }

    func testDetectEOLFindsCRLF() {
        XCTAssertEqual(ChangesView.detectEOL("a\r\nb\r\n"), "crlf")
        XCTAssertEqual(ChangesView.detectEOL("a\nb\n"), "lf")
        XCTAssertEqual(ChangesView.detectEOL("no newlines"), "lf")
        XCTAssertEqual(ChangesView.detectEOL(""), "lf")
    }

    func testEncodeForSaveRestoresCRLFAndBOM() {
        // Monaco hands back LF without BOM; the save path restores both.
        XCTAssertEqual(
            ChangesView.encodeForSave("a\nb\n", eol: "crlf", bom: false),
            "a\r\nb\r\n"
        )
        XCTAssertEqual(
            ChangesView.encodeForSave("a\n", eol: "lf", bom: true),
            "\u{FEFF}a\n"
        )
        XCTAssertEqual(
            ChangesView.encodeForSave("a\n", eol: "lf", bom: false),
            "a\n"
        )
        // Already-CRLF fragments must not double up.
        XCTAssertEqual(
            ChangesView.encodeForSave("a\r\nb\n", eol: "crlf", bom: false),
            "a\r\nb\r\n"
        )
        // A surviving BOM is never duplicated.
        XCTAssertEqual(
            ChangesView.encodeForSave("\u{FEFF}a\n", eol: "lf", bom: true),
            "\u{FEFF}a\n"
        )
    }

    func testWeakVersionDetectsSameSizeContentSwapViaMtime() {
        // Same line counts and byte size, different mtime: must differ so a
        // same-size edit still clears the Viewed mark.
        let before = ChangesViewStateStore.weakVersion(
            changedLines: 10, sizeHint: 100, mtime: 1000, added: 5, deleted: 5
        )
        let after = ChangesViewStateStore.weakVersion(
            changedLines: 10, sizeHint: 100, mtime: 2000, added: 5, deleted: 5
        )
        XCTAssertNotEqual(before, after)
    }

    func testWeakVersionDistinguishesAddedDeletedMix() {
        // +7/-3 vs +3/-7: same changedLines, different mix — must differ.
        let a = ChangesViewStateStore.weakVersion(
            changedLines: 10, sizeHint: 100, mtime: 1000, added: 7, deleted: 3
        )
        let b = ChangesViewStateStore.weakVersion(
            changedLines: 10, sizeHint: 100, mtime: 1000, added: 3, deleted: 7
        )
        XCTAssertNotEqual(a, b)
    }

    func testWeakVersionLegacyMarksDoNotSurvive() {
        // Pre-upgrade two-field stamps must not match the new shape, so stale
        // marks clear once instead of lingering.
        let legacy = "weak:10:100"
        let current = ChangesViewStateStore.weakVersion(
            changedLines: 10, sizeHint: 100, mtime: 0, added: 5, deleted: 5
        )
        XCTAssertNotEqual(legacy, current)
    }
}

final class ChangesViewStateStoreTests: XCTestCase {
    private var workstreamID: UUID!

    override func setUp() {
        super.setUp()
        workstreamID = UUID()
    }

    override func tearDown() {
        // Scrub keys for this workstream across both modes.
        for mode in ["branch", "uncommitted"] {
            UserDefaults.standard.removeObject(
                forKey: "factoryfloor.changesViewed.\(workstreamID.uuidString).\(mode)"
            )
            UserDefaults.standard.removeObject(
                forKey: "factoryfloor.changesCollapsed.\(workstreamID.uuidString).\(mode)"
            )
        }
        super.tearDown()
    }

    func testViewedMarkSurvivesIdenticalPrune() {
        ChangesViewStateStore.setViewed(
            true, workstreamID: workstreamID, mode: "branch",
            base: "abc", path: "a.swift", version: "v1"
        )
        let kept = ChangesViewStateStore.pruneViewed(
            workstreamID: workstreamID, mode: "branch",
            base: "abc", currentVersions: ["a.swift": "v1"]
        )
        XCTAssertEqual(kept, ["a.swift"])
    }

    func testViewedMarkClearsWhenContentChanges() {
        ChangesViewStateStore.setViewed(
            true, workstreamID: workstreamID, mode: "branch",
            base: "abc", path: "a.swift", version: "v1"
        )
        let kept = ChangesViewStateStore.pruneViewed(
            workstreamID: workstreamID, mode: "branch",
            base: "abc", currentVersions: ["a.swift": "v2"]
        )
        XCTAssertTrue(kept.isEmpty)
    }

    func testViewedMarkClearsWhenBaseMoves() {
        ChangesViewStateStore.setViewed(
            true, workstreamID: workstreamID, mode: "branch",
            base: "abc", path: "a.swift", version: "v1"
        )
        let kept = ChangesViewStateStore.pruneViewed(
            workstreamID: workstreamID, mode: "branch",
            base: "def", currentVersions: ["a.swift": "v1"]
        )
        XCTAssertTrue(kept.isEmpty)
    }

    func testViewedMarkClearsWhenFileNoLongerChanged() {
        ChangesViewStateStore.setViewed(
            true, workstreamID: workstreamID, mode: "branch",
            base: "abc", path: "a.swift", version: "v1"
        )
        let kept = ChangesViewStateStore.pruneViewed(
            workstreamID: workstreamID, mode: "branch",
            base: "abc", currentVersions: [:]
        )
        XCTAssertTrue(kept.isEmpty)
    }

    func testUnviewRemovesMark() {
        ChangesViewStateStore.setViewed(
            true, workstreamID: workstreamID, mode: "branch",
            base: "abc", path: "a.swift", version: "v1"
        )
        ChangesViewStateStore.setViewed(
            false, workstreamID: workstreamID, mode: "branch",
            base: "abc", path: "a.swift", version: "v1"
        )
        let kept = ChangesViewStateStore.pruneViewed(
            workstreamID: workstreamID, mode: "branch",
            base: "abc", currentVersions: ["a.swift": "v1"]
        )
        XCTAssertTrue(kept.isEmpty)
    }

    func testValidateViewedClearsStaleSingle() {
        ChangesViewStateStore.setViewed(
            true, workstreamID: workstreamID, mode: "uncommitted",
            base: "HEAD", path: "big.txt", version: "weak:10:100"
        )
        XCTAssertFalse(ChangesViewStateStore.validateViewed(
            workstreamID: workstreamID, mode: "uncommitted",
            base: "HEAD", path: "big.txt", version: "weak:12:120"
        ))
        // Second call finds no mark at all.
        XCTAssertFalse(ChangesViewStateStore.validateViewed(
            workstreamID: workstreamID, mode: "uncommitted",
            base: "HEAD", path: "big.txt", version: "weak:12:120"
        ))
    }

    func testCollapsedPersistsAndBulkUpdates() {
        XCTAssertTrue(ChangesViewStateStore.collapsedSet(workstreamID: workstreamID, mode: "branch").isEmpty)
        ChangesViewStateStore.setCollapsed(true, workstreamID: workstreamID, mode: "branch", path: "a.swift")
        XCTAssertEqual(
            ChangesViewStateStore.collapsedSet(workstreamID: workstreamID, mode: "branch"),
            ["a.swift"]
        )
        ChangesViewStateStore.setAllCollapsed(
            true, workstreamID: workstreamID, mode: "branch", paths: ["b.swift", "c.swift"]
        )
        XCTAssertEqual(
            ChangesViewStateStore.collapsedSet(workstreamID: workstreamID, mode: "branch"),
            ["a.swift", "b.swift", "c.swift"]
        )
        ChangesViewStateStore.setAllCollapsed(
            false, workstreamID: workstreamID, mode: "branch", paths: ["a.swift", "b.swift", "c.swift"]
        )
        XCTAssertTrue(ChangesViewStateStore.collapsedSet(workstreamID: workstreamID, mode: "branch").isEmpty)
    }

    func testModesAreIndependent() {
        ChangesViewStateStore.setViewed(
            true, workstreamID: workstreamID, mode: "branch",
            base: "abc", path: "a.swift", version: "v1"
        )
        let kept = ChangesViewStateStore.pruneViewed(
            workstreamID: workstreamID, mode: "uncommitted",
            base: "abc", currentVersions: ["a.swift": "v1"]
        )
        XCTAssertTrue(kept.isEmpty)
    }
}

final class ChangesGitBackedTests: XCTestCase {
    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testBatchFileContentsFetchesManyFilesInOneCall() throws {
        let repoDir = tempDir.appendingPathComponent("batch-repo")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)
        try "one\n".write(to: repoDir.appendingPathComponent("one.txt"), atomically: true, encoding: .utf8)
        try "two\n".write(to: repoDir.appendingPathComponent("two.txt"), atomically: true, encoding: .utf8)
        git(["add", "."], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "-m", "init"], in: repoDir)

        let contents = GitOperations.batchFileContents(
            at: repoDir.path, ref: "HEAD", paths: ["one.txt", "two.txt", "missing.txt"]
        )
        XCTAssertEqual(contents["one.txt"], "one\n")
        XCTAssertEqual(contents["two.txt"], "two\n")
        XCTAssertEqual(contents["missing.txt"], "")
    }

    func testBatchFileContentsHandlesLargeBlob() throws {
        // Over the ~64 KB pipe buffer: batch framing must use content sizes,
        // not line scans, so embedded newlines can't desync the parse.
        let repoDir = tempDir.appendingPathComponent("batch-large")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)
        var big = ""
        big.reserveCapacity(200_000)
        while big.utf8.count < 200 * 1024 { big += "the quick brown fox\n" }
        try big.write(to: repoDir.appendingPathComponent("big.txt"), atomically: true, encoding: .utf8)
        try "small\n".write(to: repoDir.appendingPathComponent("small.txt"), atomically: true, encoding: .utf8)
        git(["add", "."], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "-m", "init"], in: repoDir)

        let contents = GitOperations.batchFileContents(
            at: repoDir.path, ref: "HEAD", paths: ["big.txt", "small.txt"]
        )
        XCTAssertEqual(contents["big.txt"], big)
        XCTAssertEqual(contents["small.txt"], "small\n")
    }

    func testBranchDiffFilesFallsBackToUntrackedOnUnbornHEAD() throws {
        // Fresh repo, no commits: no merge-base exists, but the untracked file
        // must still be listed (previously reported "No changes").
        let repoDir = tempDir.appendingPathComponent("unborn")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)
        try "hello\n".write(to: repoDir.appendingPathComponent("new.txt"), atomically: true, encoding: .utf8)

        let files = GitOperations.branchDiffFiles(
            worktreePath: repoDir.path, projectPath: repoDir.path
        )
        XCTAssertTrue(files.contains { $0.relativePath == "new.txt" && $0.status == .added })
    }

    func testBranchDiffFilesCapturesOldPathForRename() throws {
        let projectDir = tempDir.appendingPathComponent("proj-oldpath")
        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: projectDir)
        try "some longer content that survives rename detection\n"
            .write(to: projectDir.appendingPathComponent("old.swift"), atomically: true, encoding: .utf8)
        git(["add", "."], in: projectDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "-m", "base"], in: projectDir)

        let wt = tempDir.appendingPathComponent("wt-oldpath")
        git(["worktree", "add", "-b", "feature-oldpath", wt.path], in: projectDir)
        git(["mv", "old.swift", "new.swift"], in: wt)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "-m", "rename"], in: wt)

        let files = GitOperations.branchDiffFiles(worktreePath: wt.path, projectPath: projectDir.path)
        let renamed = files.first { $0.relativePath == "new.swift" }
        XCTAssertNotNil(renamed)
        XCTAssertEqual(renamed?.oldPath, "old.swift")
    }

    func testDiffFingerprintIsStableAcrossProcesses() throws {
        // stableHash (FNV-1a) replaces String.hashValue (process-random), so
        // the fingerprint format must not contain the random hash.
        let repoDir = tempDir.appendingPathComponent("fp-format")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)
        try "a\n".write(to: repoDir.appendingPathComponent("a.txt"), atomically: true, encoding: .utf8)
        git(["add", "."], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "-m", "init"], in: repoDir)

        let fp1 = GitOperations.diffFingerprint(
            worktreePath: repoDir.path, projectPath: repoDir.path, mode: "uncommitted"
        )
        let fp2 = GitOperations.diffFingerprint(
            worktreePath: repoDir.path, projectPath: repoDir.path, mode: "uncommitted"
        )
        XCTAssertEqual(fp1, fp2)
        // 16-hex-char stable hash suffix.
        let parts = fp1.split(separator: "|")
        XCTAssertEqual(parts.count, 3)
        XCTAssertEqual(parts[2].count, 16)
    }

    func testUncommittedDiffFilesHandlesFilenameWithSpaces() throws {
        let repoDir = tempDir.appendingPathComponent("spaces")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)
        try "v1\n".write(
            to: repoDir.appendingPathComponent("my file.txt"), atomically: true, encoding: .utf8
        )
        git(["add", "."], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "-m", "init"], in: repoDir)
        try "v1\nv2\n".write(
            to: repoDir.appendingPathComponent("my file.txt"), atomically: true, encoding: .utf8
        )

        let files = GitOperations.uncommittedDiffFiles(at: repoDir.path)
        let entry = files.first { $0.relativePath == "my file.txt" }
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.added, 1)
    }

    func testRenamedFileKeepsNumstatCountsOnNewPath() throws {
        let repoDir = tempDir.appendingPathComponent("ren-counts")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)
        try "line1\nline2\nline3\nline4\n"
            .write(to: repoDir.appendingPathComponent("old.txt"), atomically: true, encoding: .utf8)
        git(["add", "."], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "-m", "init"], in: repoDir)
        git(["mv", "old.txt", "new.txt"], in: repoDir)
        // Modify after rename so numstat reports nonzero counts.
        try "line1\nCHANGED\nline3\nline4\nline5\n"
            .write(to: repoDir.appendingPathComponent("new.txt"), atomically: true, encoding: .utf8)

        let files = GitOperations.uncommittedDiffFiles(at: repoDir.path)
        let entry = files.first { $0.relativePath == "new.txt" }
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.status, .renamed)
        XCTAssertEqual(entry?.oldPath, "old.txt")
        XCTAssertGreaterThan((entry?.added ?? 0) + (entry?.deleted ?? 0), 0)
    }

    func testLossyReadDecodesNonUTF8() throws {
        let file = tempDir.appendingPathComponent("latin1.txt")
        // 0xE9 alone is invalid UTF-8; lossy decode must still return text.
        try Data([0x63, 0x61, 0x66, 0xE9, 0x0A]).write(to: file)
        let text = GitOperations.lossyFileText(atPath: file.path)
        XCTAssertNotNil(text)
        XCTAssertTrue(text?.contains("caf") ?? false)
    }

    // MARK: - Helpers

    @discardableResult
    private func git(_ args: [String], in dir: URL) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = args
        process.currentDirectoryURL = dir
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
        return process.terminationStatus == 0
    }
}
