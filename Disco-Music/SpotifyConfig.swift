import Foundation

struct SpotifyConfig {
    // REPLACE WITH YOUR ACTUAL CLIENT ID FROM SPOTIFY DASHBOARD
    static let clientID = "88af7de34a874416bcfe2dd098bcb9b4"
    
    // This should match your Info.plist URL scheme
    static let redirectURLString = "disco://callback"
    
    static var redirectURL: URL {
        URL(string: redirectURLString)!
    }
}
