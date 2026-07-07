import SwiftUI

struct PaymentMethodManagementView: View {
    let group: SDGroup

    @State private var viewModel = PaymentMethodListViewModel()
    @State private var sheetMode: SheetMode?

    enum SheetMode: Identifiable {
        case add
        case edit(SDPaymentMethod)
        var id: String {
            switch self { case .add: return "add"; case .edit(let pm): return pm.id.uuidString }
        }
    }

    var body: some View {
        List {
            ForEach(viewModel.paymentMethods) { pm in
                paymentMethodRow(pm)
                    .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .onDelete { indexSet in
                indexSet.forEach { viewModel.deletePaymentMethod(viewModel.paymentMethods[$0]) }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(LocalizationKey.Payment.title.localized)
        .navigationBarTitleDisplayMode(.inline)
        .errorAlert(
            isPresented: $viewModel.showError,
            message: viewModel.errorMessage,
            onDismiss: viewModel.clearError
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                PrimaryToolbarAddButton {
                    sheetMode = .add
                }
            }
        }
        .sheet(item: $sheetMode) { mode in
            NavigationStack {
                switch mode {
                case .add:
                    PaymentMethodFormView(group: group, methodToEdit: nil) {
                        Task { await viewModel.loadPaymentMethods(forGroupId: group.id) }
                    }
                case .edit(let pm):
                    PaymentMethodFormView(group: group, methodToEdit: pm) {
                        Task { await viewModel.loadPaymentMethods(forGroupId: group.id) }
                    }
                }
            }
        }
        .task { await viewModel.loadPaymentMethods(forGroupId: group.id) }
    }

    private func paymentMethodRow(_ pm: SDPaymentMethod) -> some View {
        Button { sheetMode = .edit(pm) } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(PaymentMethodAppearance.tint(for: pm).opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: PaymentMethodAppearance.icon(for: pm))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(PaymentMethodAppearance.tint(for: pm))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(pm.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(AppConstants.UserInterface.padding)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.rowCornerRadius))
            .contentShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.rowCornerRadius))
        }
        .buttonStyle(.plain)
    }
}
