//
//  AppContentView.swift
//  Omoni
//
//  Created by Dennis Chicaiza A on 13/9/25.
//

import SwiftUI
import OSLog

struct AppContentView: View {
    @State private var navigationPath = NavigationPath()
    @State private var viewModel: AppContentViewModel
    @State private var hasLoadedInitialData = false
    @State private var isShowingCreateGroup = false

    private static let logger = Logger(subsystem: "Omoni", category: "Lifecycle.AppContentView")

    init() {
        _viewModel = State(wrappedValue: AppContentViewModel())
        Self.logger.debug("init")
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            if viewModel.isLoading {
                loadingView
            } else if let errorMessage = viewModel.errorMessage {
                errorView(errorMessage)
            } else if viewModel.isSetupComplete {
                DashboardView()
                    .navigationBarHidden(true)
            } else {
                setupRequiredView
            }
        }
        .navigationTitle("OMONI")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingCreateGroup) {
            if let userId = viewModel.currentUser?.id {
                CreateGroupView(
                    userId: userId,
                    onGroupCreated: { _ in
                        Task { await viewModel.loadInitialData() }
                    }
                )
            }
        }
        .task {
            guard !hasLoadedInitialData else {
                Self.logger.debug("task skipped because initial content load already ran")
                return
            }

            hasLoadedInitialData = true
            Self.logger.debug("task starting initial content load")
            await viewModel.loadInitialData()
            Self.logger.debug("task finished initial content load setupComplete=\(viewModel.isSetupComplete) errorPresent=\(viewModel.errorMessage != nil)")
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        Color(.systemBackground).ignoresSafeArea()
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text(LocalizationKey.General.error.localized)
                .font(.title)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(LocalizationKey.General.retry.localized) {
                Task { await viewModel.loadInitialData() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - Setup Required View
    private var setupRequiredView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text(LocalizationKey.Settings.requiredConfig.localized)
                .font(.title)

            Text(LocalizationKey.Settings.requiredConfigMsg.localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(LocalizationKey.Settings.goToSettings.localized) {
                isShowingCreateGroup = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.currentUser == nil)
        }
        .padding()
    }
    
    // MARK: - Main Content View (Legacy - Now using DashboardView)
    // This content has been moved to DashboardView for better modularization
    
    // MARK: - Legacy Views (Moved to DashboardView)
    // Header and Quick Actions have been moved to DashboardView components
}

#Preview {
    AppContentView()
}
