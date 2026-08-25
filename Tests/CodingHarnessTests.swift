// ABOUTME: Tests for the CodingHarness enum.
// ABOUTME: Validates raw values, display metadata, and Codable stability.

@testable import FactoryFloor
import XCTest

final class CodingHarnessTests: XCTestCase {
    func testRawValuesAreStable() {
        // Raw values persist in UserDefaults; changing them breaks stored workstreams.
        XCTAssertEqual(CodingHarness.claudeCode.rawValue, "claudeCode")
        XCTAssertEqual(CodingHarness.opencode.rawValue, "opencode")
    }

    func testDecodeFromRawValue() {
        XCTAssertEqual(CodingHarness(rawValue: "claudeCode"), .claudeCode)
        XCTAssertEqual(CodingHarness(rawValue: "opencode"), .opencode)
        XCTAssertNil(CodingHarness(rawValue: "unknown"))
    }

    func testCLINames() {
        XCTAssertEqual(CodingHarness.claudeCode.cliName, "claude")
        XCTAssertEqual(CodingHarness.opencode.cliName, "opencode")
    }

    func testAllCases() {
        XCTAssertEqual(CodingHarness.allCases, [.claudeCode, .opencode])
    }

    func testInstallURLsAreValid() {
        for harness in CodingHarness.allCases {
            XCTAssertNotNil(URL(string: harness.installURL.absoluteString))
        }
    }

    func testCodableRoundTrip() throws {
        for harness in CodingHarness.allCases {
            let data = try JSONEncoder().encode(harness)
            let decoded = try JSONDecoder().decode(CodingHarness.self, from: data)
            XCTAssertEqual(decoded, harness)
        }
    }
}
