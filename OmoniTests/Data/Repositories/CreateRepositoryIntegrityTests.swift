import XCTest
import SwiftData
@testable import Omoni

@MainActor
final class CreateRepositoryIntegrityTests: XCTestCase {
    private var swiftData: SwiftDataTestContainer!

    override func setUp() async throws {
        swiftData = try SwiftDataTestContainer()
    }

    override func tearDown() {
        swiftData = nil
    }

    func testCreateCategory_WithUnknownGroup_ThrowsNotFound() async {
        let repository = swiftData.makeCategoryRepository()

        do {
            _ = try await repository.createCategory(
                name: "Comida",
                color: "#FF0000",
                icon: "fork.knife",
                limit: nil,
                limitFrequency: "monthly",
                groupId: UUID()
            )
            XCTFail("Expected RepositoryError.notFound")
        } catch RepositoryError.notFound {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCreatePaymentMethod_WithUnknownGroup_ThrowsNotFound() async {
        let repository = swiftData.makePaymentMethodRepository()

        do {
            _ = try await repository.createPaymentMethod(
                name: "Bizum",
                type: "digital",
                icon: "iphone",
                color: "#00FF00",
                isActive: true,
                groupId: UUID()
            )
            XCTFail("Expected RepositoryError.notFound")
        } catch RepositoryError.notFound {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCreateItemList_WithUnknownCategory_ThrowsNotFound() async throws {
        let repository = swiftData.makeItemListRepository()
        let group = try swiftData.insertGroup()

        do {
            _ = try await repository.createItemList(
                description: "Compra",
                isList: true,
                date: Date(),
                categoryId: UUID(),
                paymentMethodId: nil,
                groupId: group.id
            )
            XCTFail("Expected RepositoryError.notFound")
        } catch RepositoryError.notFound {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCreateItem_WithUnknownItemList_ThrowsNotFound() async {
        let repository = swiftData.makeItemRepository()

        do {
            _ = try await repository.createItem(
                description: "Cafe",
                amount: 2.5,
                quantity: 1,
                itemListId: UUID(),
                isPaid: false
            )
            XCTFail("Expected RepositoryError.notFound")
        } catch RepositoryError.notFound {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCreateUserGroup_WithUnknownUser_ThrowsNotFound() async throws {
        let repository = swiftData.makeUserGroupRepository()
        let group = try swiftData.insertGroup()

        do {
            _ = try await repository.createUserGroup(userId: UUID(), groupId: group.id, role: "owner")
            XCTFail("Expected RepositoryError.notFound")
        } catch RepositoryError.notFound {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCreateUserGroup_WithUnknownGroup_ThrowsNotFound() async throws {
        let repository = swiftData.makeUserGroupRepository()
        let user = try swiftData.insertUser()

        do {
            _ = try await repository.createUserGroup(userId: user.id, groupId: UUID(), role: "owner")
            XCTFail("Expected RepositoryError.notFound")
        } catch RepositoryError.notFound {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFailedCreate_DoesNotPersistPartialRecords() async throws {
        let categoryRepository = swiftData.makeCategoryRepository()

        do {
            _ = try await categoryRepository.createCategory(
                name: "Casa",
                color: "#FFFFFF",
                icon: "house.fill",
                limit: nil,
                limitFrequency: "monthly",
                groupId: UUID()
            )
            XCTFail("Expected RepositoryError.notFound")
        } catch RepositoryError.notFound {
            let stored = try swiftData.context.fetch(FetchDescriptor<SDCategory>())
            XCTAssertTrue(stored.isEmpty)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
