// ABOUTME: Tests for ChangesView's pure diff-payload classification.
// ABOUTME: Validates binary/deferred/normal decisions and the large-file thresholds.

@testable import FactoryFloor
import XCTest

final class ChangesPayloadTests: XCTestCase {
    // MARK: - Binary takes precedence

    func testBinaryFileIsClassifiedBinaryRegardlessOfSize() {
        let result = ChangesView.classify(isBinary: true, changedLines: 10, sizeHint: 10)
        XCTAssertEqual(result, .binary)
    }

    func testBinaryWinsEvenWhenAlsoOversize() {
        // A huge binary is still classified binary (no content read, no diff body).
        let result = ChangesView.classify(isBinary: true, changedLines: 99_999, sizeHint: 9_000_000)
        XCTAssertEqual(result, .binary)
    }

    // MARK: - Deferred (large-file guard)

    func testDeferredWhenChangedLinesExceedThreshold() {
        let result = ChangesView.classify(isBinary: false, changedLines: 1501, sizeHint: 0)
        XCTAssertEqual(result, .deferred)
    }

    func testDeferredWhenSizeHintExceedsThreshold() {
        let result = ChangesView.classify(isBinary: false, changedLines: 0, sizeHint: 500 * 1024 + 1)
        XCTAssertEqual(result, .deferred)
    }

    func testNotDeferredAtExactChangedLinesThreshold() {
        // Threshold is "> 1500", so exactly 1500 is still normal.
        let result = ChangesView.classify(isBinary: false, changedLines: 1500, sizeHint: 0)
        XCTAssertEqual(result, .normal)
    }

    func testNotDeferredAtExactSizeThreshold() {
        // Threshold is "> 500KB", so exactly 500KB is still normal.
        let result = ChangesView.classify(isBinary: false, changedLines: 0, sizeHint: 500 * 1024)
        XCTAssertEqual(result, .normal)
    }

    // MARK: - Normal

    func testSmallTextFileIsNormal() {
        let result = ChangesView.classify(isBinary: false, changedLines: 12, sizeHint: 2048)
        XCTAssertEqual(result, .normal)
    }

    func testEmptyFileIsNormal() {
        let result = ChangesView.classify(isBinary: false, changedLines: 0, sizeHint: 0)
        XCTAssertEqual(result, .normal)
    }

    // MARK: - Threshold constants

    func testThresholdConstants() {
        XCTAssertEqual(ChangesView.largeFileLineThreshold, 1500)
        XCTAssertEqual(ChangesView.largeFileByteThreshold, 500 * 1024)
    }
}
