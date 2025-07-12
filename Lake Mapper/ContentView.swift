import SwiftUI
import MapKit
import Combine

struct ContentView: View {
    enum ViewMode { case map, waypoints }

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
    @State private var hasCenteredOnUser = false
    @State private var viewMode: ViewMode = .map
    @StateObject private var locationManager = LocationManager()
    @State private var droppedCoordinate: CLLocationCoordinate2D?

    var body: some View {
        NavigationView {
            Group {
                if viewMode == .map {
                    VStack(spacing: 0) {
                        ZStack(alignment: .topTrailing) {
                            MapView(waypoints: $waypoints,
                                    region: $region,
                                    droppedCoordinate: $droppedCoordinate) { coord in
                                addWaypoint(at: coord)
                            }
                            VStack {
                                Button(action: centerOnUser) {
                                    Image(systemName: "location.fill")
                                        .padding(8)
                                        .background(Color.white.opacity(0.8))
                                        .clipShape(Circle())
                                }
                                Button(action: { showCoords = true }) {
                                    Image(systemName: "plus")
                                        .padding(8)
                                        .background(Color.white.opacity(0.8))
                                        .clipShape(Circle())
                                }
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
                            .padding()
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
                                    addWaypointFromForm()
                                }
                            }
                        }
                        .frame(maxHeight: 220)
                    }
                } else {
                    WaypointListView(waypoints: $waypoints)
                }
            }
            .navigationTitle("Lake Mapper")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button("Map View") { viewMode = .map }
                        Button("Waypoints") { viewMode = .waypoints }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                }
            }
        }
        .onReceive(locationManager.$location.compactMap { $0 }) { loc in
            if !hasCenteredOnUser {
                region.center = loc.coordinate
                hasCenteredOnUser = true
            }
        }
    }

    private func addWaypointFromForm() {
        guard let lat = Double(latText),
              let lon = Double(lonText),
              let depth = Double(depthText) else { return }
        let depthMeters = useFeet ? depth * 0.3048 : depth
        let waypoint = Waypoint(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon), depth: depthMeters)
        waypoints.append(waypoint)
        droppedCoordinate = nil
        latText = ""
        lonText = ""
        depthText = ""
    }

    private func addWaypoint(at coord: CLLocationCoordinate2D) {
        droppedCoordinate = coord
        latText = String(format: "%.6f", coord.latitude)
        lonText = String(format: "%.6f", coord.longitude)
    }

    private func centerOnUser() {
        if let loc = locationManager.location {
            region.center = loc.coordinate
        }
    }
}

#Preview {
    ContentView()
}
