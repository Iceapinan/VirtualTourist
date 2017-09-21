//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by IceApinan on 20/8/17.
//  Copyright © 2017 IceApinan. All rights reserved.
//

import UIKit
import MapKit
import CoreData
class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    var pins = [Pin]()
    var shouldDelete = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setMapRegion()
        let request : NSFetchRequest<Pin> = Pin.fetchRequest()
        do {
            pins = try AppDelegate.stack.context.fetch(request)
            for pin in pins {
             addAnnotationToMapView(latitude: pin.latitude, longitude: pin.longitude)
            }
        } catch {
            fatalError("\(error.localizedDescription)")
        }
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.navigationItem.rightBarButtonItem?.action = #selector(removeAnnotationTapped)
        self.setEditing(false, animated: false)
    }
    
    @objc func removeAnnotationTapped() {
        switch self.isEditing {
        case false:
            self.setEditing(true, animated: true)
        default:
            self.setEditing(false, animated: true)
        }
        
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if self.isEditing {
            shouldDelete = true
        } else {
            shouldDelete = false
        }
    }
    
    func setMapRegion() {
        guard let span = UserDefaults.standard.value(forKey: AppConstants.MapRegionKeys.span) as? [CLLocationDegrees] else { return }
        guard let center = UserDefaults.standard.value(forKey: AppConstants.MapRegionKeys.center) as? [CLLocationDegrees]  else { return }
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: center[0], longitude: center[1]), span: MKCoordinateSpan(latitudeDelta: span[0], longitudeDelta: span[1]))
        mapView.setRegion(region, animated: true)
    }
    
    func saveMapRegion () {
        let span = [mapView.region.span.latitudeDelta, mapView.region.span.longitudeDelta]
        let center = [mapView.region.center.latitude, mapView.region.center.longitude]
        UserDefaults.standard.setValue(span, forKey: AppConstants.MapRegionKeys.span)
        UserDefaults.standard.setValue(center, forKey: AppConstants.MapRegionKeys.center)
    }
    
    private func addAnnotationToMapView(latitude: Double, longitude: Double) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        mapView.addAnnotation(annotation)
    }
    
    @IBAction func revealRegionDetailsWithLongPressOnMap(sender: UILongPressGestureRecognizer) {
        guard !(self.isEditing) else { return }
        guard (sender.state == UIGestureRecognizerState.began) else { return }
        let touchLocation = sender.location(in: mapView)
        let locationCoordinate = mapView.convert(touchLocation, toCoordinateFrom: mapView)
        let _ = Pin(latitude: locationCoordinate.latitude, longitude: locationCoordinate.longitude, context: AppDelegate.stack.context)
        addAnnotationToMapView(latitude: locationCoordinate.latitude, longitude: locationCoordinate.longitude)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetailVC" {
            let vc = segue.destination as! PhotoAlbumViewController
            vc.pin = (sender as! Pin)
        }
    }

}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Pins") as? MKPinAnnotationView
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Pins")
            annotationView?.animatesDrop = true
        } else {
            annotationView?.annotation = annotation
        }
        return annotationView
    }
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", argumentArray: [view.annotation?.coordinate.latitude as Any, view.annotation?.coordinate.longitude as Any])
        fetch.predicate = predicate
        
        do {
            if let pins = try AppDelegate.stack.context.fetch(fetch) as? [Pin]
                , let pin = pins.first {
                if shouldDelete {
                    AppDelegate.stack.context.delete(pin)
                    mapView.removeAnnotation(view.annotation!)
                    AppDelegate.stack.save()
                } else {
                performSegue(withIdentifier: "showDetailVC", sender: pin)
            }
        }
            
    } catch {
            
        }
    }
}

extension UIViewController {
    
    func alertShow(title : String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        DispatchQueue.main.async {
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: { (alertAction : UIAlertAction!) in
                alert.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func presentViewControllerWithIdentifier(identifier: String, animated: Bool = true, completion: (() -> Void)? = nil) {
        let controller = storyboard!.instantiateViewController(withIdentifier: identifier)
        DispatchQueue.main.async {
            self.present(controller, animated: animated, completion: completion)
        }
    }
    
}


