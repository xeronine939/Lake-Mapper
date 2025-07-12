import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var waypoints: [Waypoint]
    @Binding var region: MKCoordinateRegion
    @Binding var droppedCoordinate: CLLocationCoordinate2D?
    var onLongPress: (CLLocationCoordinate2D) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.setRegion(region, animated: false)

        let press = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePress(_:)))
        mapView.addGestureRecognizer(press)

        // Add heatmap overlay
        let heatmap = DepthHeatmapOverlay(waypoints: waypoints)
        mapView.addOverlay(heatmap)
        context.coordinator.heatmapOverlay = heatmap

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setRegion(region, animated: true)
        context.coordinator.updateAnnotations(from: waypoints,
                                              dropped: droppedCoordinate,
                                              on: uiView)
        if let overlay = context.coordinator.heatmapOverlay {
            overlay.waypoints = waypoints
            context.coordinator.heatmapRenderer?.setNeedsDisplay()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var annotations: [UUID: MKPointAnnotation] = [:]
        var heatmapOverlay: DepthHeatmapOverlay?
        var heatmapRenderer: DepthHeatmapRenderer?

        init(parent: MapView) {
            self.parent = parent
        }

        var droppedAnnotation: MKPointAnnotation?
        var overlays: [UUID: [MKCircle]] = [:]

        func updateAnnotations(from waypoints: [Waypoint],
                               dropped: CLLocationCoordinate2D?,
                               on mapView: MKMapView) {
            let existingIDs = Set(annotations.keys)
            let currentIDs = Set(waypoints.map { $0.id })
            for id in existingIDs.subtracting(currentIDs) {
                if let anno = annotations[id] {
                    mapView.removeAnnotation(anno)
                    annotations.removeValue(forKey: id)
                }
                if let circs = overlays[id] {
                    mapView.removeOverlays(circs)
                    overlays.removeValue(forKey: id)
                }
            }
            for waypoint in waypoints {
                if let anno = annotations[waypoint.id] {
                    anno.coordinate = waypoint.coordinate
                    anno.title = String(format: "%.1f m", waypoint.depth)
                    if let circs = overlays[waypoint.id] {
                        mapView.removeOverlays(circs)
                    }
                    overlays[waypoint.id] = makeCircles(for: waypoint)
                    mapView.addOverlays(overlays[waypoint.id]!)
                } else {
                    let anno = MKPointAnnotation()
                    anno.coordinate = waypoint.coordinate
                    anno.title = String(format: "%.1f m", waypoint.depth)
                    annotations[waypoint.id] = anno
                    mapView.addAnnotation(anno)
                    let circs = makeCircles(for: waypoint)
                    overlays[waypoint.id] = circs
                    mapView.addOverlays(circs)
                }
            }

            // Handle dropped annotation
            if let dropped = dropped {
                if let anno = droppedAnnotation {
                    anno.coordinate = dropped
                } else {
                    let anno = MKPointAnnotation()
                    anno.coordinate = dropped
                    droppedAnnotation = anno
                    mapView.addAnnotation(anno)
                }
            } else if let anno = droppedAnnotation {
                mapView.removeAnnotation(anno)
                droppedAnnotation = nil
            }
        }

        private func makeCircles(for waypoint: Waypoint) -> [MKCircle] {
            // Create three concentric circles scaled by depth
            var circles: [MKCircle] = []
            let base = max(10.0, waypoint.depth * 3)
            for i in 1...3 {
                circles.append(MKCircle(center: waypoint.coordinate,
                                        radius: CLLocationDistance(base * Double(i))))
            }
            return circles
        }

        @objc func handlePress(_ gesture: UILongPressGestureRecognizer) {
            if gesture.state == .began, let mapView = gesture.view as? MKMapView {
                let point = gesture.location(in: mapView)
                let coord = mapView.convert(point, toCoordinateFrom: mapView)
                parent.onLongPress(coord)
            }
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }
            let identifier = "pin"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
            if view == nil {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view?.canShowCallout = true
                view?.isDraggable = true
            } else {
                view?.annotation = annotation
            }
            return view
        }

        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
            guard newState == .ending || newState == .none,
                  let annotation = view.annotation,
                  let id = annotations.first(where: { $0.value === annotation })?.key,
                  let index = parent.waypoints.firstIndex(where: { $0.id == id }) else { return }
            parent.waypoints[index].coordinate = annotation.coordinate
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let heatmap = overlay as? DepthHeatmapOverlay {
                let renderer = DepthHeatmapRenderer(overlay: heatmap)
                heatmapRenderer = renderer
                return renderer
            }
            if let circle = overlay as? MKCircle {
                let renderer = MKCircleRenderer(circle: circle)
                renderer.fillColor = UIColor.blue.withAlphaComponent(0.1)
                renderer.strokeColor = UIColor.blue
                renderer.lineWidth = 1
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.region = mapView.region
        }
    }
}
