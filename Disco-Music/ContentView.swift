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
            List(filteredCountries) { country in
                Button(action: {
                    selectedCountry = country
                }) {
                    HStack {
                        Text(country.flagEmoji)
                            .font(.largeTitle)
                        
                        VStack(alignment: .leading) {
                            Text(country.name)
                                .font(.headline)
                            Text(country.capital)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search countries or capitals")
            .navigationTitle("Countries")
        }
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Interactive Globe")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Explore the world through an interactive 3D globe powered by RealityKit. Tap on capital cities to learn more about different countries.")
                        .font(.body)
                    
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
                    }
                    
                    Divider()
                    
                    Text("Built with SwiftUI and RealityKit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("About")
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

// MARK: - Main Content View

enum NavigationTab {
    case globe, list, about
}

struct ContentView: View {
    @StateObject private var dataProvider = CountriesDataProvider()
    @State private var selectedTab: NavigationTab = .globe
    @State private var selectedCountry: Country?
    @State private var isARModeEnabled = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    var body: some View {
        ZStack {
            // Main content based on selected tab
            switch selectedTab {
            case .globe:
                GlobeRealityView(
                    dataProvider: dataProvider,
                    selectedCountry: $selectedCountry,
                    isARModeEnabled: $isARModeEnabled
                )
                .edgesIgnoringSafeArea(.all)
            case .list:
                CountriesListView(dataProvider: dataProvider, selectedCountry: $selectedCountry)
            case .about:
                AboutView()
            }
            
            // AR Toggle (only visible in globe view)
            if selectedTab == .globe {
                VStack {
                    HStack {
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Image(systemName: isARModeEnabled ? "camera.fill" : "moon.stars.fill")
                                .foregroundColor(isARModeEnabled ? .blue : .purple)
                                .font(.system(size: 16))
                            
                            Toggle("", isOn: $isARModeEnabled)
                                .labelsHidden()
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                            
                            Text(isARModeEnabled ? "AR Mode" : "Starfield")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .padding()
                    }
                    
                    Spacer()
                }
            }
            
            // Navigation Dashboard
            VStack {
                Spacer()
                
                HStack(spacing: 30) {
                    DashboardButton(icon: "globe", title: "Globe", isSelected: selectedTab == .globe) {
                        selectedTab = .globe
                    }
                    
                    DashboardButton(icon: "list.bullet", title: "List", isSelected: selectedTab == .list) {
                        selectedTab = .list
                    }
                    
                    DashboardButton(icon: "info.circle", title: "About", isSelected: selectedTab == .about) {
                        selectedTab = .about
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding()
            }
        }
        .sheet(item: $selectedCountry) { country in
            CountryDetailView(country: country)
        }
        .fullScreenCover(isPresented: .constant(!hasSeenOnboarding)) {
            OnboardingView(showOnboarding: .init(get: { !hasSeenOnboarding },
                                                 set: { if !$0 { hasSeenOnboarding = true }}))
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
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .blue : .primary)
            .frame(width: 80, height: 60)
        }
    }
}

// MARK: - App Entry Point

@main
struct InteractiveGlobeApp: App {
    var body: some SwiftUI.Scene {
        WindowGroup {
            ContentView()
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
