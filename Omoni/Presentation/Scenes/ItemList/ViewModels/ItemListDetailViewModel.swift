//
//  ItemListDetailViewModel.swift
//  Omoni
//

import Foundation
import SwiftUI

enum ItemListDetailHeroStatus {
    case neutral
    case unpaid(String)
    case partial(String)
    case completed
}

@MainActor

@Observable
class ItemListDetailViewModel {

    // MARK: - Published Properties
    var items: [SDItem] = []
    var isLoading = true
    var errorMessage: String?
    private(set) var pendingMutationCount = 0

    // MARK: - Use Cases
    private let fetchItemsUseCase: FetchItemsUseCase
    private let createItemUseCase: CreateItemUseCase
    private let updateItemUseCase: UpdateItemUseCase
    private let deleteItemUseCase: DeleteItemUseCase
    private let toggleItemPaidUseCase: ToggleItemPaidUseCase

    // MARK: - Model & Cache
    private let itemList: SDItemList
    private let currencyCode: String
    private let showsPendingItemsOnly: Bool
    private let cacheManager = CacheManager.shared

    // MARK: - Cache Keys
    private var serviceCacheKey: String {
        "ItemService.itemListItems.\(itemList.id.uuidString)"
    }

    private var timestampKey: String {
        "\(serviceCacheKey).timestamp"
    }

    // MARK: - Initialization
    init(
        itemList: SDItemList,
        currencyCode: String,
        showsPendingItemsOnly: Bool,
        fetchItemsUseCase: FetchItemsUseCase,
        createItemUseCase: CreateItemUseCase,
        updateItemUseCase: UpdateItemUseCase,
        deleteItemUseCase: DeleteItemUseCase,
        toggleItemPaidUseCase: ToggleItemPaidUseCase
    ) {
        self.itemList = itemList
        self.currencyCode = currencyCode
        self.showsPendingItemsOnly = showsPendingItemsOnly
        self.fetchItemsUseCase = fetchItemsUseCase
        self.createItemUseCase = createItemUseCase
        self.updateItemUseCase = updateItemUseCase
        self.deleteItemUseCase = deleteItemUseCase
        self.toggleItemPaidUseCase = toggleItemPaidUseCase
    }

    // MARK: - Data Loading

    var visibleItems: [SDItem] {
        showsPendingItemsOnly ? items.filter { !$0.isPaid } : items
    }

    func loadItems() async {

        let isInitialLoad = items.isEmpty

        if isInitialLoad {
            isLoading = true
        }
        errorMessage = nil

        do {
            let fetchedItems = try await fetchItemsUseCase.execute(forItemListId: itemList.id)
            let sortedItems = sortItems(fetchedItems)

            if isInitialLoad {
                items = sortedItems
            } else {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    items = sortedItems
                }
            }
            isLoading = false
        } catch {
            errorMessage = "No se pudieron cargar los artículos: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Item Operations

    func addItem(_ item: SDItem) async {
        items.append(item)
        items = sortItems(items)
    }

    func updateItem(_ item: SDItem) async {
        // SDItem is a reference type — the object is already updated in place.
        // Keep the list aligned with the repository's creation-date ordering.
        items = sortItems(items)
    }

    func deleteItem(_ item: SDItem) async {
        pendingMutationCount += 1
        defer { pendingMutationCount = max(0, pendingMutationCount - 1) }

        withAnimation(AnimationHelper.deleteSpring) {
            items.removeAll { $0.id == item.id }
        }

        do {
            try await deleteItemUseCase.execute(id: item.id)
        } catch {
            withAnimation(AnimationHelper.deleteSpring) {
                items.append(item)
                items = sortItems(items)
            }
        }
    }

    func toggleItemPaid(_ item: SDItem) async {
        pendingMutationCount += 1
        defer { pendingMutationCount = max(0, pendingMutationCount - 1) }

        let newIsPaid = !item.isPaid
        let previousLastModifiedAt = item.lastModifiedAt
        item.setPaidStatus(newIsPaid)
        do {
            try await toggleItemPaidUseCase.execute(itemId: item.id, isPaid: newIsPaid)
        } catch {
            item.restorePaidStatus(!newIsPaid, lastModifiedAt: previousLastModifiedAt)
        }
    }

    func waitForPendingMutations() async {
        while pendingMutationCount > 0 {
            try? await Task.sleep(for: .milliseconds(50))
        }
    }

    // MARK: - Formatting Helpers

    private func sortItems(_ items: [SDItem]) -> [SDItem] {
        items.sorted { lhs, rhs in
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt > rhs.createdAt
            }

            return lhs.id.uuidString > rhs.id.uuidString
        }
    }

    private func makeCurrencyFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale(identifier: "es_ES")
        let sym = NumberFormatter()
        sym.numberStyle = .currency
        sym.currencyCode = currencyCode
        sym.locale = Locale(identifier: "en_US")
        formatter.currencySymbol = sym.currencySymbol
        return formatter
    }

    func getFormattedTotal(query: String? = nil) -> String {
        let total = relevantItems(for: query).filter(\.isPaid).reduce(0.0) { result, item in
            result + item.totalAmount
        }
        return makeCurrencyFormatter().string(from: NSNumber(value: total)) ?? "\(total) \(currencyCode)"
    }

    func getFormattedUnpaidTotal(query: String? = nil) -> String? {
        let unpaid = relevantItems(for: query).filter { !$0.isPaid }.reduce(0.0) { $0 + $1.totalAmount }
        guard unpaid > 0 else { return nil }
        return makeCurrencyFormatter().string(from: NSNumber(value: unpaid)) ?? "\(unpaid) \(currencyCode)"
    }

    func getHeroStatus(query: String? = nil) -> ItemListDetailHeroStatus {
        let relevantItems = relevantItems(for: query)

        guard !relevantItems.isEmpty else {
            return .neutral
        }

        let unpaidItems = relevantItems.filter { !$0.isPaid }
        if !unpaidItems.isEmpty {
            let unpaidTotal = getFormattedUnpaidTotal(query: query) ?? ""
            return unpaidItems.count == relevantItems.count ? .unpaid(unpaidTotal) : .partial(unpaidTotal)
        }

        return .completed
    }

    func getFormattedAmount(_ item: SDItem) -> String {
        return makeCurrencyFormatter().string(from: NSNumber(value: item.totalAmount)) ?? "\(item.totalAmount) \(currencyCode)"
    }

    func getQuantityBreakdown(_ item: SDItem) -> String? {
        guard item.quantity > 1 else { return nil }
        let formatter = makeCurrencyFormatter()
        guard let unitFormatted = formatter.string(from: NSNumber(value: item.amount)) else { return nil }
        return "\(item.quantity) × \(unitFormatted)"
    }

    func itemMatchesSearch(_ item: SDItem, query: String?) -> Bool {
        guard let normalizedQuery = normalizedSearchQuery(from: query) else {
            return false
        }

        return item.itemDescription.localizedCaseInsensitiveContains(normalizedQuery)
    }

    private func normalizedSearchQuery(from query: String?) -> String? {
        guard let query else { return nil }
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedQuery.isEmpty ? nil : trimmedQuery
    }

    private func relevantItems(for query: String?) -> [SDItem] {
        guard let normalizedQuery = normalizedSearchQuery(from: query) else {
            return visibleItems
        }

        let matchedItems = visibleItems.filter {
            $0.itemDescription.localizedCaseInsensitiveContains(normalizedQuery)
        }

        return matchedItems.isEmpty ? visibleItems : matchedItems
    }
}
