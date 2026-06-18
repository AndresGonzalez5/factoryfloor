// ABOUTME: Tests for MonacoLanguage.id(for:) filename → Monaco languageId mapping.
// ABOUTME: Characterizes the contract shared by the Editor and the Changes (diff) view.

@testable import FactoryFloor
import XCTest

final class MonacoLanguageTests: XCTestCase {
    // MARK: - Common source extensions

    func testSwiftExtensionMapsToSwift() {
        XCTAssertEqual(MonacoLanguage.id(for: "foo.swift"), "swift")
    }

    func testTypeScriptExtensionMapsToTypeScript() {
        XCTAssertEqual(MonacoLanguage.id(for: "a.ts"), "typescript")
    }

    func testTypeScriptReactExtensionMapsToTypeScriptReact() {
        // The implementation distinguishes .tsx from .ts.
        XCTAssertEqual(MonacoLanguage.id(for: "a.tsx"), "typescriptreact")
    }

    func testJavaScriptExtensionMapsToJavaScript() {
        XCTAssertEqual(MonacoLanguage.id(for: "a.js"), "javascript")
    }

    func testJavaScriptReactExtensionMapsToJavaScriptReact() {
        XCTAssertEqual(MonacoLanguage.id(for: "a.jsx"), "javascriptreact")
    }

    func testPythonExtensionMapsToPython() {
        XCTAssertEqual(MonacoLanguage.id(for: "a.py"), "python")
    }

    func testRustExtensionMapsToRust() {
        XCTAssertEqual(MonacoLanguage.id(for: "a.rs"), "rust")
    }

    func testGoExtensionMapsToGo() {
        XCTAssertEqual(MonacoLanguage.id(for: "main.go"), "go")
    }

    // MARK: - Multi-extension aliases collapse to one id

    func testAlternateJavaScriptExtensionsMapToJavaScript() {
        XCTAssertEqual(MonacoLanguage.id(for: "a.mjs"), "javascript")
        XCTAssertEqual(MonacoLanguage.id(for: "a.cjs"), "javascript")
    }

    func testYamlAliasesMapToYaml() {
        XCTAssertEqual(MonacoLanguage.id(for: "ci.yml"), "yaml")
        XCTAssertEqual(MonacoLanguage.id(for: "ci.yaml"), "yaml")
    }

    func testShellExtensionsMapToShellscript() {
        XCTAssertEqual(MonacoLanguage.id(for: "run.sh"), "shellscript")
        XCTAssertEqual(MonacoLanguage.id(for: "run.zsh"), "shellscript")
    }

    // MARK: - Case-insensitive extensions

    func testExtensionMatchingIsCaseInsensitive() {
        XCTAssertEqual(MonacoLanguage.id(for: "Foo.SWIFT"), "swift")
        XCTAssertEqual(MonacoLanguage.id(for: "A.TS"), "typescript")
    }

    // MARK: - Extensionless filenames matched by basename

    func testMakefileMapsToMakefile() {
        XCTAssertEqual(MonacoLanguage.id(for: "Makefile"), "makefile")
    }

    func testDockerfileMapsToDockerfile() {
        XCTAssertEqual(MonacoLanguage.id(for: "Dockerfile"), "dockerfile")
    }

    func testBasenameMatchIsCaseInsensitive() {
        XCTAssertEqual(MonacoLanguage.id(for: "MAKEFILE"), "makefile")
        XCTAssertEqual(MonacoLanguage.id(for: "dockerfile"), "dockerfile")
    }

    func testFullPathResolvesByLastComponent() {
        XCTAssertEqual(MonacoLanguage.id(for: "src/models/foo.swift"), "swift")
        XCTAssertEqual(MonacoLanguage.id(for: "build/Dockerfile"), "dockerfile")
    }

    // MARK: - Unknown / no extension fall back to plaintext

    func testUnknownExtensionFallsBackToPlaintext() {
        XCTAssertEqual(MonacoLanguage.id(for: "data.xyzzy"), "plaintext")
    }

    func testNoExtensionUnknownBasenameFallsBackToPlaintext() {
        XCTAssertEqual(MonacoLanguage.id(for: "LICENSE"), "plaintext")
    }

    func testEmptyStringFallsBackToPlaintext() {
        XCTAssertEqual(MonacoLanguage.id(for: ""), "plaintext")
    }
}
