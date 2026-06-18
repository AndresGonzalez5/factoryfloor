// ABOUTME: Tests for GitOperations worktree resolution.
// ABOUTME: Validates detection of worktree directories and resolution to main repository.

@testable import FactoryFloor
import XCTest

final class GitOperationsTests: XCTestCase {
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

    // MARK: - mainRepositoryPath

    func testMainRepositoryPathReturnsNilForNonGitDirectory() throws {
        let plainDir = tempDir.appendingPathComponent("plain")
        try FileManager.default.createDirectory(at: plainDir, withIntermediateDirectories: true)

        XCTAssertNil(GitOperations.mainRepositoryPath(for: plainDir.path))
    }

    func testMainRepositoryPathReturnsNilForMainRepo() throws {
        let repoDir = tempDir.appendingPathComponent("main-repo")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init"], in: repoDir)

        XCTAssertNil(GitOperations.mainRepositoryPath(for: repoDir.path))
    }

    func testMainRepositoryPathResolvesWorktreeToMainRepo() throws {
        let repoDir = tempDir.appendingPathComponent("main-repo")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init"], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "--allow-empty", "-m", "init"], in: repoDir)

        let worktreeDir = tempDir.appendingPathComponent("worktree-branch")
        git(["worktree", "add", "-b", "test-branch", worktreeDir.path], in: repoDir)

        let result = GitOperations.mainRepositoryPath(for: worktreeDir.path)
        XCTAssertEqual(
            URL(fileURLWithPath: result ?? "").standardizedFileURL.path,
            repoDir.standardizedFileURL.path
        )
    }

    func testMainRepositoryPathReturnsNilForNestedDirectoryInWorktree() throws {
        let repoDir = tempDir.appendingPathComponent("main-repo")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init"], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "--allow-empty", "-m", "init"], in: repoDir)

        let worktreeDir = tempDir.appendingPathComponent("worktree-branch")
        git(["worktree", "add", "-b", "test-branch", worktreeDir.path], in: repoDir)

        // A subdirectory inside the worktree doesn't have its own .git file
        let subDir = worktreeDir.appendingPathComponent("subdir")
        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        XCTAssertNil(GitOperations.mainRepositoryPath(for: subDir.path))
    }

    // MARK: - defaultBranch

    func testDefaultBranchReturnsLocalMainWhenNoRemote() throws {
        let repoDir = tempDir.appendingPathComponent("no-remote")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "--allow-empty", "-m", "init"], in: repoDir)

        let branch = GitOperations.defaultBranch(at: repoDir.path)
        XCTAssertEqual(branch, "main")
    }

    func testDefaultBranchReturnsMasterWhenNoMainBranch() throws {
        let repoDir = tempDir.appendingPathComponent("master-repo")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "master"], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "--allow-empty", "-m", "init"], in: repoDir)

        let branch = GitOperations.defaultBranch(at: repoDir.path)
        XCTAssertEqual(branch, "master")
    }

    func testDefaultBranchReturnsHEADWhenNeitherMainNorMasterExist() throws {
        let repoDir = tempDir.appendingPathComponent("custom-branch")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "develop"], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "--allow-empty", "-m", "init"], in: repoDir)

        let branch = GitOperations.defaultBranch(at: repoDir.path)
        XCTAssertEqual(branch, "HEAD")
    }

    func testDefaultBranchPrefersOriginOverLocal() throws {
        // Create a non-bare "remote" repo with a commit on main
        let remoteDir = tempDir.appendingPathComponent("remote")
        try FileManager.default.createDirectory(at: remoteDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: remoteDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "--allow-empty", "-m", "init"], in: remoteDir)

        // Clone it so we have origin/main
        let repoDir = tempDir.appendingPathComponent("cloned")
        git(["clone", remoteDir.path, repoDir.path], in: tempDir)

        let branch = GitOperations.defaultBranch(at: repoDir.path)
        XCTAssertTrue(branch.contains("origin"), "Expected origin-prefixed branch, got: \(branch)")
    }

    // MARK: - fetchDefaultBranch

    func testFetchDefaultBranchDoesNotCrashWithoutRemote() throws {
        let repoDir = tempDir.appendingPathComponent("no-remote-fetch")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "--allow-empty", "-m", "init"], in: repoDir)

        // Should return silently without crashing
        GitOperations.fetchDefaultBranch(at: repoDir.path)
    }

    func testFetchDefaultBranchDoesNotCrashForNonGitDirectory() throws {
        let plainDir = tempDir.appendingPathComponent("not-a-repo")
        try FileManager.default.createDirectory(at: plainDir, withIntermediateDirectories: true)

        // Should return silently without crashing
        GitOperations.fetchDefaultBranch(at: plainDir.path)
    }

    func testFetchDefaultBranchDoesNotCrashWithUnreachableRemote() throws {
        let repoDir = tempDir.appendingPathComponent("bad-remote")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "--allow-empty", "-m", "init"], in: repoDir)
        git(["remote", "add", "origin", "https://invalid.example.com/repo.git"], in: repoDir)

        // Should fail silently (timeout or network error)
        GitOperations.fetchDefaultBranch(at: repoDir.path)
    }

    // MARK: - currentBranch

    func testCurrentBranchReturnsActiveBranch() throws {
        let repoDir = tempDir.appendingPathComponent("branch-test")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "--allow-empty", "-m", "init"], in: repoDir)

        XCTAssertEqual(GitOperations.currentBranch(at: repoDir.path), "main")
    }

    func testCurrentBranchReturnsNilForNonGitDirectory() throws {
        let plainDir = tempDir.appendingPathComponent("not-a-repo")
        try FileManager.default.createDirectory(at: plainDir, withIntermediateDirectories: true)

        XCTAssertNil(GitOperations.currentBranch(at: plainDir.path))
    }

    func testCurrentBranchReturnsWorktreeBranch() throws {
        let repoDir = tempDir.appendingPathComponent("main-repo")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "--allow-empty", "-m", "init"], in: repoDir)

        let worktreeDir = tempDir.appendingPathComponent("wt")
        git(["worktree", "add", "-b", "ff/my-feature", worktreeDir.path], in: repoDir)

        XCTAssertEqual(GitOperations.currentBranch(at: worktreeDir.path), "ff/my-feature")
    }

    // MARK: - deleteLocalBranch

    func testDeleteLocalBranchRemovesBranch() throws {
        let repoDir = tempDir.appendingPathComponent("delete-branch")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "--allow-empty", "-m", "init"], in: repoDir)
        git(["branch", "feature"], in: repoDir)

        GitOperations.deleteLocalBranch(at: repoDir.path, branchName: "feature")

        // Verify branch no longer exists
        let result = git(["rev-parse", "--verify", "refs/heads/feature"], in: repoDir)
        XCTAssertFalse(result, "Branch should have been deleted")
    }

    // MARK: - fetchDefaultBranch

    func testFetchDefaultBranchSkipsWithoutRemote() throws {
        let repoDir = tempDir.appendingPathComponent("no-remote-update")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "--allow-empty", "-m", "init"], in: repoDir)

        // Should return silently without crashing
        GitOperations.fetchDefaultBranch(at: repoDir.path)
    }

    func testFetchDefaultBranchDoesNotMoveLocalRef() throws {
        // Create a "remote" repo
        let remoteDir = tempDir.appendingPathComponent("remote")
        try FileManager.default.createDirectory(at: remoteDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: remoteDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "--allow-empty", "-m", "init"], in: remoteDir)

        // Clone it
        let repoDir = tempDir.appendingPathComponent("local")
        git(["clone", remoteDir.path, repoDir.path], in: tempDir)

        // Record the initial commit
        let beforeSHA = gitOutput(["rev-parse", "refs/heads/main"], in: repoDir)

        // Add a new commit to remote
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "--allow-empty", "-m", "second"], in: remoteDir)

        // Fetch should update remote tracking ref but not local main
        GitOperations.fetchDefaultBranch(at: repoDir.path)

        let afterSHA = gitOutput(["rev-parse", "refs/heads/main"], in: repoDir)
        XCTAssertEqual(beforeSHA, afterSHA, "Local main should not have moved")

        let remoteSHA = gitOutput(["rev-parse", "refs/remotes/origin/main"], in: repoDir)
        XCTAssertNotEqual(beforeSHA, remoteSHA, "Remote tracking ref should have advanced")
    }

    // MARK: - fileStatuses

    func testFileStatusesReturnsModifiedForTrackedChanges() throws {
        let repoDir = tempDir.appendingPathComponent("status-modified")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)

        let filePath = repoDir.appendingPathComponent("tracked.txt")
        try "original".write(to: filePath, atomically: true, encoding: .utf8)
        git(["add", "tracked.txt"], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "-m", "init"], in: repoDir)

        try "changed".write(to: filePath, atomically: true, encoding: .utf8)

        let statuses = GitOperations.fileStatuses(at: repoDir.path)
        XCTAssertEqual(statuses["tracked.txt"], .modified)
    }

    func testFileStatusesReturnsUntrackedForNewFiles() throws {
        let repoDir = tempDir.appendingPathComponent("status-untracked")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "--allow-empty", "-m", "init"], in: repoDir)

        try "new file".write(
            to: repoDir.appendingPathComponent("untracked.txt"),
            atomically: true, encoding: .utf8
        )

        let statuses = GitOperations.fileStatuses(at: repoDir.path)
        XCTAssertEqual(statuses["untracked.txt"], .untracked)
    }

    func testFileStatusesReturnsIgnoredForGitignored() throws {
        let repoDir = tempDir.appendingPathComponent("status-ignored")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)

        try "build/\n".write(
            to: repoDir.appendingPathComponent(".gitignore"),
            atomically: true, encoding: .utf8
        )
        let buildDir = repoDir.appendingPathComponent("build")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)
        try "artifact".write(
            to: buildDir.appendingPathComponent("output.o"),
            atomically: true, encoding: .utf8
        )

        let statuses = GitOperations.fileStatuses(at: repoDir.path)
        XCTAssertEqual(statuses["build"], .ignored)
    }

    func testFileStatusesReturnsEmptyForNonGitDirectory() throws {
        let plainDir = tempDir.appendingPathComponent("no-git")
        try FileManager.default.createDirectory(at: plainDir, withIntermediateDirectories: true)

        let statuses = GitOperations.fileStatuses(at: plainDir.path)
        XCTAssertTrue(statuses.isEmpty)
    }

    func testFileStatusesHandlesRenames() throws {
        let repoDir = tempDir.appendingPathComponent("status-rename")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)

        try "content".write(
            to: repoDir.appendingPathComponent("old.txt"),
            atomically: true, encoding: .utf8
        )
        git(["add", "old.txt"], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "-m", "init"], in: repoDir)

        git(["mv", "old.txt", "new.txt"], in: repoDir)

        let statuses = GitOperations.fileStatuses(at: repoDir.path)
        XCTAssertEqual(statuses["new.txt"], .modified)
    }

    // MARK: - pruneCleanWorktrees

    func testPruneCleanWorktreesPrunesOnlyRequestedPaths() throws {
        let repoDir = tempDir.appendingPathComponent("prune-filtered")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "--allow-empty", "-m", "init"], in: repoDir)

        let worktreeA = tempDir.appendingPathComponent("worktree-a")
        let worktreeB = tempDir.appendingPathComponent("worktree-b")
        XCTAssertTrue(git(["worktree", "add", "-b", "feature/a", worktreeA.path], in: repoDir))
        XCTAssertTrue(git(["worktree", "add", "-b", "feature/b", worktreeB.path], in: repoDir))

        let pruned = GitOperations.pruneCleanWorktrees(
            at: repoDir.path,
            onlyPaths: Set([worktreeA.path])
        )

        XCTAssertEqual(pruned, 1)
        XCTAssertFalse(FileManager.default.fileExists(atPath: worktreeA.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: worktreeB.path))
    }

    // MARK: - uncommittedDiffFiles (Changes tab tracer)

    func testUncommittedDiffFilesListsModifiedTrackedFile() throws {
        let repoDir = tempDir.appendingPathComponent("changes-repo")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)
        let file = repoDir.appendingPathComponent("a.swift")
        try "let original = 1\n".write(to: file, atomically: true, encoding: .utf8)
        git(["add", "."], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "-m", "init"], in: repoDir)

        // Modify the tracked file without committing.
        try "let modified = 2\n".write(to: file, atomically: true, encoding: .utf8)

        let files = GitOperations.uncommittedDiffFiles(at: repoDir.path)
        XCTAssertGreaterThanOrEqual(files.count, 1)
        XCTAssertTrue(files.contains { $0.relativePath == "a.swift" && $0.status == .modified })
    }

    func testFileContentReturnsCommittedContentForRef() throws {
        let repoDir = tempDir.appendingPathComponent("content-repo")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)
        let file = repoDir.appendingPathComponent("a.swift")
        try "let original = 1\n".write(to: file, atomically: true, encoding: .utf8)
        git(["add", "."], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "-m", "init"], in: repoDir)

        let content = GitOperations.fileContent(at: repoDir.path, ref: "HEAD", filePath: "a.swift")
        XCTAssertEqual(content, "let original = 1\n")
    }

    // MARK: - Pipe-deadlock fix (Hardening 4)

    func testFileContentReturnsFullContentForLargeFile() throws {
        // A file larger than the ~64 KB pipe buffer must be returned in full
        // (stdout drained before waitUntilExit; no truncation, no deadlock).
        let repoDir = tempDir.appendingPathComponent("large-blob")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)

        // 256 KB of text — well over the macOS pipe buffer.
        let line = "the quick brown fox jumps over the lazy dog\n"
        var big = ""
        big.reserveCapacity(300_000)
        while big.utf8.count < 256 * 1024 {
            big += line
        }
        let expectedCount = big.utf8.count
        let file = repoDir.appendingPathComponent("big.txt")
        try big.write(to: file, atomically: true, encoding: .utf8)
        git(["add", "."], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "-m", "big"], in: repoDir)

        let content = GitOperations.fileContent(at: repoDir.path, ref: "HEAD", filePath: "big.txt")
        XCTAssertNotNil(content)
        XCTAssertEqual(content?.utf8.count, expectedCount, "Large git output must not be truncated")
    }

    // MARK: - mergeBase

    func testMergeBaseReturnsCommonAncestor() throws {
        let repoDir = tempDir.appendingPathComponent("mb-repo")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)
        let file = repoDir.appendingPathComponent("a.txt")
        try "base\n".write(to: file, atomically: true, encoding: .utf8)
        git(["add", "."], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "-m", "base"], in: repoDir)
        let baseSHA = gitOutput(["rev-parse", "HEAD"], in: repoDir)

        // Branch off, advance both branches.
        git(["checkout", "-b", "feature"], in: repoDir)
        try "feature\n".write(to: file, atomically: true, encoding: .utf8)
        git(["commit", "-am", "feature work",
             "-c", "user.email=test@test.com", "-c", "user.name=Test"], in: repoDir)

        // mergeBase(main, HEAD=feature) must be the base commit.
        let mb = GitOperations.mergeBase(worktreePath: repoDir.path, projectPath: repoDir.path)
        XCTAssertEqual(mb, baseSHA)
    }

    func testMergeBaseReturnsNilForNonGitDirectory() throws {
        let plainDir = tempDir.appendingPathComponent("mb-not-a-repo")
        try FileManager.default.createDirectory(at: plainDir, withIntermediateDirectories: true)
        XCTAssertNil(GitOperations.mergeBase(worktreePath: plainDir.path, projectPath: plainDir.path))
    }

    // MARK: - branchDiffFiles (Branch mode + untracked union — Hardening 1)

    func testBranchDiffFilesIncludesCommittedUncommittedAndUntracked() throws {
        // Set up: project repo with a base commit on main, then a worktree
        // branch that has (a) a committed-but-unmerged file, (b) an uncommitted
        // edit to a tracked file, and (c) an untracked new file.
        let projectDir = tempDir.appendingPathComponent("proj")
        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: projectDir)
        let tracked = projectDir.appendingPathComponent("b.swift")
        try "let b = 0\n".write(to: tracked, atomically: true, encoding: .utf8)
        git(["add", "."], in: projectDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "-m", "base"], in: projectDir)

        let wt = tempDir.appendingPathComponent("wt")
        git(["worktree", "add", "-b", "feature", wt.path], in: projectDir)

        // (a) committed-but-unmerged file on the branch
        let committedFile = wt.appendingPathComponent("a.swift")
        try "let a = 1\n".write(to: committedFile, atomically: true, encoding: .utf8)
        git(["add", "a.swift"], in: wt)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "-m", "add a"], in: wt)

        // (b) uncommitted edit to tracked b.swift
        try "let b = 99\n".write(to: wt.appendingPathComponent("b.swift"), atomically: true, encoding: .utf8)

        // (c) untracked new file
        try "let c = 3\n".write(to: wt.appendingPathComponent("c.swift"), atomically: true, encoding: .utf8)

        let files = GitOperations.branchDiffFiles(worktreePath: wt.path, projectPath: projectDir.path)
        let paths = Set(files.map { $0.relativePath })
        XCTAssertTrue(paths.contains("a.swift"), "committed file missing")
        XCTAssertTrue(paths.contains("b.swift"), "uncommitted edit missing")
        XCTAssertTrue(paths.contains("c.swift"), "untracked file missing (Hardening 1)")
        XCTAssertTrue(
            files.contains { $0.relativePath == "c.swift" && $0.status == .added },
            "untracked file must be status .added"
        )
    }

    func testBranchDiffFilesIncludesOnlyUntrackedFile() throws {
        // Branch whose only change is a never-committed new file.
        let projectDir = tempDir.appendingPathComponent("proj2")
        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: projectDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "--allow-empty", "-m", "base"], in: projectDir)

        let wt = tempDir.appendingPathComponent("wt2")
        git(["worktree", "add", "-b", "feature2", wt.path], in: projectDir)
        try "hello\n".write(to: wt.appendingPathComponent("new.txt"), atomically: true, encoding: .utf8)

        let files = GitOperations.branchDiffFiles(worktreePath: wt.path, projectPath: projectDir.path)
        XCTAssertTrue(
            files.contains { $0.relativePath == "new.txt" && $0.status == .added },
            "untracked-only branch change must be listed (PR #440 gap)"
        )
    }

    func testBranchDiffFilesMarksDeletedFile() throws {
        let projectDir = tempDir.appendingPathComponent("proj-del")
        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: projectDir)
        try "gone\n".write(to: projectDir.appendingPathComponent("gone.txt"), atomically: true, encoding: .utf8)
        git(["add", "."], in: projectDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "-m", "base"], in: projectDir)

        let wt = tempDir.appendingPathComponent("wt-del")
        git(["worktree", "add", "-b", "feature-del", wt.path], in: projectDir)
        try FileManager.default.removeItem(at: wt.appendingPathComponent("gone.txt"))

        let files = GitOperations.branchDiffFiles(worktreePath: wt.path, projectPath: projectDir.path)
        XCTAssertTrue(files.contains { $0.relativePath == "gone.txt" && $0.status == .deleted })
    }

    func testBranchDiffFilesUsesNewPathForRename() throws {
        let projectDir = tempDir.appendingPathComponent("proj-ren")
        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: projectDir)
        try "some longer content that survives rename detection\n"
            .write(to: projectDir.appendingPathComponent("old.swift"), atomically: true, encoding: .utf8)
        git(["add", "."], in: projectDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "-m", "base"], in: projectDir)

        let wt = tempDir.appendingPathComponent("wt-ren")
        git(["worktree", "add", "-b", "feature-ren", wt.path], in: projectDir)
        git(["mv", "old.swift", "new.swift"], in: wt)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "-m", "rename"], in: wt)

        let files = GitOperations.branchDiffFiles(worktreePath: wt.path, projectPath: projectDir.path)
        XCTAssertTrue(
            files.contains { $0.relativePath == "new.swift" },
            "renamed file should be listed under its new path"
        )
        XCTAssertFalse(files.contains { $0.relativePath == "old.swift" })
    }

    func testBranchDiffFilesReturnsEmptyForNonGitDirectory() throws {
        let plainDir = tempDir.appendingPathComponent("branch-not-a-repo")
        try FileManager.default.createDirectory(at: plainDir, withIntermediateDirectories: true)
        XCTAssertTrue(
            GitOperations.branchDiffFiles(worktreePath: plainDir.path, projectPath: plainDir.path).isEmpty
        )
    }

    // MARK: - uncommittedDiffFiles (untracked union — Hardening 1)

    func testUncommittedDiffFilesIncludesUntrackedAsAdded() throws {
        let repoDir = tempDir.appendingPathComponent("uncommitted-untracked")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "--allow-empty", "-m", "init"], in: repoDir)
        try "let c = 3\n".write(to: repoDir.appendingPathComponent("c.swift"), atomically: true, encoding: .utf8)

        let files = GitOperations.uncommittedDiffFiles(at: repoDir.path)
        XCTAssertTrue(files.contains { $0.relativePath == "c.swift" && $0.status == .added })
    }

    func testUncommittedDiffFilesExcludesUnchangedFiles() throws {
        let repoDir = tempDir.appendingPathComponent("uncommitted-clean")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)
        try "let a = 1\n".write(to: repoDir.appendingPathComponent("a.swift"), atomically: true, encoding: .utf8)
        try "let b = 0\n".write(to: repoDir.appendingPathComponent("b.swift"), atomically: true, encoding: .utf8)
        git(["add", "."], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "-m", "init"], in: repoDir)
        // Only modify b.swift.
        try "let b = 99\n".write(to: repoDir.appendingPathComponent("b.swift"), atomically: true, encoding: .utf8)

        let files = GitOperations.uncommittedDiffFiles(at: repoDir.path)
        XCTAssertTrue(files.contains { $0.relativePath == "b.swift" })
        XCTAssertFalse(files.contains { $0.relativePath == "a.swift" }, "unchanged file must not appear")
    }

    // MARK: - Binary detection (Hardening 2)

    func testBranchDiffFilesDetectsBinaryTrackedFile() throws {
        let projectDir = tempDir.appendingPathComponent("proj-bin")
        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: projectDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "--allow-empty", "-m", "base"], in: projectDir)

        let wt = tempDir.appendingPathComponent("wt-bin")
        git(["worktree", "add", "-b", "feature-bin", wt.path], in: projectDir)

        // A committed binary file (contains NUL bytes) — numstat reports "-"/"-".
        var bytes = Data()
        for i in 0..<2048 { bytes.append(UInt8(i % 256)) }
        try bytes.write(to: wt.appendingPathComponent("image.png"))
        git(["add", "image.png"], in: wt)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "-m", "add binary"], in: wt)

        let files = GitOperations.branchDiffFiles(worktreePath: wt.path, projectPath: projectDir.path)
        let entry = files.first { $0.relativePath == "image.png" }
        XCTAssertNotNil(entry)
        XCTAssertTrue(entry?.isBinary ?? false, "tracked binary must be flagged via numstat -/-")
    }

    func testUncommittedDiffFilesDetectsBinaryUntrackedViaNullByte() throws {
        let repoDir = tempDir.appendingPathComponent("uncommitted-bin")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "--allow-empty", "-m", "init"], in: repoDir)

        // Untracked binary file — numstat won't cover it; null-byte sniff must catch it.
        var bytes = Data([0x89, 0x50, 0x4E, 0x47, 0x00, 0x01, 0x02, 0x00])
        for i in 0..<512 { bytes.append(UInt8(i % 256)) }
        try bytes.write(to: repoDir.appendingPathComponent("untracked.bin"))

        let files = GitOperations.uncommittedDiffFiles(at: repoDir.path)
        let entry = files.first { $0.relativePath == "untracked.bin" }
        XCTAssertNotNil(entry)
        XCTAssertTrue(entry?.isBinary ?? false, "untracked binary must be detected by null-byte sniff")
    }

    func testTextFileIsNotMarkedBinary() throws {
        let repoDir = tempDir.appendingPathComponent("uncommitted-text")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)
        try "let a = 1\n".write(to: repoDir.appendingPathComponent("a.swift"), atomically: true, encoding: .utf8)
        git(["add", "."], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "-m", "init"], in: repoDir)
        try "let a = 2\nlet b = 3\n".write(to: repoDir.appendingPathComponent("a.swift"), atomically: true, encoding: .utf8)

        let files = GitOperations.uncommittedDiffFiles(at: repoDir.path)
        let entry = files.first { $0.relativePath == "a.swift" }
        XCTAssertNotNil(entry)
        XCTAssertFalse(entry?.isBinary ?? true, "text file must not be flagged binary")
    }

    // MARK: - changedLines from numstat (Hardening 3)

    func testChangedLinesReflectNumstatCounts() throws {
        let repoDir = tempDir.appendingPathComponent("changed-lines")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)
        try "line1\nline2\nline3\n".write(to: repoDir.appendingPathComponent("a.txt"), atomically: true, encoding: .utf8)
        git(["add", "."], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "-m", "init"], in: repoDir)
        // Add 2 lines, remove 0 (append).
        try "line1\nline2\nline3\nline4\nline5\n".write(to: repoDir.appendingPathComponent("a.txt"), atomically: true, encoding: .utf8)

        let files = GitOperations.uncommittedDiffFiles(at: repoDir.path)
        let entry = files.first { $0.relativePath == "a.txt" }
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.changedLines, 2, "added=2, deleted=0 → changedLines=2")
    }

    func testUntrackedChangedLinesCountFileLines() throws {
        let repoDir = tempDir.appendingPathComponent("untracked-lines")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "--allow-empty", "-m", "init"], in: repoDir)
        try "a\nb\nc\nd\n".write(to: repoDir.appendingPathComponent("new.txt"), atomically: true, encoding: .utf8)

        let files = GitOperations.uncommittedDiffFiles(at: repoDir.path)
        let entry = files.first { $0.relativePath == "new.txt" }
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.changedLines, 4, "untracked changedLines = line count of file")
        XCTAssertGreaterThan(entry?.sizeHint ?? 0, 0, "sizeHint should reflect on-disk byte size")
    }

    // MARK: - diffFingerprint

    func testDiffFingerprintStableWhenNothingChanges() throws {
        let repoDir = tempDir.appendingPathComponent("fp-stable")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)
        try "let a = 1\n".write(to: repoDir.appendingPathComponent("a.swift"), atomically: true, encoding: .utf8)
        git(["add", "."], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "-m", "init"], in: repoDir)
        try "let a = 2\n".write(to: repoDir.appendingPathComponent("a.swift"), atomically: true, encoding: .utf8)

        let fp1 = GitOperations.diffFingerprint(worktreePath: repoDir.path, projectPath: repoDir.path, mode: "uncommitted")
        let fp2 = GitOperations.diffFingerprint(worktreePath: repoDir.path, projectPath: repoDir.path, mode: "uncommitted")
        XCTAssertEqual(fp1, fp2, "fingerprint must be stable when nothing changes")
    }

    func testDiffFingerprintChangesWhenContentChanges() throws {
        let repoDir = tempDir.appendingPathComponent("fp-change")
        try FileManager.default.createDirectory(at: repoDir, withIntermediateDirectories: true)
        git(["init", "-b", "main"], in: repoDir)
        try "let a = 1\n".write(to: repoDir.appendingPathComponent("a.swift"), atomically: true, encoding: .utf8)
        git(["add", "."], in: repoDir)
        git(["-c", "user.email=test@test.com", "-c", "user.name=Test",
             "commit", "-m", "init"], in: repoDir)

        let fpClean = GitOperations.diffFingerprint(worktreePath: repoDir.path, projectPath: repoDir.path, mode: "uncommitted")

        // Edit the file.
        try "let a = 2\nlet b = 3\n".write(to: repoDir.appendingPathComponent("a.swift"), atomically: true, encoding: .utf8)
        let fpEdited = GitOperations.diffFingerprint(worktreePath: repoDir.path, projectPath: repoDir.path, mode: "uncommitted")
        XCTAssertNotEqual(fpClean, fpEdited, "fingerprint must change after an edit")

        // Add an untracked file (uncommitted mode includes ls-files --others).
        try "new\n".write(to: repoDir.appendingPathComponent("new.txt"), atomically: true, encoding: .utf8)
        let fpUntracked = GitOperations.diffFingerprint(worktreePath: repoDir.path, projectPath: repoDir.path, mode: "uncommitted")
        XCTAssertNotEqual(fpEdited, fpUntracked, "fingerprint must change when an untracked file appears")
    }

    func testDiffFingerprintDoesNotCrashForNonGitDirectory() throws {
        let plainDir = tempDir.appendingPathComponent("fp-not-a-repo")
        try FileManager.default.createDirectory(at: plainDir, withIntermediateDirectories: true)
        // Must not crash; returns some stable string.
        let fp = GitOperations.diffFingerprint(worktreePath: plainDir.path, projectPath: plainDir.path, mode: "branch")
        XCTAssertFalse(fp.isEmpty)
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

    private func gitOutput(_ args: [String], in dir: URL) -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = args
        process.currentDirectoryURL = dir
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return (String(data: data, encoding: .utf8) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
