//
//  SpotifyPlayerView.swift
//  Disco-Music
//
//  Created by Ricardo Payares on 11/26/25.
//

import SwiftUI

// MARK: - Spotify Mini Player

struct SpotifyMiniPlayer: View {
    @StateObject private var playerManager = SpotifyPlayerManager.shared
    @State private var showFullPlayer = false
    
    var body: some View {
        if playerManager.isConnected && playerManager.playbackState.trackName != nil {
            Button(action: {
                showFullPlayer = true
            }) {
                HStack(spacing: 12) {
                    // Album Art
                    AlbumArtView(size: 45)
                    
                    // Track Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(playerManager.playbackState.trackName ?? "Unknown")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        
                        Text(playerManager.playbackState.artistName ?? "Unknown Artist")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Play/Pause Button
                    Button(action: {
                        if playerManager.playbackState.isPaused {
                            playerManager.play()
                        } else {
                            playerManager.pause()
                        }
                    }) {
                        Image(systemName: playerManager.playbackState.isPaused ? "play.fill" : "pause.fill")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .shadow(radius: 5)
            }
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: $showFullPlayer) {
                SpotifyFullPlayer()
            }
        }
    }
}

// MARK: - Full Player View

struct SpotifyFullPlayer: View {
    @StateObject private var playerManager = SpotifyPlayerManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var albumArt: UIImage?
    @State private var isDragging = false
    @State private var draggedPosition: Double = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 33/255, green: 33/255, blue: 70/255),
                        Color(red: 15/255, green: 15/255, blue: 21/255)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    // Album Art
                    AlbumArtView(size: 300)
                        .shadow(radius: 20)
                    
                    Spacer()
                    
                    // Track Info
                    VStack(spacing: 8) {
                        Text(playerManager.playbackState.trackName ?? "No Track Playing")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(playerManager.playbackState.artistName ?? "Unknown Artist")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    .padding(.horizontal)
                    
                    // Progress Bar
                    VStack(spacing: 8) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background track
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 4)
                                    .cornerRadius(2)
                                
                                // Progress
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(
                                        width: geometry.size.width * (isDragging ? draggedPosition : playerManager.playbackState.progress),
                                        height: 4
                                    )
                                    .cornerRadius(2)
                            }
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        isDragging = true
                                        draggedPosition = min(max(0, value.location.x / geometry.size.width), 1)
                                    }
                                    .onEnded { value in
                                        let newPosition = min(max(0, value.location.x / geometry.size.width), 1)
                                        playerManager.seek(to: newPosition * playerManager.playbackState.duration)
                                        isDragging = false
                                    }
                            )
                        }
                        .frame(height: 4)
                        
                        // Time labels
                        HStack {
                            Text(playerManager.playbackState.formattedPosition)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Spacer()
                            
                            Text(playerManager.playbackState.formattedDuration)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Playback Controls
                    HStack(spacing: 40) {
                        // Previous
                        Button(action: {
                            playerManager.skipPrevious()
                        }) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        }
                        
                        // Play/Pause
                        Button(action: {
                            if playerManager.playbackState.isPaused {
                                playerManager.play()
                            } else {
                                playerManager.pause()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 70, height: 70)
                                
                                Image(systemName: playerManager.playbackState.isPaused ? "play.fill" : "pause.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(Color(red: 33/255, green: 33/255, blue: 70/255))
                            }
                        }
                        
                        // Next
                        Button(action: {
                            playerManager.skipNext()
                        }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.vertical, 20)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.down")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                }
            }
        }
    }
}

// MARK: - Album Art View

struct AlbumArtView: View {
    @StateObject private var playerManager = SpotifyPlayerManager.shared
    @State private var albumArt: UIImage?
    let size: CGFloat
    
    var body: some View {
        Group {
            if let albumArt = albumArt {
                Image(uiImage: albumArt)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .cornerRadius(12)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 81/255, green: 175/255, blue: 134/255),
                                Color(red: 68/255, green: 148/255, blue: 151/255)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: size * 0.4))
                            .foregroundColor(.white.opacity(0.6))
                    )
            }
        }
        .onChange(of: playerManager.playbackState.albumArtURL) { oldValue, newValue in
            fetchAlbumArt()
        }
        .onAppear {
            fetchAlbumArt()
        }
    }
    
    private func fetchAlbumArt() {
        playerManager.fetchAlbumArt { image in
            DispatchQueue.main.async {
                self.albumArt = image
            }
        }
    }
}
