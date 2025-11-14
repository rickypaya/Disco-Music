import SwiftUI
import RealityKit
import Combine

// MARK: - Data Models

struct Country: Identifiable, Codable {
    let id: UUID
    let name: String
    let capital: String
    let latitude: Double
    let longitude: Double
    let population: Int
    let flagEmoji: String
    let region: String
    let currency: String?
    
    init(id: UUID = UUID(), name: String, capital: String, latitude: Double, longitude: Double, population: Int, flagEmoji: String, region: String, currency: String? = nil) {
        self.id = id
        self.name = name
        self.capital = capital
        self.latitude = latitude
        self.longitude = longitude
        self.population = population
        self.flagEmoji = flagEmoji
        self.region = region
        self.currency = currency
    }
}

// MARK: - Sample Data Provider

class CountriesDataProvider: NSObject, ObservableObject {
    @Published var countries: [Country] = []
    
    override init() {
        super.init()
        loadCountries()
    }
    
    func loadCountries() {
        countries = [
            Country(name: "United States", capital: "Washington, D.C.", latitude: 38.9072, longitude: -77.0369, population: 331002651, flagEmoji: "🇺🇸", region: "North America", currency: "USD"),
            Country(name: "United Kingdom", capital: "London", latitude: 51.5074, longitude: -0.1278, population: 67886011, flagEmoji: "🇬🇧", region: "Europe", currency: "GBP"),
            Country(name: "France", capital: "Paris", latitude: 48.8566, longitude: 2.3522, population: 65273511, flagEmoji: "🇫🇷", region: "Europe", currency: "EUR"),
            Country(name: "Germany", capital: "Berlin", latitude: 52.5200, longitude: 13.4050, population: 83783942, flagEmoji: "🇩🇪", region: "Europe", currency: "EUR"),
            Country(name: "Japan", capital: "Tokyo", latitude: 35.6762, longitude: 139.6503, population: 126476461, flagEmoji: "🇯🇵", region: "Asia", currency: "JPY"),
            Country(name: "China", capital: "Beijing", latitude: 39.9042, longitude: 116.4074, population: 1439323776, flagEmoji: "🇨🇳", region: "Asia", currency: "CNY"),
            Country(name: "India", capital: "New Delhi", latitude: 28.6139, longitude: 77.2090, population: 1380004385, flagEmoji: "🇮🇳", region: "Asia", currency: "INR"),
            Country(name: "Brazil", capital: "Brasília", latitude: -15.8267, longitude: -47.9218, population: 212559417, flagEmoji: "🇧🇷", region: "South America", currency: "BRL"),
            Country(name: "Australia", capital: "Canberra", latitude: -35.2809, longitude: 149.1300, population: 25499884, flagEmoji: "🇦🇺", region: "Oceania", currency: "AUD"),
            Country(name: "Canada", capital: "Ottawa", latitude: 45.4215, longitude: -75.6972, population: 37742154, flagEmoji: "🇨🇦", region: "North America", currency: "CAD"),
            Country(name: "Russia", capital: "Moscow", latitude: 55.7558, longitude: 37.6173, population: 145934462, flagEmoji: "🇷🇺", region: "Europe/Asia", currency: "RUB"),
            Country(name: "South Africa", capital: "Pretoria", latitude: -25.7479, longitude: 28.2293, population: 59308690, flagEmoji: "🇿🇦", region: "Africa", currency: "ZAR"),
            Country(name: "Egypt", capital: "Cairo", latitude: 30.0444, longitude: 31.2357, population: 102334404, flagEmoji: "🇪🇬", region: "Africa", currency: "EGP"),
            Country(name: "Mexico", capital: "Mexico City", latitude: 19.4326, longitude: -99.1332, population: 128932753, flagEmoji: "🇲🇽", region: "North America", currency: "MXN"),
            Country(name: "Italy", capital: "Rome", latitude: 41.9028, longitude: 12.4964, population: 60461826, flagEmoji: "🇮🇹", region: "Europe", currency: "EUR"),
            Country(name: "Spain", capital: "Madrid", latitude: 40.4168, longitude: -3.7038, population: 46754778, flagEmoji: "🇪🇸", region: "Europe", currency: "EUR"),
            Country(name: "Argentina", capital: "Buenos Aires", latitude: -34.6037, longitude: -58.3816, population: 45195774, flagEmoji: "🇦🇷", region: "South America", currency: "ARS"),
            Country(name: "South Korea", capital: "Seoul", latitude: 37.5665, longitude: 126.9780, population: 51269185, flagEmoji: "🇰🇷", region: "Asia", currency: "KRW"),
            Country(name: "Turkey", capital: "Ankara", latitude: 39.9334, longitude: 32.8597, population: 84339067, flagEmoji: "🇹🇷", region: "Europe/Asia", currency: "TRY"),
            Country(name: "Saudi Arabia", capital: "Riyadh", latitude: 24.7136, longitude: 46.6753, population: 34813871, flagEmoji: "🇸🇦", region: "Asia", currency: "SAR")
        ]
    }
    
    func loadFromJSON(filename: String) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Country].self, from: data) else {
            return
        }
        countries = decoded
    }
}

// MARK: - RealityKit Globe Coordinator

class GlobeCoordinator: NSObject {
    var arView: ARView
    var globeEntity: ModelEntity?
    var markerEntities: [UUID: ModelEntity] = [:]
    var countries: [Country]
    var onCountryTapped: ((Country) -> Void)?
    
    private var lastPanTranslation: CGPoint = .zero
    private var currentRotation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0])
    private var cancellables = Set<AnyCancellable>()
    
    init(arView: ARView, countries: [Country]) {
        self.arView = arView
        self.countries = countries
        super.init()
        
        setupScene()
        setupGlobe()
        setupMarkers()
        setupGestures()
        startRotationAnimation()
    }
    
    private func setupScene() {
        // Create anchor for the scene
        let anchor = AnchorEntity(world: [0, 0, 0])
        arView.scene.addAnchor(anchor)
        
        // Configure lighting
        let directionalLight = DirectionalLight()
        directionalLight.light.intensity = 2000
        directionalLight.look(at: [0, 0, 0], from: [5, 5, 5], relativeTo: nil)
        anchor.addChild(directionalLight)
    }
    
    private func setupGlobe() {
        // Create globe mesh
        let globeMesh = MeshResource.generateSphere(radius: 1.0)
        
        // Create material
        var material = SimpleMaterial()
        
        // Try to load Earth texture, fallback to blue color
        if let texture = try? TextureResource.load(named: "earth_texture") {
            material.color = .init(tint: .white, texture: .init(texture))
        } else {
            material.color = .init(tint: .blue)
        }
        
        material.roughness = .init(floatLiteral: 0.8)
        material.metallic = .init(floatLiteral: 0.1)
        
        // Create globe entity
        let globe = ModelEntity(mesh: globeMesh, materials: [material])
        globe.position = [0, 0, -3]
        
        // Store reference
        globeEntity = globe
        
        // Add to scene
        if let anchor = arView.scene.anchors.first {
            anchor.addChild(globe)
        }
    }
    
    private func setupMarkers() {
        guard let globe = globeEntity else { return }
        
        for country in countries {
            let markerMesh = MeshResource.generateSphere(radius: 0.03)
            var markerMaterial = UnlitMaterial(color: .red)
            markerMaterial.baseColor = MaterialColorParameter.color(.red)
            
            let marker = ModelEntity(mesh: markerMesh, materials: [markerMaterial])
            
            // Convert lat/long to position
            let position = latLongToSIMD3(latitude: country.latitude, longitude: country.longitude, radius: 1.01)
            marker.position = position
            
            // Store country ID in name for tap detection
            marker.name = country.id.uuidString
            
            // Enable collision for tap detection
            marker.generateCollisionShapes(recursive: false)
            
            globe.addChild(marker)
            markerEntities[country.id] = marker
        }
    }
    
    private func latLongToSIMD3(latitude: Double, longitude: Double, radius: Double) -> SIMD3<Float> {
        let lat = latitude * .pi / 180.0
        let lon = longitude * .pi / 180.0
        
        let x = radius * cos(lat) * sin(lon)
        let y = radius * sin(lat)
        let z = radius * cos(lat) * cos(lon)
        
        return SIMD3<Float>(Float(x), Float(y), Float(z))
    }
    
    private func setupGestures() {
        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        // Pan gesture
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        arView.addGestureRecognizer(panGesture)
        
        // Pinch gesture
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: arView)
        
        if let entity = arView.entity(at: location) {
            let entityName = entity.name
            if let uuid = UUID(uuidString: entityName),
               let country = countries.first(where: { $0.id == uuid }) {
                onCountryTapped?(country)
            }
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let globe = globeEntity else { return }
        
        let translation = gesture.translation(in: arView)
        
        if gesture.state == .began {
            lastPanTranslation = .zero
        }
        
        let sensitivity: Float = 0.005
        let deltaX = Float(translation.x - lastPanTranslation.x) * sensitivity
        let deltaY = Float(translation.y - lastPanTranslation.y) * sensitivity
        
        // Create rotation quaternions
        let rotationY = simd_quatf(angle: deltaX, axis: [0, 1, 0])
        let rotationX = simd_quatf(angle: deltaY, axis: [1, 0, 0])
        
        // Apply rotation
        currentRotation = rotationY * currentRotation * rotationX
        globe.orientation = currentRotation
        
        lastPanTranslation = translation
        
        if gesture.state == .ended {
            lastPanTranslation = .zero
        }
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let globe = globeEntity else { return }
        
        if gesture.state == .changed {
            let scale = Float(gesture.scale)
            var position = globe.position
            
            let newZ = position.z / scale
            position.z = max(-10.0, min(-1.5, newZ))
            globe.position = position
            
            gesture.scale = 1.0
        }
    }
    
    private func startRotationAnimation() {
        guard let globe = globeEntity else { return }
        
        Timer.publish(every: 0.016, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                let rotationSpeed: Float = 0.001
                let rotation = simd_quatf(angle: rotationSpeed, axis: [0, 1, 0])
                self.currentRotation = rotation * self.currentRotation
                globe.orientation = self.currentRotation
            }
            .store(in: &cancellables)
    }
}

// MARK: - RealityKit View Wrapper

struct GlobeRealityView: UIViewRepresentable {
    @ObservedObject var dataProvider: CountriesDataProvider
    @Binding var selectedCountry: Country?
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.environment.background = .color(.black)
        
        // Disable AR features for non-AR use
        arView.automaticallyConfigureSession = false
        
        // Create coordinator
        let coordinator = GlobeCoordinator(arView: arView, countries: dataProvider.countries)
        coordinator.onCountryTapped = { country in
            selectedCountry = country
        }
        context.coordinator.globeCoordinator = coordinator
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Update if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var globeCoordinator: GlobeCoordinator?
    }
}

// MARK: - Country Detail View

struct CountryDetailView: View {
    let country: Country
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Text(country.flagEmoji)
                            .font(.system(size: 80))
                        
                        VStack(alignment: .leading) {
                            Text(country.name)
                                .font(.title)
                                .fontWeight(.bold)
                            Text(country.region)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
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
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
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
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

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
    
    var body: some View {
        ZStack {
            // Main content based on selected tab
            switch selectedTab {
            case .globe:
                GlobeRealityView(dataProvider: dataProvider, selectedCountry: $selectedCountry)
                    .edgesIgnoringSafeArea(.all)
            case .list:
                CountriesListView(dataProvider: dataProvider, selectedCountry: $selectedCountry)
            case .about:
                AboutView()
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

#Preview("Country Detail") {
    CountryDetailView(country: Country(
        name: "Japan",
        capital: "Tokyo",
        latitude: 35.6762,
        longitude: 139.6503,
        population: 126476461,
        flagEmoji: "🇯🇵",
        region: "Asia",
        currency: "JPY"
    ))
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
