//
//  SpotifyService.swift
//  Disco-Music
//
//  Created by Parissa Teli on 11/28/25.
//

import Foundation

// MARK: - Spotify Models

struct SpotifyTrack: Decodable {
    let id: String
    let name: String
    let uri: String
}

// playlist returned by spotify after created
struct SpotifyPlaylist: Decodable, Identifiable {
    let id: String
    let name: String
    let uri: String?
}


private struct SpotifyUserProfile: Decodable {
    let id: String
    let display_name: String?
}

// For search results
struct SpotifySearchArtist: Decodable {
    let id: String
    let name: String
    let genres: [String]?
}

private struct SpotifySearchArtistsPage: Decodable {
    let items: [SpotifySearchArtist]
}

private struct SpotifySearchResponse: Decodable {
    let artists: SpotifySearchArtistsPage
}

// MARK: - Errors

enum SpotifyServiceError: Error {
    case noAccessToken
    case invalidURL
    case badResponse(Int)
    case noTracksFound
}

// MARK: - AnyEncodable Helper

private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init<T: Encodable>(_ wrapped: T) {
        _encode = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

// MARK: - Spotify Service

final class SpotifyWebAPI {

    static let shared = SpotifyWebAPI()

    private init() {}

    private let baseURL = URL(string: "https://api.spotify.com/v1")!

    // Pulls OAuth tocken from SpotifyAuthManager
    private var accessToken: String? {
        SpotifyAuthManager.shared.accessToken
    }

    // MARK: - Generic Request Helper

    private func request<T: Decodable>(
        path: String,
        method: String = "GET",
        queryItems: [URLQueryItem]? = nil,
        body: Encodable? = nil,
        decode type: T.Type
    ) async throws -> T {
        
        //checks token
        guard let token = accessToken else {
            throw SpotifyServiceError.noAccessToken
        }

        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = queryItems

        guard let url = components.url else {
            throw SpotifyServiceError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            let encoder = JSONEncoder()
            req.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let (data, resp) = try await URLSession.shared.data(for: req)

        guard let http = resp as? HTTPURLResponse else {
            throw SpotifyServiceError.badResponse(-1)
        }

        guard (200..<300).contains(http.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
            print("🎧 Spotify API error \(http.statusCode): \(bodyString)")
            throw SpotifyServiceError.badResponse(http.statusCode)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Low-Level Spotify API Calls

    // Gets current user profile
    private func getCurrentUserProfile() async throws -> SpotifyUserProfile {
        try await request(
            path: "me",
            decode: SpotifyUserProfile.self
        )
    }

    // Public helper to get user ID (for diagnostics)
    func getCurrentUserId() async throws -> String {
        let profile = try await getCurrentUserProfile()
        return profile.id
    }

    // Get /v1/artists/{id}/top-tracks
    func getArtistTopTracks(artistId: String, market: String) async throws -> [SpotifyTrack] {
        struct TopTracksResponse: Decodable {
            let tracks: [SpotifyTrack]
        }

        let response: TopTracksResponse = try await request(
            path: "artists/\(artistId)/top-tracks",
            queryItems: [
                URLQueryItem(name: "market", value: market)
            ],
            decode: TopTracksResponse.self
        )

        return response.tracks
    }

    // Post /v1/users/{user_id}/playlists
    func createPlaylist(
        userId: String,
        name: String,
        description: String? = nil,
        isPublic: Bool = false
    ) async throws -> SpotifyPlaylist {

        struct Body: Encodable {
            let name: String
            let description: String?
            let `public`: Bool
        }

        let body = Body(
            name: name,
            description: description,
            public: isPublic
        )

        return try await request(
            path: "users/\(userId)/playlists",
            method: "POST",
            body: body,
            decode: SpotifyPlaylist.self
        )
    }

    /// POST /v1/playlists/{playlist_id}/tracks
    func addTracksToPlaylist(playlistId: String, trackURIs: [String]) async throws {
        struct Body: Encodable {
            let uris: [String]
        }

        struct SnapshotResponse: Decodable {
            let snapshot_id: String
        }

        _ = try await request(
            path: "playlists/\(playlistId)/tracks",
            method: "POST",
            body: Body(uris: trackURIs),
            decode: SnapshotResponse.self
        )
    }

    /// GET /v1/search?type=artist – search by name
    func searchArtistByName(
        name: String,
        market: String? = nil,
        genreHint: String? = nil
    ) async throws -> SpotifySearchArtist? {

        // Basic search query
        var query = name

        // Optionally bias by genre (best-effort)
        if let genreHint, !genreHint.isEmpty {
            query += " genre:\"\(genreHint)\""
        }

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "artist"),
            URLQueryItem(name: "limit", value: "5")
        ]

        if let market {
            queryItems.append(URLQueryItem(name: "market", value: market))
        }

        let response: SpotifySearchResponse = try await request(
            path: "search",
            method: "GET",
            queryItems: queryItems,
            body: nil,
            decode: SpotifySearchResponse.self
        )

        // For now, just pick the first search hit.
        return response.artists.items.first
    }

    // MARK: - High-Level Playlist Generation

    // High-level helper that resolves each artist to a Spotify ID (using existing spotifyID or searching by name), fetches top tracks per artist, Creates a playlist for the current user, adds all collected tracks to that playlist
    
    /*
     Parameters:
        countryCode: Spotify market (e.g., "US", "BR", "ZA")
        countryName: Human-readable country for playlist title
        genre: Genre name for title/description
        artists: Your MusicBrainz artists
        tracksPerArtist: 1–3
    */
    
    func generatePlaylist(
        countryCode: String,
        countryName: String,
        genre: String,
        artists: [Artist],
        tracksPerArtist: Int = 2
    ) async throws -> SpotifyPlaylist {

        // 1. Get the current user ID
        let profile = try await getCurrentUserProfile()
        let userId = profile.id

        // 2. Resolve artists -> Spotify IDs and collect top tracks
        var collectedURIs: [String] = []

        for artist in artists {
            // Try direct ID first (if you ever populate it from MusicBrainz)
            var spotifyId: String? = artist.spotifyID

            // Fallback: search by name if we don't have a direct Spotify ID
            if spotifyId == nil {
                let searchResult = try await searchArtistByName(
                    name: artist.name,
                    market: countryCode,
                    genreHint: genre
                )
                spotifyId = searchResult?.id
            }

            guard let id = spotifyId else {
                // Could not resolve this artist at all
                continue
            }

            // Fetch their top tracks
            let topTracks = try await getArtistTopTracks(
                artistId: id,
                market: countryCode
            )

            // Take the first `tracksPerArtist`
            let chosen = topTracks.prefix(tracksPerArtist)
            collectedURIs.append(contentsOf: chosen.map { $0.uri })
        }

        let uniqueURIs = Array(Set(collectedURIs))

        guard !uniqueURIs.isEmpty else {
            throw SpotifyServiceError.noTracksFound
        }

        // 3. Create playlist
        let playlistName = "\(countryName) \(genre) Mix"
        let description = "Generated with Disco-Music: top \(genre) tracks from \(countryName)."

        let playlist = try await createPlaylist(
            userId: userId,
            name: playlistName,
            description: description,
            isPublic: false
        )

        // 4. Add tracks to playlist
        try await addTracksToPlaylist(
            playlistId: playlist.id,
            trackURIs: uniqueURIs
        )

        return playlist
    }
}
