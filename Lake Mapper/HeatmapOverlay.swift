import Foundation
import MapKit

class DepthHeatmapOverlay: NSObject, MKOverlay {
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var boundingMapRect: MKMapRect = MKMapRect.world
    var waypoints: [Waypoint]

    init(waypoints: [Waypoint]) {
        self.waypoints = waypoints
        super.init()
    }
}

class DepthHeatmapRenderer: MKOverlayRenderer {
    private var overlayData: DepthHeatmapOverlay {
        overlay as! DepthHeatmapOverlay
    }

    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard !overlayData.waypoints.isEmpty else { return }
        let maxDepth = overlayData.waypoints.map { $0.depth }.max() ?? 1
        let minDepth = overlayData.waypoints.map { $0.depth }.min() ?? 0
        for waypoint in overlayData.waypoints {
            let point = self.point(for: MKMapPoint(waypoint.coordinate))
            let radius = max(30.0, waypoint.depth * 5.0) / zoomScale
            let color = DepthHeatmapRenderer.color(for: waypoint.depth, min: minDepth, max: maxDepth)
            let cgColor = color.cgColor
            let colors: [CGColor] = [cgColor.copy(alpha: 0.6)!, cgColor.copy(alpha: 0.0)!]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1]) {
                context.drawRadialGradient(gradient,
                                          startCenter: point,
                                          startRadius: 0,
                                          endCenter: point,
                                          endRadius: radius,
                                          options: .drawsAfterEndLocation)
            }
        }
    }

    static func color(for depth: Double, min: Double, max: Double) -> UIColor {
        let normalized = max(0, min( (depth - min) / max(max - min, 0.0001), 1 ))
        return UIColor(hue: 0.6, saturation: 1.0, brightness: 1.0 - CGFloat(normalized) * 0.6, alpha: 1.0)
    }
}
