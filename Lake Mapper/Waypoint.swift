import Foundation
import CoreLocation

struct Waypoint: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let depth: Double
}
