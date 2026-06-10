import SwiftUI

struct QuickAddItemsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: QuickAddItemsViewModel

    let currencyCode: String
    let onItemAdded: (SDItem) -> Void

    init(
        itemListId: UUID,
        groupId: UUID,
        categoryId: UUID?,
        currencyCode: String,
        onItemAdded: @escaping (SDItem) -> Void,
        fetchFrequentItemsUseCase: FetchFrequentItemsUseCase,
        createItemUseCase: CreateItemUseCase
    ) {
        self.currencyCode = currencyCode
        self.onItemAdded = onItemAdded
        self._viewModel = State(wrappedValue: QuickAddItemsViewModel(
            itemListId: itemListId,
            groupId: groupId,
            categoryId: categoryId,
            fetchFrequentItemsUseCase: fetchFrequentItemsUseCase,
            createItemUseCase: createItemUseCase
        ))
    }

    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale(identifier: "en_US")
        return formatter.currencySymbol
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.frequentItems.isEmpty {
                    emptyState
                } else {
                    itemsList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Añadir rápido")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                }
            }
            .task {
                await viewModel.loadFrequentItems()
            }
        }
    }

    // MARK: - Items list

    private var itemsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(viewModel.frequentItems.enumerated()), id: \.element.id) { index, suggestion in
                    quickAddRow(suggestion)
                    if index < viewModel.frequentItems.count - 1 {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
            .padding(AppConstants.UserInterface.padding)
        }
    }

    private func quickAddRow(_ suggestion: ItemSuggestion) -> some View {
        let added = viewModel.isAdded(suggestion)

        return Button {
            Task {
                if let item = await viewModel.quickAdd(suggestion) {
                    onItemAdded(item)
                }
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(added ? Color.paidGreen.opacity(0.15) : Color(.tertiarySystemFill))
                        .frame(width: 36, height: 36)
                    Image(systemName: added ? "checkmark" : "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(added ? Color.paidGreen : .secondary)
                }
                .animation(AnimationHelper.quickSpring, value: added)

                Text(suggestion.description)
                    .font(.body)
                    .foregroundStyle(added ? .secondary : .primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if suggestion.amount > 0 {
                    Text(formattedAmount(suggestion.amount))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(added ? .tertiary : .secondary)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, AppConstants.UserInterface.padding)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressHapticButtonStyle())
        .disabled(added)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Sin historial todavía")
                .font(.headline)
            Text("Añade artículos manualmente para que aparezcan aquí la próxima vez.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppConstants.UserInterface.padding * 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func formattedAmount(_ amount: Double) -> String {
        let formatted = String(format: "%.2f", amount)
            .replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression)
        return formatted + " " + currencySymbol
    }
}
