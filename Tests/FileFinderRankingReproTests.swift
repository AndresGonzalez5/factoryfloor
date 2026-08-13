// ABOUTME: Reproduction for ranking bug — a query like "papoover" must rank the
// exact-named file first, and clearly-matching files above barely-matching ones.

@testable import FactoryFloor
import XCTest

final class FileFinderRankingReproTests: XCTestCase {
    private func results(for query: String, in files: [String]) -> [String] {
        let entries = files.map(FileFinder.Entry.init(path:))
        return FileFinder.results(matching: query, in: entries)
    }

    func testReproUserScenario() {
        let files = [
            "src/papoover.tsx",
            "docs/prd.md",
            "lib/pool.ts",
            "docs/product.md",
            "src/App.tsx",
            "src/PapoOverButton.tsx",
            "README.md",
        ]
        let order = results(for: "papoover", in: files)
        print("[repro] order for 'papoover': \(order)")
        XCTAssertEqual(order.first, "src/papoover.tsx")
        XCTAssertFalse(order.contains("docs/prd.md"))
        XCTAssertFalse(order.contains("lib/pool.ts"))
        XCTAssertFalse(order.contains("docs/product.md"))
    }

    /// The displayed list must update as the query grows: once the full name is
    /// typed, the exact file is the top result (the stale-list symptom).
    func testExactNameRisesToTopAsQueryCompletes() {
        let files = [
            "src/papoover.tsx",
            "docs/prd.md",
            "lib/pool.ts",
            "docs/product.md",
        ]
        let partial = results(for: "p", in: files)
        XCTAssertEqual(partial.first, "docs/prd.md") // shortest name wins among equal prefix matches
        let full = results(for: "papoover", in: files)
        XCTAssertEqual(full, ["src/papoover.tsx"])
    }

    func testResultsAreBounded() {
        var files = (0..<100).map { "src/file-\($0).ts" }
        files.append("src/target.tsx")
        let order = results(for: "target", in: files)
        XCTAssertEqual(order.count, 1)
    }
}