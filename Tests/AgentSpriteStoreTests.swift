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

    func testAvatarResolvesForKnownAndUnknownTypes() {
        let store = AgentSpriteStore.shared
        // Numbered set member.
        XCTAssertNotNil(store.avatar(name: "Explore", palette: 1, variant: 2))
        // Cycling variant reuses set member.
        XCTAssertNotNil(store.avatar(name: "Explore", palette: 1, variant: 4))
        // Type without a set falls back to single portrait, then legacy sheets.
        XCTAssertNotNil(store.avatar(name: "SomeCustomAgent", palette: 2, variant: 0))
        // Main agent.
        XCTAssertNotNil(store.avatar(name: "Claude", palette: 0, variant: 0))
    }
}
