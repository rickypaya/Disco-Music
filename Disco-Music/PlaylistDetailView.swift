//
//  PlaylistDetailView.swift
//  Disco-Music
//
//  Created by Ricardo Payares on 12/1/25.
//

import SwiftUI

// MARK: - Playlist Detail View

struct PlaylistDetailView: View {
    let country: Country
    let genre: String
    let playlist: SpotifyPlaylist
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var spotifyAPI = SpotifyWebAPI.shared
    @ObservedObject private var playerManager = SpotifyPlayerManager.shared
    @State private var selectedTrack: SpotifyTrack?
    @State private var showConnectionAlert = false
    
    // Extract all tracks from playlist
    private var playlistTracks: [SpotifyTrack] {
        playlist.tracks?.items.compactMap { $0.track } ?? []
    }
    
    // Extract metadata from playlist description or use defaults
    private var era: String {
        // You could parse this from description or pass it in
        playlist.description ?? ""
    }
    
    private var playlistTitle: String {
        // Extract the custom title or use the first few words
        if let description = playlist.description, !description.isEmpty {
            // Try to extract a custom title from description
            return playlist.name.replacingOccurrences(of: " Mix", with: "")
        }
        return playlist.name
    }
    
    var body: some View {
        ZStack {
            // Background gradient matching the mockup
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 38/255, green: 147/255, blue: 155/255),
                    Color(red: 25/255, green: 110/255, blue: 125/255)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                playlistHeader
                
                // Connection Status Banner
                if !playerManager.isConnected {
                    connectionBanner
                }
                
                // Track List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if let tracks = playlist.tracks?.items {
                            ForEach(Array(tracks.enumerated()), id: \.element.track?.id) { index, item in
                                if let track = item.track {
                                    TrackRowButton(
                                        track: track,
                                        trackNumber: index + 1,
                                        isCurrentlyPlaying: isTrackCurrentlyPlaying(track),
                                        isPlaying: playerManager.playbackState.isPlaying && isTrackCurrentlyPlaying(track)
                                    ) {
                                        handleTrackTap(track: track, at: index)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 120) // Space for mini player and nav bar
                }
            }
        }
        .alert("Connect to Spotify", isPresented: $showConnectionAlert) {
            Button("Connect") {
                playerManager.connect()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please connect to Spotify to play tracks. Make sure the Spotify app is installed on your device.")
        }
    }
    
    // MARK: - Connection Banner
    
    private var connectionBanner: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
                .font(.callout)
            
            Text("Not connected to Spotify")
                .font(.caption)
                .foregroundColor(.white)
            
            Spacer()
            
            Button("Connect") {
                playerManager.connect()
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.3))
            .cornerRadius(12)
            .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.3))
    }
    
    // MARK: - Header View
    
    private var playlistHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Back button and Play All button
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                // Play All button
                Button(action: {
                    handlePlayAll()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: playerManager.playbackState.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title3)
                        Text(playerManager.playbackState.isPlaying ? "Pause" : "Play All")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(red: 50/255, green: 180/255, blue: 185/255))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 60)
            
            // Country and Era
            Text("\(country.name) · \(era)")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 16)
                .padding(.top, 20)
            
            // Playlist Title and Genre
            HStack(alignment: .bottom, spacing: 12) {
                Text(playlistTitle)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // Genre Tag and Track Count
            HStack(spacing: 12) {
                Text(genre)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.25))
                    .cornerRadius(20)
                
                if let tracks = playlist.tracks?.items {
                    Text("\(tracks.count) tracks")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Helper Methods
    
    private func isTrackCurrentlyPlaying(_ track: SpotifyTrack) -> Bool {
        // Check if this track is currently playing
        if let currentTrackName = playerManager.playbackState.trackName {
            return currentTrackName == track.name
        }
        return false
    }
    
    private func handleTrackTap(track: SpotifyTrack, at index: Int) {
        guard playerManager.isConnected else {
            showConnectionAlert = true
            return
        }
        
        // If the tapped track is currently playing, toggle play/pause
        if isTrackCurrentlyPlaying(track) && playerManager.playbackState.isPlaying {
            playerManager.pause()
        } else {
            // Play the selected track and queue the rest of the playlist
            playerManager.playPlaylistTracks(from: playlist, startingAt: index) { success in
                if success {
                    print("Started playing: \(track.name) at position \(index + 1)")
                } else {
                    print("Failed to play track: \(track.name)")
                }
            }
        }
    }
    
    private func handlePlayAll() {
        guard playerManager.isConnected else {
            showConnectionAlert = true
            return
        }
        
        // If playlist is currently playing, pause it
        if playerManager.playbackState.isPlaying {
            playerManager.pause()
        } else {
            // Play from the beginning
            playerManager.playPlaylistTracks(from: playlist, startingAt: 0) { success in
                if success {
                    print("Started playing playlist from beginning")
                } else {
                    print("Failed to play playlist")
                }
            }
        }
    }
}

// MARK: - Track Row Button

struct TrackRowButton: View {
    let track: SpotifyTrack
    let trackNumber: Int
    let isCurrentlyPlaying: Bool
    let isPlaying: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Track number or playing indicator
                ZStack {
                    if isCurrentlyPlaying && isPlaying {
                        // Animated playing indicator
                        HStack(spacing: 2) {
                            ForEach(0..<3) { index in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white)
                                    .frame(width: 3, height: CGFloat.random(in: 8...16))
                                    .animation(
                                        Animation.easeInOut(duration: 0.5)
                                            .repeatForever()
                                            .delay(Double(index) * 0.15),
                                        value: isPlaying
                                    )
                            }
                        }
                        .frame(width: 30)
                    } else if isCurrentlyPlaying {
                        Image(systemName: "pause.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                            .frame(width: 30)
                    } else {
                        Text("\(trackNumber)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 30)
                    }
                }
                
                // Album artwork
                if let imageUrl = track.album.images.first?.url,
                   let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                        case .failure(_), .empty:
                            placeholderArtwork
                        @unknown default:
                            placeholderArtwork
                        }
                    }
                } else {
                    placeholderArtwork
                }
                
                // Track info
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.name)
                        .font(.body)
                        .fontWeight(isCurrentlyPlaying ? .semibold : .regular)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(track.artists.map { $0.name }.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // More options button
                Button(action: {
                    // TODO: Show track options menu
                }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.body)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isCurrentlyPlaying ? Color.white.opacity(0.15) : Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isCurrentlyPlaying ? Color.white.opacity(0.4) : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var placeholderArtwork: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.white.opacity(0.2))
            .frame(width: 60, height: 60)
            .overlay(
                Image(systemName: "music.note")
                    .foregroundColor(.white.opacity(0.5))
            )
    }
}

