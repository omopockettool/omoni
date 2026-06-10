import XCTest
@testable import Omoni

@MainActor
final class FetchItemSuggestionsUseCaseTests: XCTestCase {

    private var swiftData: SwiftDataTestContainer!
    private var useCase: FetchItemSuggestionsUseCase!
    private var group: SDGroup!
    private var itemList: SDItemList!

    override func setUp() async throws {
        swiftData = try SwiftDataTestContainer()
        useCase = DefaultFetchItemSuggestionsUseCase(itemRepository: swiftData.makeItemRepository())
        group = try swiftData.insertGroup(name: "Casa")
        itemList = try swiftData.insertItemList(description: "Supermercado", group: group)
    }

    override func tearDown() {
        useCase = nil
        itemList = nil
        group = nil
        swiftData = nil
    }

    // MARK: - 1. Category scoping (primary path)

    func testExecute_WithCategoryId_ExcludesItemsFromOtherCategories() async throws {
        let foodCategory = try swiftData.insertCategory(name: "Comida", group: group)
        let transportCategory = try swiftData.insertCategory(name: "Movilidad", group: group)

        let foodList = try swiftData.insertItemList(description: "Supermercado", group: group)
        foodList.category = foodCategory
        try swiftData.context.save()

        let transportList = try swiftData.insertItemList(description: "Transporte", group: group)
        transportList.category = transportCategory
        try swiftData.context.save()

        try swiftData.insertItem(description: "Leche", amount: 1.20, itemList: foodList)
        try swiftData.insertItem(description: "Abono transporte", amount: 54.60, itemList: transportList)

        let results = await useCase.execute(query: "a", categoryId: foodCategory.id, groupId: group.id)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.description, "Leche")
        XCTAssertFalse(results.contains { $0.description == "Abono transporte" })
    }

    // MARK: - 2. Group scoping (fallback when categoryId is nil)

    func testExecute_WithNilCategoryId_FallsBackToGroupScope() async throws {
        let otherGroup = try swiftData.insertGroup(name: "Trabajo")
        let otherList = try swiftData.insertItemList(description: "Otros", group: otherGroup)

        try swiftData.insertItem(description: "Chocolate", amount: 1.50, itemList: itemList)
        try swiftData.insertItem(description: "Chocolate negro", amount: 2.00, itemList: otherList)

        let results = await useCase.execute(query: "Chocolate", categoryId: nil, groupId: group.id)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.description, "Chocolate")
    }

    // MARK: - 3. Frequency sort

    func testExecute_ReturnsSortedByFrequency() async throws {
        let list2 = try swiftData.insertItemList(description: "Lista 2", group: group)

        // "Leche" appears 3 times, "Pan" appears 1 time
        try swiftData.insertItem(description: "Leche", amount: 1.20, itemList: itemList)
        try swiftData.insertItem(description: "Leche", amount: 1.20, itemList: itemList)
        try swiftData.insertItem(description: "Leche", amount: 1.20, itemList: list2)
        try swiftData.insertItem(description: "Pan", amount: 0.80, itemList: itemList)

        let results = await useCase.execute(query: "a", categoryId: nil, groupId: group.id)

        XCTAssertEqual(results.first?.description, "Leche")
    }

    // MARK: - 4. Last known price

    func testExecute_ReturnsLastKnownPriceForRepeatedDescription() async throws {
        let oldDate = Date(timeIntervalSinceNow: -3600)
        let newDate = Date()

        let oldItem = SDItem(itemDescription: "Café", amount: 1.80, quantity: 1, isPaid: false, createdAt: oldDate)
        oldItem.itemList = itemList
        swiftData.context.insert(oldItem)

        let newItem = SDItem(itemDescription: "Café", amount: 2.50, quantity: 1, isPaid: false, createdAt: newDate)
        newItem.itemList = itemList
        swiftData.context.insert(newItem)
        try swiftData.context.save()

        let results = await useCase.execute(query: "Café", categoryId: nil, groupId: group.id)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.amount, 2.50, "Should return the most recently created price, not the older one")
    }

    // MARK: - 5. Minimum query length

    func testExecute_ReturnsEmptyForBlankQuery() async throws {
        try swiftData.insertItem(description: "Arroz", amount: 1.00, itemList: itemList)
        let results = await useCase.execute(query: "", categoryId: nil, groupId: group.id)
        XCTAssertTrue(results.isEmpty)
    }

    func testExecute_ReturnsEmptyForSingleCharacterQuery() async throws {
        try swiftData.insertItem(description: "Arroz", amount: 1.00, itemList: itemList)
        let results = await useCase.execute(query: "A", categoryId: nil, groupId: group.id)
        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - 6. No matches

    func testExecute_ReturnsEmptyWhenNoDescriptionMatches() async throws {
        try swiftData.insertItem(description: "Mantequilla", amount: 2.00, itemList: itemList)
        let results = await useCase.execute(query: "xyz", categoryId: nil, groupId: group.id)
        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - 7. Result cap

    func testExecute_CapsResultsAtFive() async throws {
        let descriptions = ["Arroz", "Azúcar", "Aceite", "Atún", "Avena", "Almendras"]
        for desc in descriptions {
            try swiftData.insertItem(description: desc, amount: 1.00, itemList: itemList)
        }

        let results = await useCase.execute(query: "a", categoryId: nil, groupId: group.id)

        XCTAssertLessThanOrEqual(results.count, 5)
    }
}
