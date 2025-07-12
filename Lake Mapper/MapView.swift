import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var waypoints: [Waypoint]
    @Binding var region: MKCoordinateRegion
    var onLongPress: (CLLocationCoordinate2D) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.setRegion(region, animated: false)

        let press = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePress(_:)))
        mapView.addGestureRecognizer(press)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setRegion(region, animated: true)
        context.coordinator.updateAnnotations(from: waypoints, on: uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var annotations: [UUID: MKPointAnnotation] = [:]

        init(parent: MapView) {
            self.parent = parent
        }

        func updateAnnotations(from waypoints: [Waypoint], on mapView: MKMapView) {
            let existingIDs = Set(annotations.keys)
            let currentIDs = Set(waypoints.map { $0.id })
            for id in existingIDs.subtracting(currentIDs) {
                if let anno = annotations[id] {
                    mapView.removeAnnotation(anno)
                    annotations.removeValue(forKey: id)
                }
            }
            for waypoint in waypoints {
                if let anno = annotations[waypoint.id] {
                    anno.coordinate = waypoint.coordinate
                    anno.title = String(format: "%.1f m", waypoint.depth)
                } else {
                    let anno = MKPointAnnotation()
                    anno.coordinate = waypoint.coordinate
                    anno.title = String(format: "%.1f m", waypoint.depth)
                    annotations[waypoint.id] = anno
                    mapView.addAnnotation(anno)
                }
            }
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
    }
}
