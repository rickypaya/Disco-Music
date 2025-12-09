//
//  LikedGenresView.swift
//  Disco-Music
//
//  Created by Heather Meade on 12/8/25.
//

import SwiftUI

struct LikedGenresView: View {
    @StateObject private var storageManager = PlaylistStorageManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 82/255, green: 82/255, blue: 131/255), .appBackgroundDark
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if storageManager.loadLikedGenres().isEmpty {
                    emptyStateView
                } else {
                    likedGenresListView
                }
            }
            .navigationTitle("Likes").foregroundStyle(Color.white)
            .navigationBarTitleDisplayMode(.automatic)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "heart.slash.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            VStack(spacing: 12) {
                Text("No Liked Genres Yet")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Tap the heart icon on playlist previews to save your favorite genres!")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var likedGenresListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(storageManager.loadLikedGenres().keys.sorted(), id: \.self) { countryName in
                    Section(header: Text(countryName)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.leading, 16)
                        .padding(.bottom, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ) {
                        ForEach(storageManager.loadLikedGenres()[countryName] ?? [], id: \.self) { genre in
                            GenreCard(countryName: countryName, genre: genre)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
    }
}

struct GenreCard: View {
    let countryName: String
    let genre: String
    
    @State private var isPressed = false
    @StateObject private var storageManager = PlaylistStorageManager.shared
    
    var body: some View {
        Button(action: {
            // TODO: Navigate to a PlaylistPreviewView for this country and genre
            print("Tapped genre: \(genre) for country: \(countryName)")
        }) {
            HStack(spacing: 14) {
                // Icon/Artwork placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 100/255, green: 140/255, blue: 200/255),
                                    Color(red: 70/255, green: 110/255, blue: 170/255)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "guitars")
                        .font(.title)
                        .foregroundColor(.white.opacity(0.9))
                }
                .frame(width: 60, height: 60)
                .cornerRadius(12)
                
                // Genre and Country info
                VStack(alignment: .leading, spacing: 4) {
                    Text(genre)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(countryName)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Delete button
                Button(action: {
                    if let country = CountriesDataProvider().countries.first(where: { $0.name == countryName }) {
                        storageManager.removeLikedGenre(genre, for: country)
                    }
                }) {
                    Image(systemName: "trash")
                        .font(.body)
                        .foregroundColor(.red)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isPressed ? 0.12 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(CardButtonStyle(isPressed: $isPressed))
    }
}

#Preview {
    LikedGenresView()
}
