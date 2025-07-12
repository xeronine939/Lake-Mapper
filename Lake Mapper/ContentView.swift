import SwiftUI
import MapKit

struct ContentView: View {
    @State private var waypoints: [Waypoint] = []
    @State private var latText = ""
    @State private var lonText = ""
    @State private var depthText = ""

    var body: some View {
        VStack(spacing: 0) {
            MapView(waypoints: $waypoints)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Form {
                Section(header: Text("Add Waypoint")) {
                    TextField("Latitude", text: $latText)
                        .keyboardType(.decimalPad)
                    TextField("Longitude", text: $lonText)
                        .keyboardType(.decimalPad)
                    TextField("Depth (m)", text: $depthText)
                        .keyboardType(.decimalPad)
                    Button("Add") {
                        addWaypoint()
                    }
                }
            }
            .frame(maxHeight: 220)
        }
    }

    private func addWaypoint() {
        guard let lat = Double(latText),
              let lon = Double(lonText),
              let depth = Double(depthText) else { return }
        let waypoint = Waypoint(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon), depth: depth)
        waypoints.append(waypoint)
        latText = ""
        lonText = ""
        depthText = ""
    }
}

#Preview {
    ContentView()
}
