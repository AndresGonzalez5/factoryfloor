// ABOUTME: Tests for agent sprite resolution: type-keyed sets, variant
// ABOUTME: cycling, name normalization, and bundle-backed fallbacks.

@testable import FactoryFloor
import XCTest

@MainActor
final class AgentSpriteStoreTests: XCTestCase {

    // MARK: - Name normalization

    func testNormalizeTypeName() {
        XCTAssertEqual(AgentSpriteStore.normalizeTypeName("Explore"), "explore")
        XCTAssertEqual(AgentSpriteStore.normalizeTypeName("general-purpose"), "generalpurpose")
        XCTAssertEqual(AgentSpriteStore.normalizeTypeName("Plan"), "plan")
        XCTAssertEqual(AgentSpriteStore.normalizeTypeName("Claude"), "claude")
        XCTAssertEqual(AgentSpriteStore.normalizeTypeName("My Agent (v2)"), "myagentv2")
    }

    // MARK: - Variant cycling math

    func testSpriteVariantIndexCycles() {
        XCTAssertEqual(AgentSpriteStore.spriteVariantIndex(variant: 0, count: 4), 0)
        XCTAssertEqual(AgentSpriteStore.spriteVariantIndex(variant: 3, count: 4), 3)
        XCTAssertEqual(AgentSpriteStore.spriteVariantIndex(variant: 4, count: 4), 0)
        XCTAssertEqual(AgentSpriteStore.spriteVariantIndex(variant: 5, count: 4), 1)
        XCTAssertEqual(AgentSpriteStore.spriteVariantIndex(variant: 7, count: 1), 0)
        // Degenerate counts stay safe.
        XCTAssertEqual(AgentSpriteStore.spriteVariantIndex(variant: 3, count: 0), 0)
    }

    // MARK: - Bundle-backed resolution (tests run inside the host app)

    func testExploreSetHasFourSprites() {
        let store = AgentSpriteStore.shared
        XCTAssertEqual(store.spriteFile(for: "explore", variant: 0), "avatar_explore_1")
        XCTAssertEqual(store.spriteFile(for: "explore", variant: 3), "avatar_explore_4")
        XCTAssertEqual(store.spriteFile(for: "explore", variant: 4), "avatar_explore_1")
    }

    func testUnknownTypeHasNoNumberedSet() {
        XCTAssertNil(AgentSpriteStore.shared.spriteFile(for: "definitelynotatype", variant: 0))
    }

    // MARK: - Alias resolution

    func testResolutionKeysTryOwnArtBeforeAlias() {
        XCTAssertEqual(AgentSpriteStore.resolutionKeys(for: "scout"), ["scout", "explore"])
        XCTAssertEqual(AgentSpriteStore.resolutionKeys(for: "build"), ["build", "claude"])
        XCTAssertEqual(AgentSpriteStore.resolutionKeys(for: "general"), ["general", "generalpurpose"])
        // Types with no alias resolve only themselves.
        XCTAssertEqual(AgentSpriteStore.resolutionKeys(for: "claude"), ["claude"])
        XCTAssertEqual(AgentSpriteStore.resolutionKeys(for: "explore"), ["explore"])
        // Empty names resolve to nothing.
        XCTAssertEqual(AgentSpriteStore.resolutionKeys(for: ""), [])
    }

    func testAliasedOpenCodeTypesResolveToArt() {
        let store = AgentSpriteStore.shared
        // Scout has no dedicated art yet; the alias fills the gap with the
        // explore set.
        XCTAssertNotNil(store.avatar(name: "Scout", palette: 1, variant: 0))
        XCTAssertNotNil(store.avatar(name: "general", palette: 1, variant: 0))
        XCTAssertNotNil(store.avatar(name: "build", palette: 1, variant: 0))
        XCTAssertNotNil(store.avatar(name: "plan", palette: 1, variant: 0))
    }

    func testAvatarResolvesForKnownAndUnknownTypes() {
        let store = AgentSpriteStore.shared
        // Numbered set member.
        XCTAssertNotNil(store.avatar(name: "Explore", palette: 1, variant: 2))
        // Cycling variant reuses set member.
        XCTAssertNotNil(store.avatar(name: "Explore", palette: 1, variant: 4))
        // Main agents for both harnesses.
        XCTAssertNotNil(store.avatar(name: "Claude", palette: 0, variant: 0))
        XCTAssertNotNil(store.avatar(name: "OpenCode", palette: 0, variant: 0))
        // Type without any art resolves to nil; views substitute a
        // neutral SF Symbol placeholder.
        XCTAssertNil(store.avatar(name: "SomeCustomAgent", palette: 2, variant: 0))
    }
}
