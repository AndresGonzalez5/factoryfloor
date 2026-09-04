// ABOUTME: Tests for environment tab session restoration decisions.
// ABOUTME: Verifies run panes reappear when tmux already has a persisted run session.

@testable import FactoryFloor
import XCTest

final class EnvironmentTabViewTests: XCTestCase {
    func testRunSessionRestoresOnlyWhenTmuxSessionExists() {
        XCTAssertTrue(shouldRestoreRunSession(useTmux: true, hasRunScript: true, hasExistingRunSession: true, wasStoppedManually: false, isApproved: true))
        XCTAssertFalse(shouldRestoreRunSession(useTmux: false, hasRunScript: true, hasExistingRunSession: true, wasStoppedManually: false, isApproved: true))
        XCTAssertFalse(shouldRestoreRunSession(useTmux: true, hasRunScript: false, hasExistingRunSession: true, wasStoppedManually: false, isApproved: true))
        XCTAssertFalse(shouldRestoreRunSession(useTmux: true, hasRunScript: true, hasExistingRunSession: false, wasStoppedManually: false, isApproved: true))
    }

    func testRunSessionDoesNotRestoreAfterManualStop() {
        XCTAssertFalse(shouldRestoreRunSession(useTmux: true, hasRunScript: true, hasExistingRunSession: true, wasStoppedManually: true, isApproved: true))
    }

    func testRunSessionDoesNotRestoreWithoutApproval() {
        XCTAssertFalse(shouldRestoreRunSession(useTmux: true, hasRunScript: true, hasExistingRunSession: true, wasStoppedManually: false, isApproved: false))
    }

    func testSetupScriptAppendsCompletionMessage() {
        let command = scriptCommand(script: "./.hooks/factoryfloor-setup.sh", role: "setup", shell: "/bin/zsh")

        XCTAssertTrue(command.contains("./.hooks/factoryfloor-setup.sh"))
        XCTAssertTrue(command.contains("Setup completed in this terminal."))
    }

    func testRunScriptDoesNotAppendCompletionMessage() {
        let command = scriptCommand(script: "just local", role: "run", shell: "/bin/zsh")

        XCTAssertFalse(command.contains("Setup completed"))
    }

    func testSetupScriptWrapsInLoginShell() {
        let command = scriptCommand(script: "setup.sh", role: "setup", shell: "/bin/zsh")

        XCTAssertTrue(command.hasPrefix("/bin/zsh -lic "))
    }

    func testRunScriptWrapsInLoginShell() {
        let command = scriptCommand(script: "just local", role: "run", shell: "/bin/zsh")

        XCTAssertTrue(command.hasPrefix("/bin/zsh -lic "))
        XCTAssertTrue(command.contains("just local"))
    }

    func testRunScriptCommandUsesLoginShell() {
        let command = runScriptCommand(script: "bun dev", workstreamID: UUID(), launcherPath: "/path/to/ff-run", shell: "/bin/zsh")

        XCTAssertTrue(command.contains("/bin/zsh -lic"))
        XCTAssertFalse(command.contains("/bin/sh"))
    }

    // MARK: - Display status (flag reconciled with live port state)

    func testDisplayStatusIdleWhenNeverStarted() {
        XCTAssertEqual(
            RunDisplayStatus.resolve(runStarted: false, runCommand: nil, portStatus: .none, selectedPort: nil, isWaiting: false),
            .idle
        )
    }

    func testDisplayStatusRunningWithPort() {
        XCTAssertEqual(
            RunDisplayStatus.resolve(runStarted: true, runCommand: "npm run dev", portStatus: .running, selectedPort: 5173, isWaiting: false),
            .running(port: 5173)
        )
    }

    func testDisplayStatusStartingWhileNoPort() {
        XCTAssertEqual(
            RunDisplayStatus.resolve(runStarted: true, runCommand: "npm run dev", portStatus: .starting, selectedPort: nil, isWaiting: false),
            .starting
        )
    }

    func testDisplayStatusStartingWhileWaiting() {
        XCTAssertEqual(
            RunDisplayStatus.resolve(runStarted: true, runCommand: "npm run dev", portStatus: .none, selectedPort: nil, isWaiting: true),
            .starting
        )
    }

    func testDisplayStatusStaleWhenFlagWithoutSession() {
        // The phantom Stop/Rerun case: flag set, no live session, not booting.
        XCTAssertEqual(
            RunDisplayStatus.resolve(runStarted: true, runCommand: "npm run dev", portStatus: .none, selectedPort: nil, isWaiting: false),
            .stale
        )
    }

    func testDisplayStatusStaleWhenCommandMissing() {
        XCTAssertEqual(
            RunDisplayStatus.resolve(runStarted: true, runCommand: nil, portStatus: .running, selectedPort: 5173, isWaiting: false),
            .stale
        )
    }

    // MARK: - Port references in dev commands

    func testDevCommandReferencesPortDetectsFFPORT() {
        XCTAssertTrue(devCommandReferencesPort("vite --port $FF_PORT --strictPort"))
        XCTAssertTrue(devCommandReferencesPort("next dev -p ${FF_PORT}"))
    }

    func testDevCommandReferencesPortDetectsExplicitFlags() {
        XCTAssertTrue(devCommandReferencesPort("vite --port 5173"))
        XCTAssertTrue(devCommandReferencesPort("next dev -p 3000"))
        XCTAssertTrue(devCommandReferencesPort("next dev -p3000"))
    }

    func testDevCommandReferencesPortRejectsBareCommands() {
        XCTAssertFalse(devCommandReferencesPort("npm run dev"))
        XCTAssertFalse(devCommandReferencesPort("bun run dev"))
        XCTAssertFalse(devCommandReferencesPort("make serve"))
    }
}
