// ABOUTME: Tests for SurfaceEventLogger per-workstream surface lifecycle log files.
// ABOUTME: Validates gating on detailedLogging, append behavior, preview truncation, and cleanup.

@testable import FactoryFloor
import XCTest

final class SurfaceEventLoggerTests: XCTestCase {
    private let testWorkstreamID = UUID(uuidString: "12345678-1234-1234-1234-123456789abc")!

    override func setUp() {
        super.setUp()
        try? FileManager.default.removeItem(at: SurfaceEventLogger.logFileURL(for: testWorkstreamID))
        UserDefaults.standard.set(true, forKey: "factoryfloor.detailedLogging")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: SurfaceEventLogger.logFileURL(for: testWorkstreamID))
        UserDefaults.standard.removeObject(forKey: "factoryfloor.detailedLogging")
        super.tearDown()
    }

    func testLogInfoWritesFileWhenEnabled() {
        SurfaceEventLogger.logInfo(workstreamID: testWorkstreamID, "surface-created cmd=opencode")
        XCTAssertTrue(FileManager.default.fileExists(atPath: SurfaceEventLogger.logFileURL(for: testWorkstreamID).path))
    }

    func testLogSkipsFileWhenDisabled() {
        UserDefaults.standard.set(false, forKey: "factoryfloor.detailedLogging")
        SurfaceEventLogger.logInfo(workstreamID: testWorkstreamID, "surface-created cmd=opencode")
        SurfaceEventLogger.logDetailed(workstreamID: testWorkstreamID, "surface-reused")
        XCTAssertFalse(FileManager.default.fileExists(atPath: SurfaceEventLogger.logFileURL(for: testWorkstreamID).path))
    }

    func testLogAppendsMultipleLines() throws {
        SurfaceEventLogger.logInfo(workstreamID: testWorkstreamID, "surface-created")
        SurfaceEventLogger.logDetailed(workstreamID: testWorkstreamID, "surface-reused")
        SurfaceEventLogger.logInfo(workstreamID: testWorkstreamID, "surface-kept-alive")

        let contents = try String(contentsOf: SurfaceEventLogger.logFileURL(for: testWorkstreamID), encoding: .utf8)
        let lines = contents.split(separator: "\n", omittingEmptySubsequences: true)
        XCTAssertEqual(lines.count, 3)
    }

    func testPreviewTruncatesLongCommands() {
        XCTAssertEqual(SurfaceEventLogger.preview(nil), "<shell>")
        XCTAssertEqual(SurfaceEventLogger.preview(""), "<shell>")
        XCTAssertEqual(SurfaceEventLogger.preview("opencode --session abc"), "opencode --session abc")
        let long = String(repeating: "x", count: 200)
        let previewed = SurfaceEventLogger.preview(long, limit: 160)
        XCTAssertEqual(previewed.count, 161)
        XCTAssertTrue(previewed.hasSuffix("…"))
    }

    func testRemoveLogDeletesFile() {
        SurfaceEventLogger.logInfo(workstreamID: testWorkstreamID, "surface-created")
        XCTAssertTrue(FileManager.default.fileExists(atPath: SurfaceEventLogger.logFileURL(for: testWorkstreamID).path))
        SurfaceEventLogger.removeLog(for: testWorkstreamID)
        XCTAssertFalse(FileManager.default.fileExists(atPath: SurfaceEventLogger.logFileURL(for: testWorkstreamID).path))
    }

    func testSurfaceLogUsesDistinctFileFromLaunchLog() {
        XCTAssertNotEqual(
            SurfaceEventLogger.logFileURL(for: testWorkstreamID).lastPathComponent,
            LaunchLogger.logFileURL(for: testWorkstreamID).lastPathComponent
        )
    }
}
