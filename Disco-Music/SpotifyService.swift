//
//  SpotifyService.swift
//  Disco-Music
//
//  Created by Parissa Teli on 11/28/25.

import Foundation
import Combine

// MARK: - Public Models & Errors



// MARK: - Internal DTOs (Web API shapes)

fileprivate struct SpotifyUserProfile: Decodable {
    let id: String
    let display_name: String?
}

fileprivate struct SpotifySearchArtist: Decodable {
    let id: String
    let name: String
    let genres: [String]?
}

fileprivate struct SpotifySearchArtistsPage: Decodable {
    let items: [SpotifySearchArtist]
}

fileprivate struct SpotifySearchResponse: Decodable {
    let artists: SpotifySearchArtistsPage
}

fileprivate struct SpotifyTopTracksResponse: Decodable {
    let tracks: [SpotifyTrack]
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

// MARK: - Spotify Web API Service

final class SpotifyWebAPI: ObservableObject {
    @Published var currentTrack: SpotifyTrack?
    @Published var isPlaying: Bool = false
    @Published var currentPlaylist: SpotifyPlaylist?

    static let shared = SpotifyWebAPI()
    private init() {}

    private let baseURL = URL(string: "https://api.spotify.com/v1")!

    /// Access token from your auth manager
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

        // 1. Ensure we have a token
        guard let token = accessToken else {
            throw SpotifyServiceError.noAccessToken
        }

        // 2. Build URL
        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = queryItems

        guard let url = components.url else {
            throw SpotifyServiceError.invalidURL
        }

        // 3. Build request
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            let encoder = JSONEncoder()
            req.httpBody = try encoder.encode(AnyEncodable(body))
        }

        // 4. Perform request
        let (data, resp) = try await URLSession.shared.data(for: req)

        guard let http = resp as? HTTPURLResponse else {
            throw SpotifyServiceError.badResponse(
                status: -1,
                message: "Non-HTTP response from Spotify."
            )
        }

        guard (200..<300).contains(http.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8) ?? "<no body>"
            print("Spotify API error \(http.statusCode): \(bodyString)")
            throw SpotifyServiceError.badResponse(status: http.statusCode, message: bodyString)
        }

        // 5. Decode
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Low-Level Web API Calls

    /// GET /v1/me – current user profile
    private func getCurrentUserProfile() async throws -> SpotifyUserProfile {
        try await request(
            path: "me",
            decode: SpotifyUserProfile.self
        )
    }

    /// Public helper if you ever want to debug the current user ID
    func getCurrentUserId() async throws -> String {
        let profile = try await getCurrentUserProfile()
        return profile.id
    }

    /// GET /v1/artists/{id}/top-tracks
    func getArtistTopTracks(artistId: String, market: String) async throws -> [SpotifyTrack] {
        let response: SpotifyTopTracksResponse = try await request(
            path: "artists/\(artistId)/top-tracks",
            queryItems: [
                URLQueryItem(name: "market", value: market)
            ],
            decode: SpotifyTopTracksResponse.self
        )
        return response.tracks
    }

    // POST /v1/users/{user_id}/playlists (Create Playlist – matches Spotify docs)
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
    
    func fetchFullPlaylist(playlistId: String, market: String? = nil) async throws -> SpotifyPlaylist {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "fields", value: "id,name,description,uri,images,tracks.items(track(id,name,uri,artists,album,duration_ms))")
        ]
        
        if let market = market {
            queryItems.append(URLQueryItem(name: "market", value: market))
        }
        
        return try await request(
            path: "playlists/\(playlistId)",
            queryItems: queryItems,
            decode: SpotifyPlaylist.self
        )
    }

    /// GET /v1/search?type=artist – search by name (+ optional genre/maket bias)
    fileprivate func searchArtistByName(
        name: String,
        market: String? = nil,
        genreHint: String? = nil
    ) async throws -> SpotifySearchArtist? {

        var query = name
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

        return response.artists.items.first
    }

    // MARK: - High-Level Playlist Generation
    //
    // Parameters:
    //  - countryCode: Spotify market (e.g. "US", "BR", "JP")
    //  - countryName: human readable (for playlist title)
    //  - genre: genre label (for title/description + search bias)
    //  - artists: MusicBrainz → Artist models
    //  - tracksPerArtist: how many top tracks per artist to include

    func generatePlaylist(
        countryCode: String,
        countryName: String,
        genre: String,
        artists: [Artist],
        tracksPerArtist: Int = 2
    ) async throws -> SpotifyPlaylist {

        // 1. Current user (for /users/{user_id}/playlists)
        let profile = try await getCurrentUserProfile()
        let userId = profile.id

        // 2. Resolve artists → Spotify IDs, collect top tracks
        var collectedURIs: [String] = []

        for artist in artists {
            var spotifyId: String? = artist.spotifyID

            // If MusicBrainz didn't give us a Spotify ID, fall back to search
            if spotifyId == nil {
                let searchResult = try await searchArtistByName(
                    name: artist.name,
                    market: countryCode,
                    genreHint: genre
                )
                spotifyId = searchResult?.id
            }

            guard let id = spotifyId else {
                continue // skip artists we can't resolve
            }

            // Pull that artist's top tracks for this market
            let topTracks = try await getArtistTopTracks(
                artistId: id,
                market: countryCode
            )

            let chosen = topTracks.prefix(tracksPerArtist)
            collectedURIs.append(contentsOf: chosen.map { $0.uri })
        }

        // De-dupe tracks
        let uniqueURIs = Array(Set(collectedURIs))

        guard !uniqueURIs.isEmpty else {
            throw SpotifyServiceError.noTracksFound
        }

        // 3. Create playlist (this is the Create Playlist endpoint from the docs)
        let playlistName = "\(countryName) \(genre) Mix"
        let description = "Generated with Disco-Music: top \(genre) tracks from \(countryName)."

        let playlist = try await createPlaylist(
            userId: userId,
            name: playlistName,
            description: description,
            isPublic: false   // keep private by default
        )

        // 4. Add tracks to that playlist
        try await addTracksToPlaylist(
            playlistId: playlist.id,
            trackURIs: uniqueURIs
        )

        let completePlaylist = try await fetchFullPlaylist(playlistId: playlist.id, market: countryCode)
        
        return completePlaylist
    }
    
    func fetchArtistImageURL(for artist: Artist) async throws -> URL? {
        // 1. Resolve the Spotify artist ID (same idea as in generatePlaylist)
        var spotifyId: String? = artist.spotifyID
        
        if spotifyId == nil {
            // Fallback: search by name, no market/genre bias here (or you can add them)
            let searchResult = try await searchArtistByName(
                name: artist.name,
                market: nil,
                genreHint: nil
            )
            spotifyId = searchResult?.id
        }
        
        guard let id = spotifyId else {
            print("No Spotify ID found for artist: \(artist.name)")
            return nil
        }
        
        // 2. Call Spotify's /v1/artists/{id} using your existing request() helper
        struct SpotifyArtistDetails: Decodable {
            let images: [SpotifyImage]
        }
        
        struct SpotifyImage: Decodable {
            let url: String
            let width: Int?
            let height: Int?
        }
        
        let details: SpotifyArtistDetails = try await request(
            path: "artists/\(id)",
            decode: SpotifyArtistDetails.self
        )
        
        // 3. Return the highest-res image URL (Spotify puts largest first)
        return details.images.first.flatMap { URL(string: $0.url) }
    }
    
}
