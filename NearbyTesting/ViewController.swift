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
    var locationManager = CLLocationManager()
    var annotationView: MKPinAnnotationView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        self.mapView.delegate = self
        mapView.showsUserLocation = true
        // Aded from Kaelin
        //mapView.setUserTrackingMode(MKUserTrackingMode.Follow, animated: true)
        
        let createAnnotation = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognizer))
        self.view.addGestureRecognizer(createAnnotation)
        
    }
    
    
    
    //MARK: - Drop a NEW PIN
    func tapGestureRecognizer(tapGestureRecognizer: UITapGestureRecognizer) {
        print("Tap Gesture Recognized!")
        
        locationManager.requestAlwaysAuthorization()
        
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
        let span = MKCoordinateSpanMake(0.1, 0.1)
        let region = MKCoordinateRegion(center: newCoordinate, span: span)
        mapView.setRegion(region, animated: true)
        mapView.addOverlay(circle)
        
        // Add an alarm pin
        let alarm = AlarmPin(coordinate: newCoordinate, radius: fenceDistance, identifier: "")
        addAlarmPin(alarm)
        startMonitoringAlarmPin(alarm)
        
    }
    
    // MARK: To update view with model
    
    func addAlarmPin(alarmPin: AlarmPin) {
        //mapView.addAnnotation(alarmPin)
        addRadiusOverlayForAlarmPin(alarmPin)
        startMonitoringAlarmPin(alarmPin)
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
            circleRenderer.lineWidth = 3.0
            circleRenderer.strokeColor = UIColor.redColor()
            circleRenderer.fillColor = UIColor.redColor().colorWithAlphaComponent(0.4)
            return circleRenderer
        }
        return MKOverlayRenderer()
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        // Modify Annotation attributes here
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        
        let reuseID = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseID) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView!.canShowCallout = true
            pinView?.animatesDrop = true
            pinView?.pinTintColor = UIColor.redColor()
            
            // Add detail button to right callout
            let calloutButton = UIButton.init(type: .DetailDisclosure) as UIButton
            pinView!.rightCalloutAccessoryView = calloutButton
        }
        else {
            pinView!.annotation = annotation
        }
    
        return pinView
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // Segue to editAlarm details
        print("Callout was tapped!")
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
    
    
    
    //MARK: - MapView Helper Functions
    
    // CL requires each geofence to be be represented as a CLCircularRegion before it can be registered for monitoring.
    func regionWithAlarmPin(alarmPin: AlarmPin) -> CLCircularRegion {
        
        // create the region to show with AlarmPin
        let region = CLCircularRegion(center: alarmPin.coordinate, radius: alarmPin.radius, identifier: alarmPin.identifier)
        region.notifyOnEntry = true
        
        return region
    }
    
    func startMonitoringAlarmPin(alarmPin: AlarmPin) {
        // Checks if device is available, checks authorization to be granted permission to use location services, and lastly at which region to begin monitoring
        
        // 1
        if !CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion) {
            let alertController = UIAlertController(title: "Alert!", message: "Geofencing is not supported on this device!", preferredStyle: .Alert)
            
            let defaultAction = UIAlertAction(title: "Cancel", style: .Cancel) { (alert) -> Void in
                print("Canceled button pressed.")
            }
            
            let okAction = UIAlertAction(title: "Okay", style: .Default) { (alert) -> Void in
                print("Okey button pressed")
            }
            
            alertController.addAction(defaultAction)
            alertController.addAction(okAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
            return
        }
        // 2
        if CLLocationManager.authorizationStatus() != .AuthorizedAlways {
            let alertController = UIAlertController(title: "Warning!", message: "Your alarm is saved but will only be activated once you grant Nearby permission to access the device location.", preferredStyle: .Alert)
            
            let defaultAction = UIAlertAction(title: "Cancel", style: .Cancel) { (alert) -> Void in
                print("Canceled button pressed.")
            }
            
            let okAction = UIAlertAction(title: "Okay", style: .Default) { (alert) -> Void in
                print("Okey button pressed")
            }
            
            alertController.addAction(defaultAction)
            alertController.addAction(okAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        // 3
        let region = regionWithAlarmPin(alarmPin)
        // 4
        locationManager.startMonitoringForRegion(region)
    }
    
    // Call when need to stop monitoring region
    func stopMonitoringAlarmPin(alarmPin: AlarmPin) {
        for region in locationManager.monitoredRegions {
            if let circularRegion = region as? CLCircularRegion {
                if circularRegion.identifier == alarmPin.identifier {
                    locationManager.stopMonitoringForRegion(circularRegion)
                }
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Draws the map for the current location
        let location = locations.last
        let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        mapView.setRegion(region, animated: false)
        locationManager.stopUpdatingLocation()
    }
    
    func handleRegionEvent(region: CLRegion) {
        // Show an alert if application is active
        if UIApplication.sharedApplication().applicationState == .Active {
            // Then show an Alert Notification here
            let alertController = UIAlertController(title: "YAY!!", message: "You've reached your desination.", preferredStyle: .Alert)
            
            let okAction = UIAlertAction(title: "Okay", style: .Default) { (alert) -> Void in
                print("Okay button pressed")
                self.locationManager.startMonitoringForRegion(region)            }
            
            alertController.addAction(okAction)
            
            locationManager.stopMonitoringForRegion(region)
            
            self.presentViewController(alertController, animated: true, completion: nil)
        } else {
            // Otherwise present a Local Notification when app is closed
            let notification = UILocalNotification()
            notification.soundName = "Default"
            UIApplication.sharedApplication().presentLocalNotificationNow(notification)
        }
        
        
    }
    
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered Region!")
        if region is CLCircularRegion {
            handleRegionEvent(region)
        }
    }
    
    func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) {
        // Don't know if I need this.
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        // Be notified if the user changes location preference
        mapView.showsUserLocation = (status == .AuthorizedAlways)
        print("Authorized!")
        
        //print("Hey, you turned off your navigation for this app. That means you won't be able to make alarms")

    }
    
}

