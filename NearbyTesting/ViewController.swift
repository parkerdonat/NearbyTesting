//
//  ViewController.swift
//  NearbyTesting
//
//  Created by Parker Donat on 3/22/16.
//  Copyright © 2016 Parker Donat. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapView.delegate = self
        
        let createAnnotation = UITapGestureRecognizer(target: self, action: "tapGestureRecognizer:")
        self.view.addGestureRecognizer(createAnnotation)

        // Set the region
//        let newYorkLocation = CLLocationCoordinate2D(latitude: 40.730872, longitude: -74.003066)
//        let span = MKCoordinateSpanMake(0.01, 0.01)
//        let region = MKCoordinateRegion(center: newYorkLocation, span: span)
//        mapView.setRegion(region, animated: true)
        
        // Drop a pin
//        let dropPin = MKPointAnnotation()
//        dropPin.coordinate = newYorkLocation
//        dropPin.title = "New York City"
//        dropPin.subtitle = "Sweet annotation brah!"
//
//        mapView.addAnnotation(dropPin)
    }
    
    // Drop an NEW PIN
    func tapGestureRecognizer(tapGestureRecognizer: UITapGestureRecognizer) {
        print("Gesture Recognized")
        let touchPoint = tapGestureRecognizer.locationInView(self.mapView)
        let newCoordinate: CLLocationCoordinate2D = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinate
        annotation.title = ""
        annotation.subtitle = ""
        mapView.addAnnotation(annotation)
        let fenceDistance: CLLocationDistance = 161000
        //let circleMidPoint = CLLocationCoordinate2DMake(40.730872, -74.003066)
        let circle = MKCircle(centerCoordinate: newCoordinate, radius: fenceDistance)
      
        let circleRenderer = MKCircleRenderer(overlay: circle)
        circleRenderer.lineWidth = 1.0
        circleRenderer.strokeColor = UIColor.purpleColor()
        circleRenderer.fillColor = UIColor.purpleColor().colorWithAlphaComponent(0.4)

        mapView.addOverlay(circle)

    }
    
    // MARK: Functions that update the model/associated views with geotification changes
    
    func addAlarmPin(alarmPin: AlarmPin) {
        addRadiusOverlayForAlarmPin(alarmPin)
    }
    
    // MARK: - Overlay Functions
    
    func addRadiusOverlayForAlarmPin(alarmPin: AlarmPin) {
        // add mapView with MKCircle coordinate and radius
        mapView?.addOverlay(MKCircle(centerCoordinate: alarmPin.coordinate, radius: alarmPin.radius))
    }
    
    func removeRadiusOverlayForAlarmPin(alarmPin: AlarmPin) {
        // call mapView removeOverlay
        // Find exactly one overlay which has the same coordinates & radius to remove
        if let overlays = mapView?.overlays {
            for overlay in overlays {
                if let circleOverlay = overlay as? MKCircle {
                    let coord = circleOverlay.coordinate
                    if coord.latitude == alarmPin.coordinate.latitude && coord.longitude == alarmPin.coordinate.longitude && circleOverlay.radius == alarmPin.radius {
                        mapView?.removeOverlay(circleOverlay)
                        break
                    }
                }
            }
        }
    }
    
    
    // MARK: - MKMapView Delegate Methods
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        // Modify Circle attributes here
        
        if overlay is MKCircle {
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.lineWidth = 1.0
            circleRenderer.strokeColor = UIColor.purpleColor()
            circleRenderer.fillColor = UIColor.purpleColor().colorWithAlphaComponent(0.4)
            return circleRenderer
        }
        return MKOverlayRenderer()
    }
    
//    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
//        // Modify Annotation attributes here
//    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // Segue to editAlarm details
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        // Use if I want to drag the pin
    }
    
    //MARK: - Other MapView Helper Functions
    
//    @IBAction func userTappedToZoomToCurrentLocation(sender: AnyObject) {
//        // zoom to current location
//        zoomToUserLocationInMapView(sender as! MKMapView)
//    }

    func regionWithAlarmPin(alarmPin: AlarmPin) -> CLCircularRegion {
        // create the reagion to show with AlarmPin
        let region = CLCircularRegion(center: alarmPin.coordinate, radius: alarmPin.radius, identifier: alarmPin.identifier)
        //region.notifyOnEntry =  .OnEntry
        return region
    }
    
    func startMonitoringAlarmPin(alarmPin: AlarmPin) {
        // Checks if device is available, checks authorization, and at which region
    }
    
    func zoomToUserLocationInMapView(mapView: MKMapView) {
        if let coordinate = mapView.userLocation.location?.coordinate {
            let region = MKCoordinateRegionMakeWithDistance(coordinate, 10000, 10000)
            mapView.setRegion(region, animated: true)
        }
    }
}

