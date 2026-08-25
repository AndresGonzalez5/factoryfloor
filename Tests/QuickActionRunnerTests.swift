// ABOUTME: Tests for parsing `opencode run --format json` streams into
// ABOUTME: human-readable quick-action summaries and PR artifact links.

@testable import FactoryFloor
import XCTest

final class QuickActionRunnerTests: XCTestCase {

    private func jsonl(_ lines: [String]) -> String {
        lines.joined(separator: "\n") + "\n"
    }

    // MARK: - Summary extraction

    func testParseReturnsFinalAssistantTextPart() {
        let stream = jsonl([
            #"{"type":"message.updated","timestamp":1,"sessionID":"s","info":{"id":"m1","role":"assistant","modelID":"kimi-k2"}}"#,
            #"{"type":"message.part.updated","timestamp":2,"sessionID":"s","part":{"id":"p1","type":"text","text":"Looking at the changes.","messageID":"m1"}}"#,
            #"{"type":"message.part.updated","timestamp":3,"sessionID":"s","part":{"id":"p2","type":"text","text":"Committed as abc1234." ,"messageID":"m1"}}"#,
        ])
        let (summary, url) = QuickActionRunner.parseOpencodeStream(stream)
        XCTAssertEqual(summary, "Committed as abc1234.")
        XCTAssertNil(url)
    }

    func testParseIgnoresUserTextPartsWhenAssistantKnown() {
        let stream = jsonl([
            #"{"type":"message.updated","timestamp":1,"sessionID":"s","info":{"id":"u1","role":"user"}}"#,
            #"{"type":"message.part.updated","timestamp":2,"sessionID":"s","part":{"id":"up","type":"text","text":"Please commit.","messageID":"u1"}}"#,
            #"{"type":"message.updated","timestamp":3,"sessionID":"s","info":{"id":"m1","role":"assistant"}}"#,
            #"{"type":"message.part.updated","timestamp":4,"sessionID":"s","part":{"id":"ap","type":"text","text":"Done.","messageID":"m1"}}"#,
        ])
        let (summary, _) = QuickActionRunner.parseOpencodeStream(stream)
        XCTAssertEqual(summary, "Done.")
    }

    func testParseAcceptsTextPartsWhenAssistantSetUnknown() {
        // Shape drift tolerance: no message.updated lines at all.
        let stream = jsonl([
            #"{"type":"message.part.updated","timestamp":1,"sessionID":"s","properties":{"part":{"id":"p1","type":"text","text":"Fallback text."}}}"#,
        ])
        let (summary, _) = QuickActionRunner.parseOpencodeStream(stream)
        XCTAssertEqual(summary, "Fallback text.")
    }

    func testParsePrefersPropertiesEnvelope() {
        let stream = jsonl([
            #"{"type":"message.part.updated","timestamp":1,"sessionID":"s","properties":{"info":{"id":"m1","role":"assistant"},"part":{"id":"p1","type":"text","text":"Nested envelope." ,"messageID":"m1"}}}"#,
        ])
        let (summary, _) = QuickActionRunner.parseOpencodeStream(stream)
        XCTAssertEqual(summary, "Nested envelope.")
    }

    func testParseSkipsEmptyAndNonTextParts() {
        let stream = jsonl([
            #"{"type":"message.updated","timestamp":1,"sessionID":"s","info":{"id":"m1","role":"assistant"}}"#,
            #"{"type":"message.part.updated","timestamp":2,"sessionID":"s","part":{"id":"t1","type":"tool","tool":"bash"}}"#,
            #"{"type":"message.part.updated","timestamp":3,"sessionID":"s","part":{"id":"t2","type":"text","text":"   ","messageID":"m1"}}"#,
            #"not json at all"#,
            #"{"type":"message.part.updated","timestamp":4,"sessionID":"s","part":{"id":"t3","type":"text","text":"Real answer.","messageID":"m1"}}"#,
        ])
        let (summary, _) = QuickActionRunner.parseOpencodeStream(stream)
        XCTAssertEqual(summary, "Real answer.")
    }

    func testParseEmptyStreamYieldsNil() {
        let (summary, url) = QuickActionRunner.parseOpencodeStream("")
        XCTAssertNil(summary)
        XCTAssertNil(url)
    }

    // MARK: - Artifact extraction

    func testParseExtractsPullRequestURLFromSummary() {
        let stream = jsonl([
            #"{"type":"message.part.updated","timestamp":1,"sessionID":"s","part":{"id":"p1","type":"text","text":"Created PR: https://github.com/acme/app/pull/14 — ready for review."}}"#,
        ])
        let (_, url) = QuickActionRunner.parseOpencodeStream(stream)
        XCTAssertEqual(url, "https://github.com/acme/app/pull/14")
    }

    func testParseExtractsURLFromRawOutputWhenMissingFromSummary() {
        let stream = jsonl([
            #"{"type":"session.error","timestamp":1}"#,
            #"{"type":"message.part.updated","timestamp":2,"sessionID":"s","part":{"id":"p1","type":"text","text":"Opened the pull request."}}"#,
            #"view it at https://github.com/acme/app/pull/7 anytime"#,
        ])
        let (summary, url) = QuickActionRunner.parseOpencodeStream(stream)
        XCTAssertEqual(summary, "Opened the pull request.")
        XCTAssertEqual(url, "https://github.com/acme/app/pull/7")
    }

    func testParseStopsURLAtPunctuation() {
        let stream = jsonl([
            #"{"type":"message.part.updated","timestamp":1,"sessionID":"s","part":{"id":"p1","type":"text","text":"Opened https://github.com/acme/app/pull/14."}}"#,
        ])
        let (_, url) = QuickActionRunner.parseOpencodeStream(stream)
        XCTAssertEqual(url, "https://github.com/acme/app/pull/14")
    }

    func testArtifactURLLabelDistinguishesPullRequests() {
        // Sanity on the shape the UI relies on for label selection.
        XCTAssertTrue("https://github.com/acme/app/pull/14".contains("/pull/"))
        XCTAssertFalse("https://github.com/acme/app/issues/14".contains("/pull/"))
    }
}
