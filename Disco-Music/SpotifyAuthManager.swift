//
//  SpotifyAuthManager.swift
//  Disco-Music
//
//  Created by Ricardo Payares on 11/25/25.
//


import Foundation
import SpotifyiOS
import Combine

class SpotifyAuthManager: NSObject, ObservableObject {
    static let shared = SpotifyAuthManager()
    
    @Published var isAuthenticated = false
    @Published var accessToken: String?
    
    private var sessionManager: SPTSessionManager?
    
    private var spotifyClientID: String {
        SpotifyConfig.clientID
    }
    
    private var spotifyRedirectURL: URL {
        SpotifyConfig.redirectURL
    }
    
    override private init() {
        super.init()
        setupSessionManager()
        checkExistingSession()
    }
    
    private func setupSessionManager() {
        let configuration = SPTConfiguration(
            clientID: spotifyClientID,
            redirectURL: spotifyRedirectURL
        )
        
        sessionManager = SPTSessionManager(
            configuration: configuration,
            delegate: self
        )
    }
    
    func initiateLogin(from viewController: UIViewController) {
        guard let sessionManager = sessionManager else {
            print("Session manager not initialized")
            return
        }
        
        let scope: SPTScope = [
            .userReadEmail, .userReadPrivate,
            .userReadPlaybackState, .userModifyPlaybackState, .userReadCurrentlyPlaying,
            .streaming, .appRemoteControl,
            .playlistReadCollaborative, .playlistModifyPublic, .playlistReadPrivate, .playlistModifyPrivate,
            .userLibraryModify, .userLibraryRead,
            .userTopRead, .userReadPlaybackState, .userReadRecentlyPlayed,
            .userFollowRead, .userFollowModify
        ]
        
        let requestedScopes: SPTScope = scope
        sessionManager.initiateSession(with: requestedScopes, options: .default, campaign: nil)
    }
    
    func handleRedirect(url: URL) -> Bool {
        guard let sessionManager = sessionManager else {
            return false
        }
        
        return sessionManager.application(UIApplication.shared, open: url, options: [:])
    }
    
    private func checkExistingSession() {
        if let token = KeychainHelper.shared.getAccessToken() {
            self.accessToken = token
            self.isAuthenticated = true
        }
        
    }
    
    func logout() {
        KeychainHelper.shared.deleteAccessToken()
        self.accessToken = nil
        self.isAuthenticated = false
    }
    
    func refreshAccessToken(completion: @escaping (Bool) -> Void) {
        // Implement token refresh logic here if needed
        completion(false)
    }
}

// MARK: - SPTSessionManagerDelegate

extension SpotifyAuthManager: SPTSessionManagerDelegate {
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        print("Successfully authenticated with Spotify")
        
        // Store token in keychain
        KeychainHelper.shared.saveAccessToken(session.accessToken)
        
        DispatchQueue.main.async {
            self.accessToken = session.accessToken
            self.isAuthenticated = true
            
            // Post notification for UI updates
            NotificationCenter.default.post(name: NSNotification.Name("SpotifyAuthSuccess"), object: nil)
        }
    }
    
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        print("Failed to authenticate with Spotify: \(error.localizedDescription)")
        
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.accessToken = nil
        }
    }
    
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        print("Session renewed")
        
        // Update token in keychain
        KeychainHelper.shared.saveAccessToken(session.accessToken)
        
        DispatchQueue.main.async {
            self.accessToken = session.accessToken
            self.isAuthenticated = true
        }
    }
}
