//
//  KeychainHelper.swift
//  Disco-Music
//
//  Created by Ricardo Payares on 11/25/25.
//

import Foundation
import Security

class KeychainHelper {
    static let shared = KeychainHelper()
    
    private let service = "com.spotify.music"
    private let accessTokenKey = "spotifyAccessToken"
    
    private init() {}
    
    // MARK: - Save Access Token
    
    func saveAccessToken(_ token: String) {
        let data = Data(token.utf8)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accessTokenKey,
            kSecValueData as String: data
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("Access token saved successfully to keychain")
        } else {
            print("Failed to save access token to keychain: \(status)")
        }
    }
    
    // MARK: - Get Access Token
    
    func getAccessToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accessTokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess,
           let data = dataTypeRef as? Data,
           let token = String(data: data, encoding: .utf8) {
            return token
        } else {
            print("Failed to retrieve access token from keychain: \(status)")
            return nil
        }
    }
    
    // MARK: - Delete Access Token
    
    func deleteAccessToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accessTokenKey
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess {
            print("Access token deleted successfully from keychain")
        } else if status == errSecItemNotFound {
            print("No access token found in keychain to delete")
        } else {
            print("Failed to delete access token from keychain: \(status)")
        }
    }
}
