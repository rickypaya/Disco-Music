import SwiftUI
import SceneKit
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
        // Sample dataset - expandable with JSON loading
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
        // Extensible for loading from JSON files
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Country].self, from: data) else {
            return
        }
        countries = decoded
    }
}

// MARK: - SceneKit Globe Scene

class GlobeScene: SCNScene {
    let globeNode: SCNNode
    let markerNodes: [SCNNode]
    var countries: [Country]
    
    init(countries: [Country]) {
        self.countries = countries
        self.globeNode = SCNNode()
        self.markerNodes = []
        super.init()
        
        setupScene()
        setupGlobe()
        setupMarkers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    private func setupScene() {
        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 5)
        rootNode.addChildNode(cameraNode)
        
        // Lighting
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor(white: 0.4, alpha: 1.0)
        rootNode.addChildNode(ambientLight)
        
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.intensity = 1000
        directionalLight.position = SCNVector3(x: 5, y: 5, z: 5)
        directionalLight.look(at: SCNVector3Zero)
        rootNode.addChildNode(directionalLight)
    }
    
    private func setupGlobe() {
        let sphere = SCNSphere(radius: 1.0)
        
        // Material for Earth texture
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "earth_texture") ?? UIColor.blue
        material.specular.contents = UIColor(white: 0.1, alpha: 1.0)
        material.shininess = 0.1
        
        // Fix texture wrapping to align with coordinates
        material.diffuse.wrapS = .repeat
        material.diffuse.wrapT = .repeat
        
        sphere.materials = [material]
        
        globeNode.geometry = sphere
        
        // FIXED: No initial rotation needed - markers will align with texture
        // Most Earth textures have 0° longitude at the center, which aligns with
        // the standard spherical coordinate system when no rotation is applied
        
        rootNode.addChildNode(globeNode)
        
        // Add rotation animation
        let rotation = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 60))
        globeNode.runAction(rotation)
    }
    
    private func setupMarkers() {
        for country in countries {
            let marker = createMarker(for: country)
            globeNode.addChildNode(marker)
        }
    }
    
    private func createMarker(for country: Country) -> SCNNode {
        let marker = SCNNode()
        
        // Marker geometry - small sphere
        let sphere = SCNSphere(radius: 0.03)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        material.emission.contents = UIColor.red
        sphere.materials = [material]
        
        marker.geometry = sphere
        marker.name = country.id.uuidString
        
        // Convert lat/long to 3D position
        let position = latLongToSCNVector3(latitude: country.latitude, longitude: country.longitude, radius: 1.01)
        marker.position = position
        
        return marker
    }
    
    private func latLongToSCNVector3(latitude: Double, longitude: Double, radius: Double) -> SCNVector3 {
        // FIXED: Corrected spherical to Cartesian coordinate conversion
        // Standard spherical coordinates: (r, θ, φ) where:
        // θ (theta) = longitude (rotation around Y-axis)
        // φ (phi) = latitude (angle from equator)
        
        // Convert degrees to radians
        let lat = latitude * .pi / 180.0
        let lon = longitude * .pi / 180.0
        
        // Standard spherical to Cartesian conversion for SceneKit
        // X-axis points right, Y-axis points up, Z-axis points toward viewer
        // Longitude 0° should be at positive Z (front of globe)
        // Latitude 0° (equator) should be at Y = 0
        
        let x = radius * cos(lat) * sin(lon)
        let y = radius * sin(lat)
        let z = radius * cos(lat) * cos(lon)
        
        return SCNVector3(x: Float(x), y: Float(y), z: Float(z))
    }
}

// MARK: - SceneKit View Coordinator

class GlobeSceneCoordinator: NSObject, SCNSceneRendererDelegate {
    var parent: GlobeSceneView
    var lastPanLocation: CGPoint?
    
    init(_ parent: GlobeSceneView) {
        self.parent = parent
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let scnView = gesture.view as! SCNView
        let location = gesture.location(in: scnView)
        
        let hitResults = scnView.hitTest(location, options: [:])
        
        if let hit = hitResults.first, let nodeName = hit.node.name,
           let uuid = UUID(uuidString: nodeName),
           let country = parent.dataProvider.countries.first(where: { $0.id == uuid }) {
            parent.selectedCountry = country
        }
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let scnView = gesture.view as? SCNView,
              let scene = scnView.scene as? GlobeScene else {
            return
        }
        
        let translation = gesture.translation(in: scnView)
        
        // Sensitivity for smooth rotation
        let sensitivity: Float = 0.003
        let rotationY = Float(translation.x) * sensitivity
        let rotationX = Float(translation.y) * sensitivity
        
        // Apply rotation to globe node directly
        let currentRotation = scene.globeNode.eulerAngles
        
        // Constrain X rotation (latitude-like) to prevent flipping
        var newRotationX = currentRotation.x - rotationX
        newRotationX = max(-Float.pi / 2, min(Float.pi / 2, newRotationX))
        
        // Y rotation (longitude-like) can be free
        let newRotationY = currentRotation.y + rotationY
        
        scene.globeNode.eulerAngles = SCNVector3(newRotationX, newRotationY, currentRotation.z)
        
        gesture.setTranslation(.zero, in: scnView)
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let scnView = gesture.view as? SCNView,
              let cameraNode = scnView.pointOfView else {
            return
        }
        
        let scale = Float(gesture.scale)
        var position = cameraNode.position
        
        if gesture.state == .changed {
            let newZ = position.z / scale
            position.z = max(2.5, min(10.0, newZ))
            cameraNode.position = position
            gesture.scale = 1.0
        }
    }
}

// MARK: - SwiftUI SceneKit View Wrapper

struct GlobeSceneView: UIViewRepresentable {
    @ObservedObject var dataProvider: CountriesDataProvider
    @Binding var selectedCountry: Country?
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = GlobeScene(countries: dataProvider.countries)
        scnView.backgroundColor = .black
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = false
        scnView.antialiasingMode = .multisampling4X
        
        // Gestures
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(GlobeSceneCoordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(GlobeSceneCoordinator.handlePan(_:)))
        scnView.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(GlobeSceneCoordinator.handlePinch(_:)))
        scnView.addGestureRecognizer(pinchGesture)
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Update scene if data changes
    }
    
    func makeCoordinator() -> GlobeSceneCoordinator {
        GlobeSceneCoordinator(self)
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
                    
                    Text("Explore the world through an interactive 3D globe. Tap on capital cities to learn more about different countries.")
                        .font(.body)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Features")
                            .font(.headline)
                        
                        FeatureRow(icon: "globe", text: "Interactive 3D globe with real-time rendering")
                        FeatureRow(icon: "hand.draw", text: "Drag to rotate, pinch to zoom")
                        FeatureRow(icon: "mappin.circle", text: "Tap capital cities for detailed information")
                        FeatureRow(icon: "list.bullet", text: "Browse all countries in list view")
                    }
                    
                    Divider()
                    
                    Text("Built with SwiftUI and SceneKit")
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
                GlobeSceneView(dataProvider: dataProvider, selectedCountry: $selectedCountry)
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
    var body: some Scene {
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
