import SwiftUI
import RealityKit
import Combine

// MARK: - Countries List View

struct CountriesListView: View {
    @ObservedObject var dataProvider: CountriesDataProvider
    @Binding var selectedCountry: Country?
    @State private var searchText = ""
    
    var filteredCountries: [Country] {
        if searchText.isEmpty {
            return dataProvider.countries
        }
        return dataProvider.countries.filter { country in
            country.name.localizedCaseInsensitiveContains(searchText) ||
            country.capital.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                List(filteredCountries) { country in
                    NavigationLink(destination: CountryDetailView(country: country)) {
                        HStack {
                            Text(country.flagEmoji)
                                .font(.largeTitle)
                                .foregroundColor(.appTextLight)
                            
                            VStack(alignment: .leading) {
                                Text(country.name)
                                    .font(.headline)
                                    .foregroundColor(.appTextLight)
                                Text(country.capital)
                                    .font(.subheadline)
                                    .foregroundColor(.appTextLight)
                                    .opacity(0.7)
                            }
                            
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.appBackgroundDark.opacity(0.1))
                    
                }
                .scrollContentBackground(.hidden)
                .background(LinearGradient(colors: [.appBackgroundLight, .appBackgroundDark], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                        
                )
                .searchable(text: $searchText, prompt: "Search countries or capitals")
            }
        }
        .navigationBarHidden(true) // Hide navigation bar for CountriesListView
    }
}

// MARK: - About View

struct AboutView: View {
    @StateObject private var authManager = SpotifyAuthManager.shared
    @State private var showingLogoutAlert = false
    @State private var showingLoginController = false
    
    var body: some View {
        ZStack{
            LinearGradient(colors: [Color(red: 76/255, green: 168/255, blue: 183/255), .appBackgroundDark], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Interactive Globe")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.appTextLight)
                    
                    Text("Explore the world through an interactive 3D globe powered by RealityKit. Tap on capital cities to learn more about different countries.")
                        .font(.body)
                        .foregroundColor(.appTextLight)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Features")
                            .font(.headline)
                        
                        FeatureRow(icon: "globe", text: "Interactive 3D globe with RealityKit rendering")
                        FeatureRow(icon: "hand.draw", text: "Drag to rotate, pinch to zoom")
                        FeatureRow(icon: "mappin.circle", text: "Tap capital cities for detailed information")
                        FeatureRow(icon: "list.bullet", text: "Browse all countries in list view")
                        FeatureRow(icon: "camera", text: "Toggle AR mode to view globe in real world")
                        FeatureRow(icon: "moon.stars", text: "Enjoy starry night sky in non-AR mode")
                    }.foregroundColor(.appTextLight)
                    
                    Divider()
                    
                    // Spotify Account Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Spotify Account")
                            .font(.headline)
                            .foregroundColor(.appTextLight)
                        
                        HStack {
                            Image(systemName: authManager.isAuthenticated ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(authManager.isAuthenticated ? .green : .gray)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(authManager.isAuthenticated ? "Connected" : "Not Connected")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text(authManager.isAuthenticated ? "You can create playlists" : "Connect to enable playlist creation")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Sign Out / Sign In Button
                        if authManager.isAuthenticated {
                            Button(action: {
                                showingLogoutAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Sign Out of Spotify")
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(12)
                            }
                        } else {
                            Button(action: {
                                showingLoginController = true
                            }) {
                                HStack {
                                    Image(systemName: "music.note")
                                    Text("Sign In to Spotify")
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 30/255, green: 215/255, blue: 96/255))
                                .foregroundColor(.appTextLight)
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    Divider()
                    
                    Text("Built with SwiftUI and RealityKit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding()
                .padding(.bottom, 100)
            }
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)

            .background(
                ZStack {
                    LinearGradient(
                        colors: [.appBackgroundLight, .appBackgroundDark],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    SpotifyLoginControllerWrapper(
                        isPresented: $showingLoginController,
                        onSuccess: {
                            showingLoginController = false
                        }
                    )
                }
                    .ignoresSafeArea()
            )
            .alert("Sign Out of Spotify?", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authManager.logout()
                }
            } message: {
                Text("You'll need to sign in again to create playlists and access Spotify features.")
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            Text(text)
                .font(.subheadline)
        }
    }
}

struct ExploreView: View {
    @ObservedObject var dataProvider: CountriesDataProvider
    @Binding var selectedCountry: Country?
    @Binding var isARModeEnabled: Bool
    @Binding var explorePage: ExplorePage
    var body: some View {
        ZStack(alignment: .top) {
            // Main page content
            Group {
                switch explorePage {
                case .globe:
                    GlobeRealityView(
                        dataProvider: dataProvider,
                        selectedCountry: $selectedCountry,
                        isARModeEnabled: $isARModeEnabled
                    )
                    .edgesIgnoringSafeArea(.all)
                    
                case .list:
                    CountriesListView(
                        dataProvider: dataProvider,
                        selectedCountry: $selectedCountry
                    )
                }
            }
            
            // Toggle overlaid at the top
            VStack {
                HStack {
                    Spacer()
                    ExploreToggle(page: $explorePage)
                }
                .padding(.top, 16)
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
}

struct ExploreToggle: View {
    @Binding var page: ExplorePage
    
    var body: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.spring()) {
                    page = .globe
                }
            } label: {
                Text("Globe")
                    .font(.subheadline)
                    .fontWeight(page == .globe ? .bold : .medium)
                    .foregroundColor(page == .globe ? .white : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }

            Button {
                withAnimation(.spring()) {
                    page = .list
                }
            } label: {
                Text("List")
                    .font(.subheadline)
                    .fontWeight(page == .list ? .bold : .medium)
                    .foregroundColor(page == .list ? .white : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Main Content View

enum NavigationTab {
    case explore, recent, likes, about
}

enum ExplorePage{
    case globe
    case list
}

struct ContentView: View {
    @StateObject private var dataProvider = CountriesDataProvider()
    @State private var selectedTab: NavigationTab = .explore
    @State private var explorePage: ExplorePage = .globe
    @State private var selectedCountry: Country?
    @State private var isARModeEnabled = false
    @StateObject private var playerManager = SpotifyPlayerManager.shared
    @StateObject private var authManager = SpotifyAuthManager.shared
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    var body: some View {
        NavigationStack { // Added NavigationStack
            ZStack {
                // Main content based on selected tab
                switch selectedTab {
                case .explore:
                    ExploreView(
                        dataProvider: dataProvider,
                        selectedCountry: $selectedCountry,
                        isARModeEnabled: $isARModeEnabled,
                        explorePage: $explorePage
                    )
                case .recent:
                    RecentPlaylistsView()
                case .likes:
                    LikedGenresView()
                case .about:
                    AboutView()
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    // AR Toggle (only visible in globe view)
                    if selectedTab == .explore && explorePage == .globe {
                        HStack {
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Toggle("", isOn: $isARModeEnabled)
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                                
                                Text(isARModeEnabled ? "AR Mode" : "AR Mode")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                            .padding()
                        }
                    }
                    // Navigation Dashboard
                    VStack (spacing: 0){
                        if playerManager.isConnected {
                            SpotifyMiniPlayer()
                                .padding(.horizontal)
                                .padding(.bottom, 4)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        Rectangle()
                            .fill(Color.white.opacity(1.0))
                            .frame(height: 1.0)
                            .padding(.horizontal, 0)
                        
                        HStack {
                            DashboardButton(icon: "globe.americas", title: "Explore", isSelected: selectedTab == .explore) {
                                selectedTab = .explore
                            }
                            DashboardButton(
                                icon: "music.note.arrow.trianglehead.clockwise",
                                title: "Recent",
                                isSelected: selectedTab == .recent,
                            ) {
                                selectedTab = .recent
                            }
                            DashboardButton(icon: "heart", title: "Likes", isSelected: selectedTab == .likes) {
                                selectedTab = .likes
                            }
                            
                            DashboardButton(icon: "person", title: "About", isSelected: selectedTab == .about) {
                                selectedTab = .about
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                        .padding(.bottom, 0)
                        .background(Color.black)
                    }
                }
            }
            /*.sheet(item: $selectedCountry) { country in
                CountryDetailView(country: country)
            }*/
            .fullScreenCover(isPresented: .constant(!hasSeenOnboarding)) {
                OnboardingView(showOnboarding: .init(
                    get: { !hasSeenOnboarding },
                    set: { if !$0 { hasSeenOnboarding = true } }
                ))                    
            }
            .onAppear {
                if authManager.isAuthenticated && !playerManager.isConnected {
                    playerManager.connect()
                }
            }
            .onChange(of: authManager.isAuthenticated) { oldValue, newValue in
                if newValue {
                    playerManager.connect()
                } else {
                    playerManager.disconnect()
                }
            }
        }
    }
}

struct DashboardButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(.white)
            .fontWeight(isSelected ? .bold : .regular)
            .frame(maxWidth: .infinity)
            
        }
    }
}

// MARK: - Previews

#Preview("Main App") {
    ContentView()
}

#Preview("Countries List") {
    CountriesListView(
        dataProvider: CountriesDataProvider(),
        selectedCountry: .constant(nil)
    )
}

#Preview("About View") {
    AboutView()
}
