// ABOUTME: Tests for ContextMeter's token formatting and the combined
// ABOUTME: capacity/quality severity coloring.

@testable import FactoryFloor
import XCTest

final class ContextMeterTests: XCTestCase {
    // MARK: - Token formatting

    func testCompactTokenCountBoundaries() {
        XCTAssertEqual(ContextMeter.compactTokenCount(0), "0")
        XCTAssertEqual(ContextMeter.compactTokenCount(999), "999")
        XCTAssertEqual(ContextMeter.compactTokenCount(1_000), "1.0k")
        XCTAssertEqual(ContextMeter.compactTokenCount(12_340), "12.3k")
        XCTAssertEqual(ContextMeter.compactTokenCount(145_234), "145k")
        XCTAssertEqual(ContextMeter.compactTokenCount(999_999), "999k")
        XCTAssertEqual(ContextMeter.compactTokenCount(1_000_000), "1.0M")
        XCTAssertEqual(ContextMeter.compactTokenCount(1_234_567), "1.2M")
        // Defensive: negative counts clamp to zero.
        XCTAssertEqual(ContextMeter.compactTokenCount(-5), "0")
    }

    // MARK: - Severity matrix

    private let threshold = ContextLimits.qualityCautionThreshold

    func testCapacityAloneDrivesColorOnSmallWindows() {
        // 100k of a 200k window = 50% capacity, under quality threshold.
        XCTAssertEqual(ContextMeter.severity(fraction: 0.5, usedTokens: 100_000), 0)
        // 70% capacity -> orange.
        XCTAssertEqual(ContextMeter.severity(fraction: 0.7, usedTokens: 140_000), 1)
        // 85%+ capacity -> red.
        XCTAssertEqual(ContextMeter.severity(fraction: 0.9, usedTokens: 180_000), 2)
    }

    func testQualityThresholdFloorsAtOrangeOnLargeWindows() {
        // Exactly at the threshold -> caution.
        XCTAssertEqual(ContextMeter.severity(fraction: 0.25, usedTokens: threshold), 1)
        // One token under -> still green.
        XCTAssertEqual(ContextMeter.severity(fraction: 0.25, usedTokens: threshold - 1), 0)
    }

    func testQualityAloneNeverExceedsOrangeBelowCritical() {
        // Past caution but under critical on a roomy window: orange.
        XCTAssertEqual(ContextMeter.severity(fraction: 0.25, usedTokens: 250_000), 1)
    }

    func testQualityCriticalThresholdForcesRedOnAnyWindow() {
        // Exactly at the critical line -> red even with a roomy window.
        XCTAssertEqual(ContextMeter.severity(fraction: 0.25, usedTokens: threshold + 100_000), 2)
        // One token under -> still orange.
        XCTAssertEqual(
            ContextMeter.severity(fraction: 0.25, usedTokens: threshold + 100_000 - 1), 1)
        // Capacity and quality agree deep in the decay zone.
        XCTAssertEqual(ContextMeter.severity(fraction: 0.9, usedTokens: 400_000), 2)
    }

    /// Calm meters render neutral gray — vivid green pulled too much attention.
    func testSeverityColorsAreGrayOrangeRed() {
        XCTAssertEqual(ContextMeter.severityColor(0), .gray)
        XCTAssertEqual(ContextMeter.severityColor(1), .orange)
        XCTAssertEqual(ContextMeter.severityColor(2), .red)
    }
}
