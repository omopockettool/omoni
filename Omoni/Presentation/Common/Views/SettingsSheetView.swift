import SwiftUI

struct SettingsSheetView: View {
    let user: SDUser
    let onUserUpdated: (SDUser) -> Void
    let onBackupImported: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var backupViewModel: SettingsBackupViewModel

    init(
        user: SDUser,
        onUserUpdated: @escaping (SDUser) -> Void,
        onBackupImported: @escaping () async -> Void,
        container: AppDIContainer
    ) {
        self.user = user
        self.onUserUpdated = onUserUpdated
        self.onBackupImported = onBackupImported
        _backupViewModel = State(wrappedValue: container.makeSettingsBackupViewModel())
    }

    @MainActor
    init(
        user: SDUser,
        onUserUpdated: @escaping (SDUser) -> Void,
        onBackupImported: @escaping () async -> Void
    ) {
        self.init(
            user: user,
            onUserUpdated: onUserUpdated,
            onBackupImported: onBackupImported,
            container: .shared
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    profileSection
                    backupSection
                    omoSection
                }
                .padding(AppConstants.UserInterface.padding)
                .padding(.bottom, AppConstants.UserInterface.largePadding)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(LocalizationKey.Settings.title.localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
        .fileExporter(
            isPresented: $backupViewModel.isShowingExporter,
            document: backupViewModel.exportDocument,
            contentType: .omoBackup,
            defaultFilename: backupViewModel.exportFilename
        ) { result in
            backupViewModel.handleExportCompletion(result)
        }
        .fileImporter(
            isPresented: $backupViewModel.isShowingImporter,
            allowedContentTypes: [.omoBackup, .json]
        ) { result in
            backupViewModel.handleImportSelection(result)
        }
        .alert(
            LocalizationKey.Settings.rescueBackupTitle.localized,
            isPresented: $backupViewModel.isShowingRescueExplanation
        ) {
            Button(LocalizationKey.General.cancel.localized, role: .cancel) {
                backupViewModel.cancelRescueExport()
            }
            Button(LocalizationKey.Settings.rescueBackupConfirm.localized) {
                backupViewModel.confirmRescueExport()
            }
        } message: {
            Text(LocalizationKey.Settings.rescueBackupMessage.localized)
        }
        .alert(
            LocalizationKey.Settings.replaceDataTitle.localized,
            isPresented: $backupViewModel.isShowingReplaceConfirmation
        ) {
            Button(LocalizationKey.General.cancel.localized, role: .cancel) {
                backupViewModel.cancelReplaceImport()
            }
            Button(LocalizationKey.Settings.replaceDataConfirm.localized, role: .destructive) {
                backupViewModel.confirmReplaceImport {
                    await onBackupImported()
                    dismiss()
                }
            }
        } message: {
            Text(LocalizationKey.Settings.replaceDataMessage.localized)
        }
        .errorAlert(
            isPresented: $backupViewModel.showError,
            message: backupViewModel.errorMessage,
            onDismiss: backupViewModel.clearError
        )
        .toast($backupViewModel.toast)
    }

    private var profileSection: some View {
        NavigationLink {
            UserProfileView(user: user, onUserUpdated: onUserUpdated)
        } label: {
            NativeSettingsCard {
                settingsNavigationRow(systemImage: "person.fill", color: .purple, title: user.name)
            }
        }
        .buttonStyle(.plain)
    }

    private var backupSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(LocalizationKey.Settings.backup.localized)

            NativeSettingsCard {
                Text(LocalizationKey.Settings.backupDescription.localized)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(AppConstants.UserInterface.padding)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .padding(.leading, AppConstants.UserInterface.padding)

                Button {
                    backupViewModel.beginManualExport()
                } label: {
                    settingsActionRow(
                        systemImage: "square.and.arrow.up",
                        color: .green,
                        title: LocalizationKey.Settings.exportBackup.localized
                    )
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.leading, AppConstants.UserInterface.padding + 42)

                Button {
                    backupViewModel.beginImport()
                } label: {
                    settingsActionRow(
                        systemImage: "square.and.arrow.down",
                        color: .orange,
                        title: LocalizationKey.Settings.importBackup.localized
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var omoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("OMO")

            NavigationLink {
                AboutOMOView()
            } label: {
                NativeSettingsCard {
                    settingsNavigationRow(
                        systemImage: "info.circle.fill",
                        color: .blue,
                        title: LocalizationKey.Settings.aboutOMO.localized
                    )
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }

    private func settingsNavigationRow(systemImage: String, color: Color, title: String) -> some View {
        NativeSettingsRow(systemImage: systemImage, color: color, title: title) {
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .font(.body)
        .padding(AppConstants.UserInterface.padding)
    }

    private func settingsActionRow(systemImage: String, color: Color, title: String) -> some View {
        NativeSettingsRow(systemImage: systemImage, color: color, title: title)
            .font(.body)
            .padding(AppConstants.UserInterface.padding)
    }
}
