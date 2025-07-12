import SwiftUI
import MapKit

struct MapView: View {
    @Binding var waypoints: [Waypoint]
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 45.0, longitude: -90.0),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: waypoints) { waypoint in
            MapAnnotation(coordinate: waypoint.coordinate) {
                VStack(spacing: 2) {
                    Image(systemName: "mappin")
                        .foregroundColor(.red)
                    Text(String(format: "%.1f m", waypoint.depth))
                        .font(.caption2)
                        .padding(2)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(3)
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}
