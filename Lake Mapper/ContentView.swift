import SwiftUI
import MapKit
import Combine

struct ContentView: View {
    @State private var waypoints: [Waypoint] = []
    @State private var latText = ""
    @State private var lonText = ""
    @State private var depthText = ""
    @State private var useFeet = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 45.0, longitude: -90.0),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    @State private var showCoords = false
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                MapView(waypoints: $waypoints, region: $region) { coord in
                    latText = String(format: "%.6f", coord.latitude)
                    lonText = String(format: "%.6f", coord.longitude)
                }
                Button(action: { showCoords = true }) {
                    Image(systemName: "plus")
                        .padding(8)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                }
                .padding()
                .alert("Current Location", isPresented: $showCoords) {
                    Button("OK", role: .cancel) {}
                } message: {
                    if let loc = locationManager.location {
                        Text(String(format: "%.6f, %.6f", loc.coordinate.latitude, loc.coordinate.longitude))
                    } else {
                        Text("Location unavailable")
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Form {
                Section(header: Text("Add Waypoint")) {
                    TextField("Latitude", text: $latText)
                        .keyboardType(.decimalPad)
                    TextField("Longitude", text: $lonText)
                        .keyboardType(.decimalPad)
                    TextField("Depth (\(useFeet ? "ft" : "m"))", text: $depthText)
                        .keyboardType(.decimalPad)
                    Toggle("Use Feet", isOn: $useFeet)
                    Button("Add") {
                        addWaypoint()
                    }
                }
            }
            .frame(maxHeight: 220)
        }
        .onReceive(locationManager.$location.compactMap { $0 }) { loc in
            region.center = loc.coordinate
        }
    }

    private func addWaypoint() {
        guard let lat = Double(latText),
              let lon = Double(lonText),
              let depth = Double(depthText) else { return }
        let depthMeters = useFeet ? depth * 0.3048 : depth
        let waypoint = Waypoint(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon), depth: depthMeters)
        waypoints.append(waypoint)
        latText = ""
        lonText = ""
        depthText = ""
    }
}

#Preview {
    ContentView()
}
