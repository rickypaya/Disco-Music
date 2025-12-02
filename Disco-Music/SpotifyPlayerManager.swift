import Foundation
import Combine
import SpotifyiOS

// MARK: - Playback State Model

struct PlaybackState {
    var isPlaying: Bool = false
    var trackName: String?
    var artistName: String?
    var albumArtURL: String?
    var duration: TimeInterval = 0
    var position: TimeInterval = 0
    var isPaused: Bool = true
    var currentTrack: SPTAppRemoteTrack?  // NEW: Store the actual track object
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return position / duration
    }
    
    var formattedPosition: String {
        formatTime(position)
    }
    
    var formattedDuration: String {
        formatTime(duration)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Spotify Player Manager

class SpotifyPlayerManager: NSObject, ObservableObject {
    static let shared = SpotifyPlayerManager()
    
    @Published var playbackState = PlaybackState()
    @Published var isConnected = false
    @Published var errorMessage: String?
    
    private var appRemote: SPTAppRemote?
    private var connectionAttempts = 0
    private let maxConnectionAttempts = 3
    private var positionTimer: Timer?
    
    private override init() {
        super.init()
        setupAppRemote()
    }
    
    // MARK: - Setup
    
    private func setupAppRemote() {
        
        let configuration = SPTConfiguration(
            clientID: SpotifyConfig.clientID,
            redirectURL: SpotifyConfig.redirectURL
        )
        
        appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote?.delegate = self
    }
    
    
    // MARK: - Connection
    
    func connect() {
        guard let appRemote = appRemote else {
            errorMessage = "App Remote not initialized"
            return
        }
        
        guard SpotifyAuthManager.shared.isAuthenticated else {
            errorMessage = "Not authenticated with Spotify"
            return
        }
        
        if appRemote.isConnected {
            print("Already connected to Spotify")
            return
        }
        
        // Check if Spotify app is available
        guard UIApplication.shared.canOpenURL(URL(string: "spotify:")!) else {
            errorMessage = "Spotify app not installed. Please install Spotify to use playback features."
            return
        }
        
        guard let token = SpotifyAuthManager.shared.accessToken else {
            errorMessage = "No access token available"
            return
        }
        
        appRemote.connectionParameters.accessToken = token
        
        connectionAttempts += 1
        print("Attempting to connect to Spotify (attempt \(connectionAttempts)/\(maxConnectionAttempts))...")
        appRemote.connect()
    }
    
    func disconnect() {
        appRemote?.disconnect()
        stopPositionTimer()
        isConnected = false
    }
    
    // MARK: - Authorization Token
    
    func setAuthorizationToken() {
        guard let token = SpotifyAuthManager.shared.accessToken else {
            print("No access token available")
            return
        }
        
        appRemote?.connectionParameters.accessToken = token
        print("Set authorization token for App Remote")
    }
    
    // MARK: - Playback Control
    
    func play() {
        appRemote?.playerAPI?.resume { [weak self] _, error in
            if let error = error {
                self?.errorMessage = "Failed to play: \(error.localizedDescription)"
            }
        }
    }
    
    func pause() {
        appRemote?.playerAPI?.pause { [weak self] _, error in
            if let error = error {
                self?.errorMessage = "Failed to pause: \(error.localizedDescription)"
            }
        }
    }
    
    func skipNext() {
        appRemote?.playerAPI?.skip(toNext: { [weak self] _, error in
            if let error = error {
                self?.errorMessage = "Failed to skip: \(error.localizedDescription)"
            }
        })
    }
    
    func skipPrevious() {
        appRemote?.playerAPI?.skip(toPrevious: { [weak self] _, error in
            if let error = error {
                self?.errorMessage = "Failed to go back: \(error.localizedDescription)"
            }
        })
    }
    
    func seek(to position: TimeInterval) {
        let positionMs = Int(position * 1000)
        appRemote?.playerAPI?.seek(toPosition: positionMs) { [weak self] _, error in
            if let error = error {
                self?.errorMessage = "Failed to seek: \(error.localizedDescription)"
            }
        }
    }
    
    func playTrack(uri: String, completion: ((Bool) -> Void)? = nil) {
        guard isConnected else {
            errorMessage = "Not connected to Spotify. Please connect first."
            completion?(false)
            return
        }
        
        appRemote?.playerAPI?.play(uri, callback: { [weak self] _, error in
            if let error = error {
                self?.errorMessage = "Failed to play track: \(error.localizedDescription)"
                print("Error playing track: \(error)")
                completion?(false)
            } else {
                print("Successfully started playing track: \(uri)")
                self?.errorMessage = nil
                completion?(true)
            }
        })
    }
    
    /// Play a track from a Track model
    func playTrack(_ track: Track, completion: ((Bool) -> Void)? = nil) {
        playTrack(uri: track.uri, completion: completion)
    }
    
    /// Play multiple tracks starting from a specific index, maintaining order
    func playTracks(uris: [String], startingAt index: Int = 0, completion: ((Bool) -> Void)? = nil) {
        guard isConnected else {
            errorMessage = "Not connected to Spotify. Please connect first."
            completion?(false)
            return
        }
        
        guard !uris.isEmpty, index >= 0, index < uris.count else {
            errorMessage = "Invalid track list or index"
            completion?(false)
            return
        }
        
        // Play the selected track
        let selectedTrackURI = uris[index]
        print(uris)
        
        appRemote?.playerAPI?.play(selectedTrackURI, callback: { [weak self] _, error in
            if let error = error {
                self?.errorMessage = "Failed to play tracks: \(error.localizedDescription)"
                print("Error playing tracks: \(error)")
                completion?(false)
            } else {
                print("Successfully started playing track at index \(index)")
                self?.errorMessage = nil
                
                // Queue remaining tracks in order (from index + 1 to end)
                self?.queueRemainingTracks(uris: uris, startingFrom: index + 1)
                completion?(true)
            }
        })
    }
    
    /// Play a list of Track models, starting from a specific index
    func playTracks(_ tracks: [Track], startingAt index: Int = 0, completion: ((Bool) -> Void)? = nil) {
        let uris = tracks.map { $0.uri }
        playTracks(uris: uris, startingAt: index, completion: completion)
    }
    
    /// Play playlist from SpotifyPlaylist starting at a specific track
    func playPlaylistTracks(from playlist: SpotifyPlaylist, startingAt index: Int = 0, completion: ((Bool) -> Void)? = nil) {
        guard let tracks = playlist.tracks?.items else {
            errorMessage = "No tracks in playlist"
            completion?(false)
            return
        }
        
        let trackURIs = tracks.compactMap { $0.track?.uri }
        playTracks(uris: trackURIs, startingAt: index, completion: completion)
    }
    
    /// Play a SpotifyTrack and queue subsequent tracks from a list
    func playSpotifyTrack(_ track: SpotifyTrack, fromPlaylist tracks: [SpotifyTrack], startingAt index: Int, completion: ((Bool) -> Void)? = nil) {
        let uris = tracks.map { "spotify:track:\($0.id)" }
        playTracks(uris: uris, startingAt: index, completion: completion)
    }
    
    /// Queue tracks after the current track in order
    private func queueRemainingTracks(uris: [String], startingFrom index: Int) {
        guard index < uris.count else { return }
        
        // Queue tracks sequentially to maintain order
        for i in index..<uris.count {
            let uri = uris[i]
            appRemote?.playerAPI?.enqueueTrackUri(uri, callback: { result, error in
                if let error = error {
                    print("Failed to queue track \(uri): \(error.localizedDescription)")
                } else {
                    print("Successfully queued track at position \(i): \(uri)")
                }
            })
        }
    }
    
    /// Play a playlist
    func playPlaylist(spotifyID: String, completion: ((Bool) -> Void)? = nil) {
        guard isConnected else {
            errorMessage = "Not connected to Spotify. Please connect first."
            completion?(false)
            return
        }
        
        let playlistURI = "spotify:playlist:\(spotifyID)"
        appRemote?.playerAPI?.play(playlistURI, callback: { [weak self] _, error in
            if let error = error {
                self?.errorMessage = "Failed to play playlist: \(error.localizedDescription)"
                print("Error playing playlist: \(error)")
                completion?(false)
            } else {
                print("Successfully started playing playlist: \(playlistURI)")
                self?.errorMessage = nil
                completion?(true)
            }
        })
    }
    
    // MARK: - Playback State Updates
    
    private func subscribeToPlayerState() {
        appRemote?.playerAPI?.delegate = self
        appRemote?.playerAPI?.subscribe { [weak self] _, error in
            if let error = error {
                self?.errorMessage = "Failed to subscribe: \(error.localizedDescription)"
            } else {
                print("Successfully subscribed to player state")
                self?.startPositionTimer()
            }
        }
    }
    
    private func updatePlaybackState(from playerState: SPTAppRemotePlayerState) {
        DispatchQueue.main.async { [weak self] in
            self?.playbackState.isPlaying = !playerState.isPaused
            self?.playbackState.isPaused = playerState.isPaused
            self?.playbackState.trackName = playerState.track.name
            self?.playbackState.artistName = playerState.track.artist.name
            self?.playbackState.albumArtURL = playerState.track.imageIdentifier
            self?.playbackState.duration = TimeInterval(playerState.track.duration) / 1000.0
            self?.playbackState.position = TimeInterval(playerState.playbackPosition) / 1000.0
            self?.playbackState.currentTrack = playerState.track  // NEW: Store track object
        }
    }
    
    // MARK: - Position Timer
    
    private func startPositionTimer() {
        stopPositionTimer()
        
        positionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updatePosition()
        }
    }
    
    private func stopPositionTimer() {
        positionTimer?.invalidate()
        positionTimer = nil
    }
    
    private func updatePosition() {
        guard !playbackState.isPaused else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.playbackState.position < self.playbackState.duration {
                self.playbackState.position += 0.5
            }
        }
    }
    
    // MARK: - Fetch Album Art
    
    func fetchAlbumArt(completion: @escaping (UIImage?) -> Void) {
        guard let track = playbackState.currentTrack else {
            completion(nil)
            return
        }
        
        appRemote?.imageAPI?.fetchImage(forItem: track, with: CGSize(width: 300, height: 300)) { image, error in
            if let error = error {
                print("Failed to fetch album art: \(error.localizedDescription)")
                completion(nil)
            } else {
                completion(image as? UIImage)
            }
        }
    }
}

// MARK: - SPTAppRemoteDelegate

extension SpotifyPlayerManager: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("App Remote connected")
        isConnected = true
        connectionAttempts = 0
        errorMessage = nil
        subscribeToPlayerState()
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("Failed to connect: \(error?.localizedDescription ?? "Unknown error")")
        isConnected = false
        errorMessage = "Failed to connect to Spotify"
        
        // Retry connection
        if connectionAttempts < maxConnectionAttempts {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.connect()
            }
        }
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("App Remote disconnected: \(error?.localizedDescription ?? "No error")")
        isConnected = false
        stopPositionTimer()
    }
}

// MARK: - SPTAppRemotePlayerStateDelegate

extension SpotifyPlayerManager: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        print("Player state changed")
        updatePlaybackState(from: playerState)
    }
}
