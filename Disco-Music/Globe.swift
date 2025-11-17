import SwiftUI
import RealityKit
import ARKit
import Combine

// MARK: - RealityKit Globe Coordinator

class GlobeCoordinator: NSObject {
    var arView: ARView
    var globeEntity: ModelEntity?
    var markerEntities: [UUID: ModelEntity] = [:]
    var countries: [Country]
    var onCountryTapped: ((Country) -> Void)?
    var starfieldEntity: ModelEntity?
    
    private var lastPanTranslation: CGPoint = .zero
    private var currentRotation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0])
    private var cancellables = Set<AnyCancellable>()
    private var isARMode = false
    
    init(arView: ARView, countries: [Country]) {
        self.arView = arView
        self.countries = countries
        super.init()
        
        setupScene()
        setupStarfield()
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
    
    private func setupStarfield() {
        // Create a large sphere for the starfield background
        let starfieldMesh = MeshResource.generateSphere(radius: 50.0)
        
        var starfieldMaterial = UnlitMaterial()
        starfieldMaterial.color = .init(tint: .black)
        
        let starfield = ModelEntity(mesh: starfieldMesh, materials: [starfieldMaterial])
        starfield.position = [0, 0, -3]
        
        // Add star particles as small spheres
        for _ in 0..<200 {
            let starSize = Float.random(in: 0.02...0.05)
            let starMesh = MeshResource.generateSphere(radius: starSize)
            
            var starMaterial = UnlitMaterial()
            let brightness = Float.random(in: 0.5...1.0)
            starMaterial.color = .init(tint: UIColor(white: CGFloat(brightness), alpha: 1.0))
            
            let star = ModelEntity(mesh: starMesh, materials: [starMaterial])
            
            // Random position on the inside of the sphere
            let theta = Float.random(in: 0...(2 * .pi))
            let phi = Float.random(in: 0...(2 * .pi))
            let radius: Float = 49.0
            
            let x = radius * sin(theta) * cos(phi)
            let y = radius * sin(theta) * sin(phi)
            let z = radius * cos(theta)
            
            star.position = SIMD3<Float>(x, y, z)
            starfield.addChild(star)
        }
        
        starfieldEntity = starfield
        
        if let anchor = arView.scene.anchors.first {
            anchor.addChild(starfield)
        }
    }
    
    private func setupGlobe() {
        // Create globe mesh
        let globeMesh = MeshResource.generateSphere(radius: 1.0)
        
        // Create material
        var material = SimpleMaterial()
        
        // Load the provided Earth texture
        // This texture uses equirectangular projection with:
        // - 0° longitude (Prime Meridian) at the horizontal center
        // - 0° latitude (Equator) at the vertical center
        // - Longitude: -180° (left edge) to +180° (right edge)
        // - Latitude: +90° (top) to -90° (bottom)
        if let texture = try? TextureResource.load(named: "earth_texture") {
            material.color = .init(tint: .white, texture: .init(texture))
        } else {
            // Fallback color if texture not found
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
        let lon = (longitude - 90) * .pi / 180.0
        
        let x = radius * cos(lat) * sin(lon)
        let y = radius * sin(lat)
        let z = radius * cos(lat) * cos(lon)
        
        return SIMD3<Float>(Float(x), Float(y), Float(z))
    }
    
    func toggleARMode(_ enabled: Bool) {
        isARMode = enabled
        
        if enabled {
            // Enable AR mode with camera feed
            let config = ARWorldTrackingConfiguration()
            config.planeDetection = []
            arView.session.run(config, options: [])
            arView.environment.background = .cameraFeed()
            
            // Hide starfield
            starfieldEntity?.isEnabled = false
        } else {
            // Disable AR mode
            arView.session.pause()
            arView.environment.background = .color(.black)
            
            // Show starfield
            starfieldEntity?.isEnabled = true
        }
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
    @Binding var isARModeEnabled: Bool
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.environment.background = .color(.black)
        
        // Start with AR disabled
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
        // Update AR mode when toggle changes
        context.coordinator.globeCoordinator?.toggleARMode(isARModeEnabled)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var globeCoordinator: GlobeCoordinator?
    }
}

#Preview("Main App") {
    ContentView()
}
