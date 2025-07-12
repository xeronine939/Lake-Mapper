import Foundation
import CoreLocation

struct Waypoint: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var depth: Double
}
