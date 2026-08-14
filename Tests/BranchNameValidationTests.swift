// ABOUTME: Tests for GitOperations.isValidBranchName.
// ABOUTME: Validates git check-ref-format rules used by the workstream naming dialog.

@testable import FactoryFloor
import XCTest

final class BranchNameValidationTests: XCTestCase {
    func testValidBranchNames() {
        let valid = [
            "merge-quick-pipe",
            "feat/foo",
            "fix-bug-123",
            "feature.one",
            "main",
            "a/b/c",
            "v1.2.3",
        ]
        for name in valid {
            XCTAssertTrue(GitOperations.isValidBranchName(name), "expected \(name) to be valid")
        }
    }

    func testEmptyNameIsInvalid() {
        XCTAssertFalse(GitOperations.isValidBranchName(""))
        XCTAssertFalse(GitOperations.isValidBranchName("   "))
    }

    func testRejectsForbiddenCharacters() {
        let invalid = [
            "has space",
            "tilde~name",
            "caret^name",
            "colon:name",
            "question?name",
            "star*name",
            "bracket[name",
            "backslash\\name",
        ]
        for name in invalid {
            XCTAssertFalse(GitOperations.isValidBranchName(name), "expected \(name) to be invalid")
        }
    }

    func testRejectsSequences() {
        let invalid = [
            "dotdot..name",
            "at@{name",
            "double//slash",
        ]
        for name in invalid {
            XCTAssertFalse(GitOperations.isValidBranchName(name), "expected \(name) to be invalid")
        }
    }

    func testRejectsLeadingHyphenAndTrailingPunctuation() {
        XCTAssertFalse(GitOperations.isValidBranchName("-leading"))
        XCTAssertFalse(GitOperations.isValidBranchName("trailing."))
        XCTAssertFalse(GitOperations.isValidBranchName("trailing/"))
        XCTAssertFalse(GitOperations.isValidBranchName("ends.lock"))
    }

    func testRejectsControlCharacters() {
        XCTAssertFalse(GitOperations.isValidBranchName("new\nline"))
        XCTAssertFalse(GitOperations.isValidBranchName("tab\tname"))
    }
}