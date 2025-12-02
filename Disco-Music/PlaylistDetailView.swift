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
    @State private var selectedTrack: SpotifyTrack?
    
    // Extract metadata from playlist description or use defaults
    private var era: String {
        // You could parse this from description or pass it in
        "Late 70s-80s"
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
                
                // Track List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if let tracks = playlist.tracks?.items {
                            ForEach(Array(tracks.enumerated()), id: \.element.track?.id) { index, item in
                                if let track = item.track {
                                    TrackRow(
                                        track: track,
                                        isCurrentlyPlaying: spotifyAPI.currentTrack?.id == track.id,
                                        isPlaying: spotifyAPI.isPlaying && spotifyAPI.currentTrack?.id == track.id
                                    )
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
    }
    
    // MARK: - Header View
    
    private var playlistHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Back button
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
                
                // Play/Pause button
                Button(action: {
                }) {
                    Image(systemName: spotifyAPI.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color(red: 50/255, green: 180/255, blue: 185/255))
                        .clipShape(Circle())
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
            
            // Genre Tag
            HStack {
                Text(genre)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.25))
                    .cornerRadius(20)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Track Row

struct TrackRow: View {
    let track: SpotifyTrack
    let isCurrentlyPlaying: Bool
    let isPlaying: Bool
    
    var body: some View {
        HStack(spacing: 12) {
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
            
            // Playing indicator or static icon
            if isCurrentlyPlaying && isPlaying {
                Image(systemName: "waveform")
                    .font(.caption)
                    .foregroundColor(.white)
            } else {
                // Empty spacer to maintain alignment
                Color.clear.frame(width: 20)
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

