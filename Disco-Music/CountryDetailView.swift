import SwiftUI

// MARK: - Country Detail View

struct CountryDetailView: View {
    let country: Country
    @Environment(\.dismiss) var dismiss
    @State private var selectedGenre: String?
    @State private var showPlaylistPreview = false
    
    //let backgroundBlue = Color(red: 0.047, green: 0.490, blue: 0.627)
    //let backgroundBlueDark = Color(red: 0.04, green: 0.25, blue: 0.31)


    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [.appBackgroundLight, .appBackgroundDark], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 5) {
                        // Header
                        HStack {
                            Text(country.flagEmoji)
                                .font(.system(size: 80))
                            
                            VStack(alignment: .leading) {
                                Text(country.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.appTextLight)

                                Text(country.region)
                                    .font(.subheadline)
                                    .foregroundColor(.appTextLight)
                                    .opacity(0.7)

                            }
                            Spacer()
                        }
                        .padding()
                        
                        Divider()
                        
                        // Details
                        DetailRow(label: "Capital", value: country.capital)
                        
                        DetailRow(label: "Population", value: formattedPopulation(country.population))
                        
                        DetailRow(label: "Region", value: country.region)
                        
                        if let currency = country.currency {
                            DetailRow(label: "Currency", value: currency)
                        }
                        
                        DetailRow(label: "Coordinates", value: String(format: "%.4f°, %.4f°", country.latitude, country.longitude))
                        
                        Divider()
                        
                        // Music Genres Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Originating Genres")
                                .font(.headline)
                                .padding(.horizontal)
                                .foregroundColor(.appTextLight)

                            
                            Text("Tap a genre to discover artists and create a playlist")
                                .font(.caption)
                                .foregroundColor(.appTextLight)
                                .opacity(0.7)
                                .padding(.horizontal)
                            
                            
                            VStack(spacing: 12) {
                                ForEach(country.genres, id: \.self) { genre in
                                    GenreButton(genre: genre) {
                                        selectedGenre = genre
                                        showPlaylistPreview = true
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                        
                        //Spacer()
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showPlaylistPreview) {
                if let genre = selectedGenre {
                    PlaylistPreviewView(country: country, genre: genre)
                }
            }
        }
    }
    
    private func formattedPopulation(_ population: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: population)) ?? "\(population)"
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.appTextLight)
                .opacity(0.7)
            Text(value)
                .font(.body)
                .foregroundColor(.appTextLight)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

// MARK: - Genre Button

struct GenreButton: View {
    let genre: String
    let action: () -> Void
    let buttonCyan = Color(red: 0.0, green: 0.671, blue: 0.725)

    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "music.note.list")
                    .foregroundColor(.appTextLight)
                    .font(.title3)
                
                Text(genre)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.appTextLight)

                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(Color(buttonCyan))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Previews

#Preview("Country Detail") {
    CountryDetailView(country: Country(
        name: "Japan",
        capital: "Tokyo",
        latitude: 35.6762,
        longitude: 139.6503,
        population: 126476461,
        flagEmoji: "🇯🇵",
        region: "Asia",
        currency: "JPY",
        genres: ["J-Pop", "Enka", "City Pop"]
    ))
}


