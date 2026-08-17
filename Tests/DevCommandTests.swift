// ABOUTME: Tests for dev server command resolution (browser tab auto-start).
// ABOUTME: Covers package.json detection, lockfile manager inference, and override precedence.

@testable import FactoryFloor
import XCTest

final class DevCommandTests: XCTestCase {
    private var tmpDir: URL!
    private let workstreamID = UUID()

    override func setUp() {
        super.setUp()
        tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        DevCommandResolver.saveOverride(nil, for: workstreamID)
        try? FileManager.default.removeItem(at: tmpDir)
        super.tearDown()
    }

    // MARK: - package.json detection

    func testDetectsDevScriptFromPackageJSON() throws {
        try writePackageJSON(["dev": "vite"])

        let command = try XCTUnwrap(DevCommandResolver.detectPackageScript(in: tmpDir.path))

        XCTAssertEqual(command.command, "npm run dev")
        XCTAssertEqual(command.source, .packageJSON)
    }

    func testNoDevScriptReturnsNil() throws {
        try writePackageJSON(["build": "vite build"])

        XCTAssertNil(DevCommandResolver.detectPackageScript(in: tmpDir.path))
    }

    func testMissingPackageJSONReturnsNil() {
        XCTAssertNil(DevCommandResolver.detectPackageScript(in: tmpDir.path))
    }

    func testEmptyDevScriptReturnsNil() throws {
        try writePackageJSON(["dev": "   "])

        XCTAssertNil(DevCommandResolver.detectPackageScript(in: tmpDir.path))
    }

    // MARK: - Package manager inference

    func testDefaultsToNpmWithoutLockfile() {
        XCTAssertEqual(DevCommandResolver.packageManager(in: tmpDir.path), "npm")
    }

    func testBunLockfilesPickBun() throws {
        for name in ["bun.lock", "bun.lockb"] {
            try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
            try Data().write(to: tmpDir.appendingPathComponent(name))
            XCTAssertEqual(
                DevCommandResolver.packageManager(in: tmpDir.path),
                "bun",
                "\(name) should select bun"
            )
            try? FileManager.default.removeItem(at: tmpDir.appendingPathComponent(name))
        }
    }

    func testPnpmLockfilePicksPnpm() throws {
        try Data().write(to: tmpDir.appendingPathComponent("pnpm-lock.yaml"))

        XCTAssertEqual(DevCommandResolver.packageManager(in: tmpDir.path), "pnpm")
    }

    func testYarnLockfilePicksYarn() throws {
        try Data().write(to: tmpDir.appendingPathComponent("yarn.lock"))

        XCTAssertEqual(DevCommandResolver.packageManager(in: tmpDir.path), "yarn")
    }

    func testBunLockTakesPrecedenceOverYarn() throws {
        try Data().write(to: tmpDir.appendingPathComponent("bun.lockb"))
        try Data().write(to: tmpDir.appendingPathComponent("yarn.lock"))

        XCTAssertEqual(DevCommandResolver.packageManager(in: tmpDir.path), "bun")
    }

    // MARK: - Resolution precedence

    func testConfigRunScriptWinsOverEverything() throws {
        try writePackageJSON(["dev": "vite"])
        DevCommandResolver.saveOverride("npm --prefix frontend run dev", for: workstreamID)
        let config = ScriptConfig(setup: nil, run: "make serve", teardown: nil, source: ".factoryfloor.json", loadError: nil)

        let resolved = DevCommandResolver.resolve(
            scriptConfig: config,
            workstreamID: workstreamID,
            workingDirectory: tmpDir.path,
            override: DevCommandResolver.savedOverride(for: workstreamID)
        )

        XCTAssertEqual(resolved?.command, "make serve")
        XCTAssertEqual(resolved?.source, .configScript)
    }

    func testOverrideBeatsPackageJSONDetection() throws {
        try writePackageJSON(["dev": "vite"])
        DevCommandResolver.saveOverride("npm run dev -- --port 3000", for: workstreamID)

        let resolved = DevCommandResolver.resolve(
            scriptConfig: .empty,
            workstreamID: workstreamID,
            workingDirectory: tmpDir.path,
            override: DevCommandResolver.savedOverride(for: workstreamID)
        )

        XCTAssertEqual(resolved?.command, "npm run dev -- --port 3000")
        XCTAssertEqual(resolved?.source, .override)
    }

    func testPackageJSONUsedWhenNoOverride() throws {
        try writePackageJSON(["dev": "next dev"])

        let resolved = DevCommandResolver.resolve(
            scriptConfig: .empty,
            workstreamID: workstreamID,
            workingDirectory: tmpDir.path,
            override: nil
        )

        XCTAssertEqual(resolved?.command, "npm run dev")
        XCTAssertEqual(resolved?.source, .packageJSON)
    }

    func testNothingDetectedReturnsNil() {
        let resolved = DevCommandResolver.resolve(
            scriptConfig: .empty,
            workstreamID: workstreamID,
            workingDirectory: tmpDir.path,
            override: nil
        )

        XCTAssertNil(resolved)
    }

    // MARK: - Override persistence

    func testOverrideRoundTrip() {
        DevCommandResolver.saveOverride("bun run dev", for: workstreamID)

        XCTAssertEqual(DevCommandResolver.savedOverride(for: workstreamID), "bun run dev")
    }

    func testEmptyOverrideClearsSavedValue() {
        DevCommandResolver.saveOverride("bun run dev", for: workstreamID)
        DevCommandResolver.saveOverride(nil, for: workstreamID)

        XCTAssertNil(DevCommandResolver.savedOverride(for: workstreamID))
    }

    func testBlankOverrideIsTreatedAsAbsent() {
        DevCommandResolver.saveOverride("   ", for: workstreamID)

        XCTAssertNil(DevCommandResolver.savedOverride(for: workstreamID))
    }

    // MARK: - Helpers

    private func writePackageJSON(_ scripts: [String: String]) throws {
        let data = try JSONSerialization.data(withJSONObject: ["scripts": scripts])
        try data.write(to: tmpDir.appendingPathComponent("package.json"))
    }
}