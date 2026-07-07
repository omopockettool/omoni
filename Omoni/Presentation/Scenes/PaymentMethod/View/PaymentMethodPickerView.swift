import SwiftUI
import SwiftData

struct PaymentMethodPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedPaymentMethod: SDPaymentMethod?
    let groupId: UUID

    @Query private var availablePaymentMethods: [SDPaymentMethod]

    init(selectedPaymentMethod: Binding<SDPaymentMethod?>, groupId: UUID) {
        self._selectedPaymentMethod = selectedPaymentMethod
        self.groupId = groupId
        let id = groupId
        self._availablePaymentMethods = Query(
            filter: #Predicate<SDPaymentMethod> { $0.group?.id == id && $0.isActive },
            sort: \SDPaymentMethod.name
        )
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if availablePaymentMethods.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "creditcard.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)

                        Text(LocalizationKey.Payment.emptyMessage.localized)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(LocalizationKey.Payment.emptyHint.localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(availablePaymentMethods, id: \.id) { paymentMethod in
                            PaymentMethodRow(
                                paymentMethod: paymentMethod,
                                isSelected: selectedPaymentMethod?.id == paymentMethod.id
                            ) {
                                selectedPaymentMethod = paymentMethod
                                dismiss()
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle(LocalizationKey.Payment.selectPayment.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationKey.General.cancel.localized) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationKey.Payment.none.localized) {
                        selectedPaymentMethod = nil
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - PaymentMethodRow

struct PaymentMethodRow: View {
    let paymentMethod: SDPaymentMethod
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack {
            Image(systemName: PaymentMethodAppearance.icon(for: paymentMethod))
                .font(.title2)
                .foregroundColor(PaymentMethodAppearance.tint(for: paymentMethod))
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(paymentMethod.name)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Preview

#Preview {
    PaymentMethodPickerView(
        selectedPaymentMethod: .constant(nil),
        groupId: UUID()
    )
    .modelContainer(ModelContainer.preview)
}
