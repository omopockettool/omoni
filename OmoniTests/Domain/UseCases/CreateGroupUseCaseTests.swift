import XCTest
@testable import Omoni

@MainActor
final class CreateGroupUseCaseTests: XCTestCase {

    private var swiftData: SwiftDataTestContainer!
    private var useCase: CreateGroupUseCase!

    override func setUp() async throws {
        swiftData = try SwiftDataTestContainer()
        useCase = DefaultCreateGroupUseCase(groupRepository: swiftData.makeGroupRepository())
    }

    override func tearDown() {
        useCase = nil
        swiftData = nil
    }

    // MARK: - Success

    func testCreateGroup_WithValidData_ReturnsGroup() async throws {
        let group = try await useCase.execute(name: "Personal", currency: "EUR")
        XCTAssertEqual(group.name, "Personal")
        XCTAssertEqual(group.currency, "EUR")
    }

    func testCreateGroup_TrimsNameWhitespace() async throws {
        let group = try await useCase.execute(name: "  Trabajo  ", currency: "EUR")
        XCTAssertEqual(group.name, "Trabajo")
    }

    func testCreateGroup_UppercasesCurrency() async throws {
        let group = try await useCase.execute(name: "Personal", currency: "eur")
        XCTAssertEqual(group.currency, "EUR")
    }

    func testCreateGroup_DefaultsGroupKindToExpense() async throws {
        let group = try await useCase.execute(name: "Personal", currency: "EUR")
        XCTAssertEqual(group.groupKind, SDGroupKind.expense.rawValue)
        XCTAssertEqual(group.resolvedGroupKind, .expense)
    }

    func testApplyEdits_WithSameValues_DoesNotTouchLastModifiedAt() async throws {
        let group = try await useCase.execute(name: "Personal", currency: "EUR")
        let originalDate = Date(timeIntervalSince1970: 1_700_000_000)
        group.lastModifiedAt = originalDate

        group.applyEdits(name: "Personal", currency: "EUR", kind: .expense)

        XCTAssertEqual(group.lastModifiedAt, originalDate)
    }

    // MARK: - Validation

    func testCreateGroup_EmptyName_ThrowsEmptyGroupName() async {
        do {
            _ = try await useCase.execute(name: "", currency: "EUR")
            XCTFail("Expected ValidationError.emptyGroupName")
        } catch ValidationError.emptyGroupName {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCreateGroup_WhitespaceOnlyName_ThrowsEmptyGroupName() async {
        do {
            _ = try await useCase.execute(name: "   ", currency: "EUR")
            XCTFail("Expected ValidationError.emptyGroupName")
        } catch ValidationError.emptyGroupName {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCreateGroup_EmptyCurrency_ThrowsError() async {
        do {
            _ = try await useCase.execute(name: "Personal", currency: "")
            XCTFail("Expected error for empty currency")
        } catch {
            // any error is acceptable — currency is invalid
        }
    }
}
