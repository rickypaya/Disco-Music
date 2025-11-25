//
//  AppDelegate.swift
//  Disco-Music
//
//  Created by Ricardo Payares on 11/25/25.
//

import UIKit
import SpotifyiOS

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
    
    // MARK: - Handle URL Callback
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Handle Spotify OAuth callback
        return SpotifyAuthManager.shared.handleRedirect(url: url)
    }
    
    // MARK: - Scene Configuration
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
}

// MARK: - Scene Delegate

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Handle URL if app was opened via deep link
        if let urlContext = connectionOptions.urlContexts.first {
            _ = SpotifyAuthManager.shared.handleRedirect(url: urlContext.url)
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // Handle Spotify OAuth callback
        guard let url = URLContexts.first?.url else {
            return
        }
        _ = SpotifyAuthManager.shared.handleRedirect(url: url)
    }
}
