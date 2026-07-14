import SwiftUI
import UIKit

struct AboutOMOView: View {
    @Environment(\.openURL) private var openURL
    private let appInfo = AppInfo.current
    private let appStoreURL = URL(string: "https://omopockettool.com")
    private let websiteURL = URL(string: "https://omopockettool.com/")
    private let supportEmailURL = URL(string: "mailto:omopockettool@gmail.com")
    private let termsURL = URL(string: "https://omopockettool.com/terms/")
    private let privacyURL = URL(string: "https://omopockettool.com/privacy/")
    @State private var copiedFieldTitle: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                heroSection
                applicationSection
                omoniSection
                supportSection
                developedBySection
            }
            .padding(AppConstants.UserInterface.padding)
            .padding(.bottom, AppConstants.UserInterface.largePadding)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(LocalizationKey.About.title.localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var heroSection: some View {
        VStack(spacing: 14) {
            OMOBrandIconView(size: 100)

            VStack(spacing: 4) {
                Text("OMONI")
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
                Text(LocalizationKey.User.welcomeSubtitle.localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private var applicationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(LocalizationKey.About.application.localized)

            NativeSettingsCard {
                infoRow(
                    icon: "app.badge.fill",
                    color: .red,
                    title: LocalizationKey.About.currentVersion.localized,
                    value: appInfo.fullVersionLabel
                )
                .padding(AppConstants.UserInterface.padding)

                Divider()
                    .padding(.leading, AppConstants.UserInterface.padding + 44)

                NavigationLink {
                    AppReleaseNotesView(installedVersion: appInfo.version)
                } label: {
                    infoRow(
                        icon: "clock.arrow.circlepath",
                        color: .orange,
                        title: LocalizationKey.About.whatsNew.localized,
                        value: LocalizationKey.About.viewHistory.localized,
                        showsChevron: true
                    )
                    .padding(AppConstants.UserInterface.padding)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var omoniSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("OMONI")

            NativeSettingsCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text(LocalizationKey.About.descriptionLabel.localized)
                        .font(.headline)
                    Text(LocalizationKey.About.tagline.localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(AppConstants.UserInterface.padding)

                Divider()
                    .padding(.leading, AppConstants.UserInterface.padding)

                if let websiteURL {
                    copyableLinkRow(
                        icon: "globe",
                        color: .indigo,
                        title: LocalizationKey.About.officialWeb.localized,
                        value: "omopockettool.com",
                        destination: websiteURL
                    )
                    .padding(AppConstants.UserInterface.padding)
                }

                Divider()
                    .padding(.leading, AppConstants.UserInterface.padding + 44)

                if let supportEmailURL {
                    copyableLinkRow(
                        icon: "envelope.fill",
                        color: .green,
                        title: LocalizationKey.About.contact.localized,
                        value: "omopockettool@gmail.com",
                        destination: supportEmailURL
                    )
                    .padding(AppConstants.UserInterface.padding)
                }

                Divider()
                    .padding(.leading, AppConstants.UserInterface.padding + 44)

                if let termsURL {
                    copyableLinkRow(
                        icon: "doc.text.fill",
                        color: .blue,
                        title: LocalizationKey.User.welcomeTerms.localized,
                        value: "omopockettool.com/terms",
                        destination: termsURL
                    )
                    .padding(AppConstants.UserInterface.padding)
                }

                Divider()
                    .padding(.leading, AppConstants.UserInterface.padding + 44)

                if let privacyURL {
                    copyableLinkRow(
                        icon: "hand.raised.fill",
                        color: .teal,
                        title: LocalizationKey.User.welcomePrivacy.localized,
                        value: "omopockettool.com/privacy",
                        destination: privacyURL
                    )
                    .padding(AppConstants.UserInterface.padding)
                }
            }
        }
    }

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(LocalizationKey.About.support.localized)

            NativeSettingsCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text(LocalizationKey.About.supportQuestion.localized)
                        .font(.headline)
                    Text(LocalizationKey.About.supportDescription.localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(AppConstants.UserInterface.padding)

                Divider()
                    .padding(.leading, AppConstants.UserInterface.padding)

                if let appStoreURL {
                    ShareLink(item: appStoreURL) {
                        infoRow(
                            icon: "square.and.arrow.up",
                            color: .blue,
                            title: LocalizationKey.About.shareApp.localized,
                            value: LocalizationKey.About.shareAppSubtitle.localized
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .padding(AppConstants.UserInterface.padding)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var developedBySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(LocalizationKey.About.developedBy.localized)

            NativeSettingsCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text(LocalizationKey.About.team.localized)
                        .font(.headline)
                    Text(LocalizationKey.About.motto.localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(AppConstants.UserInterface.padding)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }

    private func infoRow(icon: String, color: Color, title: String, value: String, showsChevron: Bool = false) -> some View {
        HStack(spacing: 12) {
            NativeSettingsRowIcon(systemName: icon, color: color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Text(value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func copyableLinkRow(
        icon: String,
        color: Color,
        title: String,
        value: String,
        destination: URL
    ) -> some View {
        HStack(spacing: 12) {
            infoRow(icon: icon, color: color, title: title, value: value)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    openURL(destination)
                }

            Button {
                UIPasteboard.general.string = value
                copiedFieldTitle = title
                Task {
                    try? await Task.sleep(for: .seconds(1.2))
                    if copiedFieldTitle == title {
                        copiedFieldTitle = nil
                    }
                }
            } label: {
                Image(systemName: copiedFieldTitle == title ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(copiedFieldTitle == title ? .green : .secondary)
                    .frame(width: 30, height: 30)
                    .background(
                        (copiedFieldTitle == title ? Color.green.opacity(0.14) : Color(.tertiarySystemGroupedBackground))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(LocalizationKey.General.copy.localized) \(title)")
        }
        .contentShape(Rectangle())
    }
}

struct AppReleaseNotesView: View {
    let installedVersion: String

    private var entries: [AppReleaseNoteEntry] {
        AppReleaseNotesCatalog.entries(for: installedVersion)
    }

    var body: some View {
        List {
            Section(LocalizationKey.About.changelog.localized) {
                ForEach(entries) { entry in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(entry.version)
                                .font(.headline)

                            if entry.version == installedVersion {
                                Text(LocalizationKey.About.installed.localized)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.red)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.12))
                                    .clipShape(Capsule())
                            }

                            Spacer()

                            Text(entry.date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text(entry.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        ForEach(entry.highlights, id: \.self) { highlight in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(Color.secondary.opacity(0.6))
                                    .frame(width: 5, height: 5)
                                    .padding(.top, 6)
                                Text(highlight)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(LocalizationKey.About.news.localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AppInfo {
    let version: String
    let build: String

    var fullVersionLabel: String {
        "v\(version) (\(build))"
    }

    static var current: AppInfo {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return AppInfo(version: version, build: build)
    }
}

private struct AppReleaseNoteEntry: Identifiable {
    let version: String
    let date: String
    let titleKey: String
    let highlightKeys: [String]

    var id: String { version }

    var title: String { titleKey.localized }
    var highlights: [String] { highlightKeys.map(\.localized) }
}

private enum AppReleaseNotesCatalog {
    private static let productionLaunchDate = "2026-07-16"

    static func entries(for marketingVersion: String) -> [AppReleaseNoteEntry] {
        [
            AppReleaseNoteEntry(
                version: marketingVersion,
                date: productionLaunchDate,
                titleKey: LocalizationKey.About.releaseNotesVersion200Title,
                highlightKeys: [
                    LocalizationKey.About.releaseNotesVersion200Highlight1,
                    LocalizationKey.About.releaseNotesVersion200Highlight2,
                    LocalizationKey.About.releaseNotesVersion200Highlight3,
                    LocalizationKey.About.releaseNotesVersion200Highlight4,
                    LocalizationKey.About.releaseNotesVersion200Highlight5
                ]
            )
        ]
    }
}
