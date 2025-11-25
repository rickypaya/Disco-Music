//
//  SpotifyLoginButtonWrapper.swift
//  Disco-Music
//
//  Created by Ricardo Payares on 11/25/25.
//

import SwiftUI
import UIKit

// MARK: - UIViewController Wrapper for Spotify Login

struct SpotifyLoginControllerWrapper: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onSuccess: () -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        return UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isPresented && context.coordinator.loginController == nil {
            let loginVC = SpotifyLoginViewController()
            loginVC.onSuccess = {
                onSuccess()
                context.coordinator.loginController = nil
            }
            
            loginVC.initiateLogin()
            context.coordinator.loginController = loginVC
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var loginController: SpotifyLoginViewController?
    }
}

class SpotifyLoginViewController: UIViewController {
    var onSuccess: (() -> Void)?
    
    func initiateLogin() {
        // Get the topmost view controller to present from
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            
            var topController = rootVC
            while let presented = topController.presentedViewController {
                topController = presented
            }
            
            // Initiate Spotify login
            SpotifyAuthManager.shared.initiateLogin(from: topController)
            
            // Listen for authentication success
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("SpotifyAuthSuccess"),
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.onSuccess?()
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
