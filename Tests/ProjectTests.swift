// ABOUTME: Tests for Project and Workstream models.
// ABOUTME: Validates creation, identity, equality, serialization, and workstream management.

@testable import FactoryFloor
import XCTest

final class ProjectTests: XCTestCase {
    private static let testSuiteName = "factoryfloor.tests"
    private let testDefaults = UserDefaults(suiteName: testSuiteName)!

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: Self.testSuiteName)
        super.tearDown()
    }

    func testCreation() {
        let project = Project(name: "myapp", directory: "/Users/test/myapp")
        XCTAssertEqual(project.name, "myapp")
        XCTAssertEqual(project.directory, "/Users/test/myapp")
    }

    func testUniqueIDs() {
        let a = Project(name: "a", directory: "/a")
        let b = Project(name: "b", directory: "/b")
        XCTAssertNotEqual(a.id, b.id)
    }

    func testExplicitID() {
        let id = UUID()
        let project = Project(name: "test", directory: "/test", id: id)
        XCTAssertEqual(project.id, id)
    }

    func testHashable() {
        let id = UUID()
        let a = Project(name: "test", directory: "/test", id: id)
        let b = Project(name: "test", directory: "/test", id: id)
        XCTAssertEqual(a, b)

        var set: Set<Project> = []
        set.insert(a)
        XCTAssertTrue(set.contains(b))
    }

    func testMutableProperties() {
        var project = Project(name: "old", directory: "/old")
        project.name = "new"
        project.directory = "/new"
        XCTAssertEqual(project.name, "new")
        XCTAssertEqual(project.directory, "/new")
    }

    func testCodableRoundTrip() throws {
        let projects = [
            Project(name: "alpha", directory: "/Users/test/alpha"),
            Project(name: "beta", directory: "/Users/test/beta"),
        ]
        let data = try JSONEncoder().encode(projects)
        let decoded = try JSONDecoder().decode([Project].self, from: data)
        XCTAssertEqual(projects, decoded)
    }

    func testCodablePreservesID() throws {
        let original = Project(name: "test", directory: "/test")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Project.self, from: data)
        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.name, decoded.name)
        XCTAssertEqual(original.directory, decoded.directory)
    }

    func testProjectStoreRoundTrip() {
        let projects = [
            Project(name: "one", directory: "/one"),
            Project(name: "two", directory: "/two"),
        ]
        ProjectStore.save(projects, defaults: testDefaults)
        let loaded = ProjectStore.load(defaults: testDefaults)
        XCTAssertEqual(projects, loaded)
    }

    func testProjectDefaultsToNoWorkstreams() {
        let project = Project(name: "test", directory: "/test")
        XCTAssertTrue(project.workstreams.isEmpty)
    }

    func testWorkstreamCreation() {
        let ws = Workstream(name: "feature-auth")
        XCTAssertEqual(ws.name, "feature-auth")
    }

    func testProjectWithWorkstreams() {
        var project = Project(name: "app", directory: "/app")
        project.workstreams.append(Workstream(name: "backend"))
        project.workstreams.append(Workstream(name: "frontend"))
        XCTAssertEqual(project.workstreams.count, 2)
        XCTAssertNotEqual(project.workstreams[0].id, project.workstreams[1].id)
    }

    func testWorkstreamsCodableRoundTrip() throws {
        let project = Project(
            name: "app",
            directory: "/app",
            workstreams: [
                Workstream(name: "main"),
                Workstream(name: "bugfix"),
            ]
        )
        let data = try JSONEncoder().encode(project)
        let decoded = try JSONDecoder().decode(Project.self, from: data)
        XCTAssertEqual(project, decoded)
        XCTAssertEqual(decoded.workstreams.count, 2)
        XCTAssertEqual(decoded.workstreams[0].name, "main")
        XCTAssertEqual(decoded.workstreams[1].name, "bugfix")
    }

    func testCodableRoundTripWithSpaceID() throws {
        let spaceID = UUID()
        let original = Project(name: "alpha", directory: "/Users/test/alpha", spaceID: spaceID)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Project.self, from: data)
        XCTAssertEqual(decoded.spaceID, spaceID)
        XCTAssertEqual(original, decoded)
    }

    func testLegacyJSONWithoutSpaceIDDecodesToNil() throws {
        // A throwaway struct mirroring the OLD Project shape (no spaceID).
        // Matching the field set lets the default JSONEncoder/Decoder date
        // handling stay consistent, avoiding hardcoded date formats.
        struct LegacyProject: Codable {
            let id: UUID
            var name: String
            var directory: String
            var workstreams: [Workstream]
            var lastAccessedAt: Date
        }

        let legacy = LegacyProject(
            id: UUID(),
            name: "legacy",
            directory: "/legacy",
            workstreams: [Workstream(name: "main")],
            lastAccessedAt: Date()
        )
        let data = try JSONEncoder().encode(legacy)
        let decoded = try JSONDecoder().decode(Project.self, from: data)
        XCTAssertNil(decoded.spaceID)
        XCTAssertEqual(decoded.id, legacy.id)
        XCTAssertEqual(decoded.name, "legacy")
        XCTAssertEqual(decoded.directory, "/legacy")
        XCTAssertEqual(decoded.workstreams.count, 1)
    }

    func testProjectStoreWithWorkstreams() {
        let projects = [
            Project(name: "one", directory: "/one", workstreams: [
                Workstream(name: "dev"),
            ]),
        ]
        ProjectStore.save(projects, defaults: testDefaults)
        let loaded = ProjectStore.load(defaults: testDefaults)
        XCTAssertEqual(loaded.first?.workstreams.count, 1)
        XCTAssertEqual(loaded.first?.workstreams.first?.name, "dev")
    }
}
