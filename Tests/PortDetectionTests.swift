// ABOUTME: Tests for run-script port detection and browser retargeting behavior.
// ABOUTME: Covers launcher command building, port selection stabilization, and browser navigation policy.

@testable import FactoryFloor
import XCTest

final class PortDetectionTests: XCTestCase {
    func testRunLauncherWrapsRunScriptInLoginShell() throws {
        let workstreamID = try XCTUnwrap(UUID(uuidString: "12345678-1234-1234-1234-123456789ABC"))

        let command = runScriptCommand(
            script: "just dev",
            workstreamID: workstreamID,
            launcherPath: "/Applications/Factory Floor.app/Contents/Helpers/ff-run",
            shell: "/bin/zsh"
        )

        XCTAssertEqual(
            command,
            "'/Applications/Factory Floor.app/Contents/Helpers/ff-run' --workstream-id 12345678-1234-1234-1234-123456789abc --generation 0 -- /bin/zsh -lic 'just dev'"
        )
    }

    func testRunLauncherIncludesGeneration() throws {
        let workstreamID = try XCTUnwrap(UUID(uuidString: "12345678-1234-1234-1234-123456789ABC"))

        let command = runScriptCommand(
            script: "just dev",
            workstreamID: workstreamID,
            launcherPath: "/ff-run",
            shell: "/bin/zsh",
            generation: 3
        )

        XCTAssertTrue(command.contains("--generation 3"))
    }

    func testSingleNewPortRequiresTwoPollsBeforeSelection() {
        var tracker = PortSelectionTracker(expectedPort: 40001)

        let first = tracker.update(listeningPorts: [5173])
        XCTAssertEqual(first.detectedPorts, [5173])
        XCTAssertNil(first.selectedPort)

        let second = tracker.update(listeningPorts: [5173])
        XCTAssertEqual(second.selectedPort, 5173)
    }

    func testMultiplePortsPreferExpectedPort() {
        var tracker = PortSelectionTracker(expectedPort: 40001)
        _ = tracker.update(listeningPorts: [40001, 5173])

        let second = tracker.update(listeningPorts: [40001, 5173])

        XCTAssertEqual(second.detectedPorts, [40001, 5173])
        XCTAssertEqual(second.selectedPort, 40001)
    }

    func testMultiplePortsWithoutExpectedPortDoNotAutoSelect() {
        var tracker = PortSelectionTracker(expectedPort: 40001)
        _ = tracker.update(listeningPorts: [3000, 5173])

        let second = tracker.update(listeningPorts: [3000, 5173])

        XCTAssertEqual(second.detectedPorts, [3000, 5173])
        XCTAssertNil(second.selectedPort)
    }

    func testBrowserRetargetsWhenStillOnPreviousDefaultURL() {
        XCTAssertTrue(shouldRetargetBrowser(
            currentURL: "http://localhost:40001/",
            displayedURL: "http://localhost:40001/",
            previousDefaultURL: "http://localhost:40001/",
            nextDefaultURL: "http://localhost:5173/",
            connectionError: false
        ))
    }

    func testBrowserRetargetsWhenShowingConnectionErrorForPreviousDefaultURL() {
        XCTAssertTrue(shouldRetargetBrowser(
            currentURL: nil,
            displayedURL: "http://localhost:40001/",
            previousDefaultURL: "http://localhost:40001/",
            nextDefaultURL: "http://localhost:5173/",
            connectionError: true
        ))
    }

    func testBrowserDoesNotRetargetWhenUserNavigatedElsewhere() {
        XCTAssertFalse(shouldRetargetBrowser(
            currentURL: "https://example.com/",
            displayedURL: "https://example.com/",
            previousDefaultURL: "http://localhost:40001/",
            nextDefaultURL: "http://localhost:5173/",
            connectionError: false
        ))
    }

    // MARK: - Generation ownership (stop/start race guard)

    func testOwnedByGenerationMatchesSameGeneration() {
        XCTAssertTrue(isOwnedByGeneration(fileGeneration: 3, ownerGeneration: 3))
    }

    func testOwnedByGenerationRejectsNewerFile() {
        // Old monitor teardown must not delete the new server's state.
        XCTAssertFalse(isOwnedByGeneration(fileGeneration: 4, ownerGeneration: 3))
    }

    func testOwnedByGenerationTreatsLegacyFileAsStale() {
        XCTAssertTrue(isOwnedByGeneration(fileGeneration: nil, ownerGeneration: 3))
    }

    // MARK: - Process tree killer

    func testDescendantsAreLeavesFirst() {
        // 1 -> 2 -> 4, 1 -> 3
        let map: [Int32: Int32] = [2: 1, 3: 1, 4: 2]

        let ordered = RunProcessKiller.descendants(of: 1, parentMap: map)

        XCTAssertEqual(Set(ordered), [2, 3, 4])
        // Deepest leaf (4) comes before its parent (2) so children are
        // signalled before the processes that spawned them.
        XCTAssertLessThan(ordered.firstIndex(of: 4)!, ordered.firstIndex(of: 2)!)
        XCTAssertFalse(ordered.contains(1))
    }

    func testDescendantsOfUnknownRootIsEmpty() {
        XCTAssertEqual(RunProcessKiller.descendants(of: 999, parentMap: [2: 1]), [])
    }

    func testParseParentMapSkipsMalformedLines() {
        let output = "  123     1\nbroken line\n  456   123\n"

        let map = RunProcessKiller.parseParentMap(output)

        XCTAssertEqual(map, [123: 1, 456: 123])
    }

    // MARK: - Atomic write to a missing destination (first state write)

    func testWriteAtomicallyCreatesMissingDestination() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let url = dir.appendingPathComponent("state.json")

        try FilePersistence.writeAtomically(Data("{\"a\":1}".utf8), to: url)

        XCTAssertEqual(try Data(contentsOf: url), Data("{\"a\":1}".utf8))
        try? FileManager.default.removeItem(at: dir)
    }

    func testWriteAtomicallyOverwritesExistingDestination() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("state.json")
        try Data("old".utf8).write(to: url)

        try FilePersistence.writeAtomically(Data("new".utf8), to: url)

        XCTAssertEqual(try Data(contentsOf: url), Data("new".utf8))
        try? FileManager.default.removeItem(at: dir)
    }

    // MARK: - Moved-server banner

    func testMovedBannerShowsWhenUserNavigatedElsewhere() {
        XCTAssertEqual(
            pendingRetargetURL(
                currentURL: "https://example.com/",
                displayedURL: "https://example.com/",
                previousDefaultURL: "http://localhost:40001/",
                nextDefaultURL: "http://localhost:5173/",
                connectionError: false,
                isWaitingForServer: false
            ),
            "http://localhost:5173/"
        )
    }

    func testMovedBannerHiddenWhenAutoRetargetApplies() {
        XCTAssertNil(pendingRetargetURL(
            currentURL: "http://localhost:40001/",
            displayedURL: "http://localhost:40001/",
            previousDefaultURL: "http://localhost:40001/",
            nextDefaultURL: "http://localhost:5173/",
            connectionError: false,
            isWaitingForServer: false
        ))
    }

    func testMovedBannerHiddenWhileWaiting() {
        XCTAssertNil(pendingRetargetURL(
            currentURL: "https://example.com/",
            displayedURL: "https://example.com/",
            previousDefaultURL: "http://localhost:40001/",
            nextDefaultURL: "http://localhost:5173/",
            connectionError: false,
            isWaitingForServer: true
        ))
    }

    func testMovedBannerHiddenWhenAlreadyOnNewURL() {
        XCTAssertNil(pendingRetargetURL(
            currentURL: "http://localhost:5173/",
            displayedURL: "http://localhost:5173/",
            previousDefaultURL: "http://localhost:40001/",
            nextDefaultURL: "http://localhost:5173/",
            connectionError: false,
            isWaitingForServer: false
        ))
    }
}
