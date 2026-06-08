// ABOUTME: Tests for the Space model and SpaceStore persistence.
// ABOUTME: Validates creation, identity, equality, serialization, and UserDefaults round-trips.

@testable import FactoryFloor
import XCTest

final class SpaceTests: XCTestCase {
    private static let testSuiteName = "factoryfloor.space.tests"
    private let testDefaults = UserDefaults(suiteName: testSuiteName)!

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: Self.testSuiteName)
        super.tearDown()
    }

    func testCreation() {
        let space = Space(name: "Work", emoji: "💼")
        XCTAssertEqual(space.name, "Work")
        XCTAssertEqual(space.emoji, "💼")
    }

    func testUniqueIDs() {
        let a = Space(name: "a", emoji: "🅰️")
        let b = Space(name: "b", emoji: "🅱️")
        XCTAssertNotEqual(a.id, b.id)
    }

    func testExplicitID() {
        let id = UUID()
        let space = Space(name: "test", emoji: "🚀", id: id)
        XCTAssertEqual(space.id, id)
    }

    func testHashable() {
        let id = UUID()
        let a = Space(name: "test", emoji: "🚀", id: id)
        let b = Space(name: "test", emoji: "🚀", id: id)
        XCTAssertEqual(a, b)

        var set: Set<Space> = []
        set.insert(a)
        XCTAssertTrue(set.contains(b))
    }

    func testMutableProperties() {
        var space = Space(name: "old", emoji: "🐌")
        space.name = "new"
        space.emoji = "⚡️"
        XCTAssertEqual(space.name, "new")
        XCTAssertEqual(space.emoji, "⚡️")
    }

    func testCodableRoundTrip() throws {
        let spaces = [
            Space(name: "Personal", emoji: "🏠"),
            Space(name: "Work", emoji: "💼"),
        ]
        let data = try JSONEncoder().encode(spaces)
        let decoded = try JSONDecoder().decode([Space].self, from: data)
        XCTAssertEqual(spaces, decoded)
    }

    func testCodablePreservesFields() throws {
        let original = Space(name: "Research", emoji: "🔬")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Space.self, from: data)
        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.name, decoded.name)
        XCTAssertEqual(original.emoji, decoded.emoji)
    }

    func testSpaceStoreRoundTrip() {
        let spaces = [
            Space(name: "one", emoji: "1️⃣"),
            Space(name: "two", emoji: "2️⃣"),
        ]
        SpaceStore.save(spaces, defaults: testDefaults)
        let loaded = SpaceStore.load(defaults: testDefaults)
        XCTAssertEqual(spaces, loaded)
    }

    func testSpaceStoreLoadEmptyReturnsEmpty() {
        let loaded = SpaceStore.load(defaults: testDefaults)
        XCTAssertTrue(loaded.isEmpty)
    }
}
