import SwiftUI

struct CreateFirstUserView: View {
    @State private var viewModel: CreateFirstUserViewModel
    @State private var backupViewModel: SettingsBackupViewModel
    @State private var acceptedLegal = false
    @FocusState private var focusedField: Field?
    
    var onUserCreated: (() async -> Void)?
    private let showsSimulationBadge: Bool
    // TODO: Replace the landing-page fallback with dedicated Terms and Privacy URLs once the website pages exist.
    private let legalURL = URL(string: "https://omopockettool.com")!
    
    enum Field: Hashable { 
        case name, email 
    }
    
    init(
        onUserCreated: (() async -> Void)? = nil,
        submissionMode: CreateFirstUserViewModel.SubmissionMode = .persist
    ) {
        self._viewModel = State(wrappedValue: CreateFirstUserViewModel(submissionMode: submissionMode))
        self._backupViewModel = State(wrappedValue: AppDIContainer.shared.makeSettingsBackupViewModel())
        self.onUserCreated = onUserCreated
        self.showsSimulationBadge = submissionMode == .simulate
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                header
                    .padding(.top, 40)
                
                formContent
                    .padding(.horizontal, AppConstants.UserInterface.largePadding)
                
                Spacer()
            }
            .opacity(viewModel.isLoading ? 0 : 1)
        }
        .errorAlert(
            isPresented: $viewModel.showError,
            message: viewModel.errorMessage ?? LocalizationKey.General.unknownError.localized,
            onDismiss: viewModel.clearError
        )
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
                    await onUserCreated?()
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
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 20) {
            if showsSimulationBadge {
                Text("DEBUG PREVIEW - No persistence")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())
            }

            // Icon with modern gradient
            ZStack {
                Circle()
                    .fill(Color.black)
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.black.opacity(0.18), radius: 12, y: 6)

                Image("settings-icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 68, height: 68)
            }
            .padding(.bottom, 8)
            
            VStack(spacing: 8) {
                Text(LocalizationKey.User.Welcome.title.localized)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.primary,
                                Color.primary.opacity(0.78)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .multilineTextAlignment(.center)

                Text(LocalizationKey.User.Welcome.subtitle.localized)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
    }
    
    // MARK: - Form Content
    
    private var formContent: some View {
        VStack(spacing: 16) {
            inputField(
                icon: "person.fill",
                placeholder: LocalizationKey.User.namePlaceholder.localized,
                text: $viewModel.name,
                field: .name,
                contentType: .name,
                keyboardType: .default,
                capitalization: .words
            )

            inputField(
                icon: "envelope.fill",
                placeholder: LocalizationKey.User.emailPlaceholder.localized,
                text: $viewModel.email,
                field: .email,
                contentType: nil,
                keyboardType: .emailAddress,
                capitalization: .never
            )

            legalDisclosure
            
            createButton
                .padding(.top, 8)

            backupDivider
                .padding(.top, 8)

            importBackupButton
        }
    }

    private var legalDisclosure: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                withAnimation(AnimationHelper.quickSpring) {
                    acceptedLegal.toggle()
                }
            } label: {
                Image(systemName: acceptedLegal ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(acceptedLegal ? Color.accentColor : Color.secondary)
                    .frame(width: 34, height: 34)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text(legalConsentMarkdown)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .tint(Color.accentColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
    }

    private var legalConsentMarkdown: AttributedString {
        let intro = LocalizationKey.User.Welcome.legalIntro.localized
        let terms = LocalizationKey.User.Welcome.terms.localized
        let connector = LocalizationKey.User.Welcome.consent.localized
        let privacy = LocalizationKey.User.Welcome.privacy.localized

        return (try? AttributedString(
            markdown: "\(intro) [\(terms)](\(legalURL.absoluteString)) \(connector) [\(privacy)](\(legalURL.absoluteString))"
        )) ?? AttributedString("\(intro) \(terms) \(connector) \(privacy)")
    }
    
    private func inputField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        field: Field,
        contentType: UITextContentType?,
        keyboardType: UIKeyboardType,
        capitalization: TextInputAutocapitalization
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.secondary)
                .frame(width: 24)
                .contentTransition(.symbolEffect(.replace))

            configuredTextField(
                placeholder: placeholder,
                text: text,
                contentType: contentType
            )
                .keyboardType(keyboardType)
                .textInputAutocapitalization(capitalization)
                .autocorrectionDisabled()
                .focused($focusedField, equals: field)
                .submitLabel(field == .name ? .next : .done)
                .onSubmit {
                    if field == .name { 
                        focusedField = .email 
                    } else { 
                        focusedField = nil
                    }
                }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            focusedField == field ? Color(.systemGray3) : Color.clear,
                            lineWidth: 2
                        )
                )
        )
    }

    @ViewBuilder
    private func configuredTextField(
        placeholder: String,
        text: Binding<String>,
        contentType: UITextContentType?
    ) -> some View {
        if let contentType {
            TextField(placeholder, text: text)
                .textContentType(contentType)
        } else {
            TextField(placeholder, text: text)
        }
    }
    
    // MARK: - Create Button
    
    private var createButton: some View {
        Button {
            focusedField = nil
            if showsSimulationBadge {
                viewModel.triggerTestError()
                return
            }
            Task {
                await viewModel.createUser()
                if viewModel.isSuccess {
                    await onUserCreated?()
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 17, weight: .semibold))
                    .symbolEffect(.bounce, value: viewModel.isFormValid)
                
                Text(LocalizationKey.User.create.localized)
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Group {
                    if viewModel.isFormValid {
                        LinearGradient(
                            colors: [
                                Color.accentColor,
                                Color.accentColor.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        LinearGradient(
                            colors: [
                                Color(.systemFill),
                                Color(.systemFill)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: viewModel.isFormValid ? Color.accentColor.opacity(0.3) : .clear,
                radius: 8,
                y: 4
            )
        }
        .buttonStyle(PressHapticButtonStyle())
        .disabled(!viewModel.isFormValid || !acceptedLegal || viewModel.isLoading)
        .animation(.smooth(duration: 0.3), value: viewModel.isFormValid)
        .animation(.smooth(duration: 0.3), value: acceptedLegal)
    }

    private var backupDivider: some View {
        HStack(spacing: 14) {
            Rectangle()
                .fill(Color(.separator).opacity(0.45))
                .frame(height: 1)

            Circle()
                .fill(Color(.tertiarySystemFill))
                .frame(width: 12, height: 12)
                .overlay {
                    Circle()
                        .stroke(Color(.separator).opacity(0.6), lineWidth: 1)
                }

            Rectangle()
                .fill(Color(.separator).opacity(0.45))
                .frame(height: 1)
        }
        .padding(.horizontal, 12)
        .accessibilityHidden(true)
    }

    private var importBackupButton: some View {
        Button {
            focusedField = nil
            backupViewModel.beginImport()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 17, weight: .semibold))

                Text(LocalizationKey.Settings.importBackup.localized)
                    .font(.headline)
            }
            .foregroundStyle(Color.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PressHapticButtonStyle())
        .disabled(viewModel.isLoading || backupViewModel.isWorking)
    }
}

// MARK: - Preview

#Preview("Default") {
    CreateFirstUserView(onUserCreated: {})
}

#Preview("Dark Mode") {
    CreateFirstUserView(onUserCreated: {})
        .preferredColorScheme(.dark)
}

#Preview("Simulated Submission") {
    CreateFirstUserView(
        onUserCreated: {},
        submissionMode: .simulate
    )
}
