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

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet var mapView: MKMapView!
    let annotation = MKPointAnnotation()
    let locationManager = CLLocationManager()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        mapView.showsUserLocation = true
        
        
        self.mapView.delegate = self
        
        let createAnnotation = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognizer))
        self.view.addGestureRecognizer(createAnnotation)
    }
    
    // Drop a NEW PIN
    func tapGestureRecognizer(tapGestureRecognizer: UITapGestureRecognizer) {
        print("Gesture Recognized")
        
        // Delete previous annotations so only one pin exists on the map at one time
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
        let touchPoint = tapGestureRecognizer.locationInView(self.mapView)
        let newCoordinate: CLLocationCoordinate2D = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        // Callout Annotation
        annotation.coordinate = newCoordinate
        annotation.title = "New Pin"
        annotation.subtitle = "Sweet Annotation Bruh!"
        mapView.addAnnotation(annotation)
        
        // Create circle with the Pin
        let fenceDistance: CLLocationDistance = 3000
        let circle = MKCircle(centerCoordinate: newCoordinate, radius: fenceDistance)
        let circleRenderer = MKCircleRenderer(overlay: circle)
        circleRenderer.lineWidth = 3.0
        circleRenderer.strokeColor = UIColor.purpleColor()
        circleRenderer.fillColor = UIColor.purpleColor().colorWithAlphaComponent(0.4)
        
        // Creates the span and animated zoomed into an area
        let span = MKCoordinateSpanMake(0.2, 0.2)
        let region = MKCoordinateRegion(center: newCoordinate, span: span)
        mapView.setRegion(region, animated: true)
        
        // Zoom into new pin without a region
        //self.mapView.showAnnotations(self.mapView.annotations, animated: true)
        
        // Automatically show annotation callout
        //let yourAnnotationAtIndex = 0
        //mapView.selectAnnotation(mapView.annotations[yourAnnotationAtIndex], animated: false)
        
        mapView.addOverlay(circle)
        
    }
    
    // MARK: Functions that update the model/associated views with geotification changes
    
    func addAlarmPin(alarmPin: AlarmPin) {
        addRadiusOverlayForAlarmPin(alarmPin)
    }
    
    func removeAlarmPin(alarmPin: AlarmPin) {
        removeRadiusOverlayForAlarmPin(alarmPin)
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
    
    // Shows the callout with delay
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        
        mapView.addAnnotation(annotation)
        performSelector(#selector(selectAnnotation), withObject: annotation, afterDelay: 0.5)
        
    }
    
    // Shows the callout with delay
    func selectAnnotation(annotation: MKAnnotation) {
        mapView.selectAnnotation(annotation, animated: true)
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
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.last
        let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
        mapView.setRegion(region, animated: false)
        locationManager.stopUpdatingLocation()
        
    }
    
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        
        
    }
}

