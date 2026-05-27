//
//  MainView.swift
//  Omoni
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import SwiftUI
import OSLog

struct MainView: View {
    @State private var viewModel: MainViewModel
    @State private var hasCheckedForUsers = false

    private static let logger = Logger(subsystem: "Omoni", category: "Lifecycle.MainView")
    
    private enum ScreenState: Equatable {
        case splash
        case app
        case onboarding
    }

    init() {
        _viewModel = State(wrappedValue: MainViewModel())
        Self.logger.debug("init")
    }

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                SplashView()
                    .transition(.opacity)
            } else if viewModel.hasUsers {
                AppContentView()
                    .transition(.opacity)
            } else {
                CreateFirstUserView(
                    onUserCreated: {
                        await viewModel.checkForUsers()
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(AnimationHelper.smoothEase, value: screenState)
        .preferredColorScheme(.dark)
        .task {
            guard !hasCheckedForUsers else {
                Self.logger.debug("task skipped because initial user check already ran")
                return
            }

            hasCheckedForUsers = true
            Self.logger.debug("task starting initial user check")
            await viewModel.checkForUsers()
            Self.logger.debug("task finished initial user check hasUsers=\(viewModel.hasUsers)")
        }
    }
    
    private var screenState: ScreenState {
        if viewModel.isLoading {
            return .splash
        }
        
        return viewModel.hasUsers ? .app : .onboarding
    }
}

#Preview {
    MainView()
}
