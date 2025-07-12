import SwiftUI
import MapKit

struct WaypointListView: View {
    @Binding var waypoints: [Waypoint]

    var body: some View {
        List {
            ForEach($waypoints) { $waypoint in
                NavigationLink(destination: EditWaypointView(waypoint: $waypoint)) {
                    VStack(alignment: .leading) {
                        Text(String(format: "%.6f, %.6f", waypoint.coordinate.latitude, waypoint.coordinate.longitude))
                        Text(String(format: "Depth: %.1f m", waypoint.depth))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete { indices in
                waypoints.remove(atOffsets: indices)
            }
        }
    }
}

struct EditWaypointView: View {
    @Binding var waypoint: Waypoint
    @Environment(\.dismiss) private var dismiss
    @State private var latText: String
    @State private var lonText: String
    @State private var depthText: String

    init(waypoint: Binding<Waypoint>) {
        _waypoint = waypoint
        _latText = State(initialValue: String(format: "%.6f", waypoint.wrappedValue.coordinate.latitude))
        _lonText = State(initialValue: String(format: "%.6f", waypoint.wrappedValue.coordinate.longitude))
        _depthText = State(initialValue: String(format: "%.1f", waypoint.wrappedValue.depth))
    }

    var body: some View {
        Form {
            TextField("Latitude", text: $latText)
                .keyboardType(.decimalPad)
            TextField("Longitude", text: $lonText)
                .keyboardType(.decimalPad)
            TextField("Depth (m)", text: $depthText)
                .keyboardType(.decimalPad)
            Button("Save") {
                if let lat = Double(latText), let lon = Double(lonText), let depth = Double(depthText) {
                    waypoint.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    waypoint.depth = depth
                    dismiss()
                }
            }
        }
        .navigationTitle("Edit Waypoint")
    }
}
