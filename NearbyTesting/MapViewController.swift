//
//  MapViewController.swift
//  NearbyTesting
//
//  Created by Parker Donat on 5/26/16.
//  Copyright © 2016 Parker Donat. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData
import AudioToolbox

protocol HandleMapSearch {
    func dropPinZoomIn(placemark: MKPlacemark)
}

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet var mapView: MKMapView!
    var annotation = MKPointAnnotation()
    var locationManager = CLLocationManager()
    var annotationCallout: MKPinAnnotationView!
    var alarmPin: AlarmPin!
    
    // Search
    var resultSearchController: UISearchController? = nil
    var selectedPin: MKPlacemark? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestLocation()
            locationManager.startUpdatingLocation()
            mapView!.showsUserLocation = true
        }
        
        self.mapView.delegate = self
        mapView.showsUserLocation = true
        
        let createAnnotation = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognizer))
        self.view.addGestureRecognizer(createAnnotation)
        
        // SearchBar Stuff
        let searchTableView = storyboard!.instantiateViewControllerWithIdentifier("SearchTableViewController") as! SearchTableViewController
        resultSearchController = UISearchController(searchResultsController: searchTableView)
        resultSearchController?.searchResultsUpdater = searchTableView
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search Address or Location"
        navigationItem.titleView = resultSearchController?.searchBar
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        searchTableView.mapView = mapView
        searchTableView.handleMapSearchDelegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)

        if (alarmPin != nil) {
            if let alarmPin = alarmPin {
            annotationFromAlarmPinSettings(alarmPin)
            }
        }
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
        
        // Pin Annotation
        annotation.coordinate = newCoordinate
        mapView.addAnnotation(annotation)
        
        // Create circle with the Pin
        let fenceDistance: CLLocationDistance = 3000
        let circle = MKCircle(centerCoordinate: newCoordinate, radius: fenceDistance)
        
        // Creates the span and animated zoomed into an area
        let span = MKCoordinateSpanMake(0.1, 0.1)
        let region = MKCoordinateRegion(center: newCoordinate, span: span)
        mapView.setRegion(region, animated: true)
        mapView.addOverlay(circle)
        
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        geoCoder.reverseGeocodeLocation(location) { (placemarks, error) in
            let placeArray = placemarks as [CLPlacemark]!
            var placeMark: CLPlacemark!
            placeMark = placeArray?[0]
            
            
            if let street = placeMark.addressDictionary?["Thoroughfare"] as? String {
                self.annotation.title = street as String
                print(street)
                
                let alarm = AlarmPin(alarmName: self.annotation.title!, longitude: newCoordinate.longitude, latitude: newCoordinate.latitude, radius: fenceDistance)

                self.addAlarmPin(alarm)
                
                AlarmController.sharedInstance.addAlarm(alarm)
                self.alarmPin = alarm
                
                self.performSelector(#selector(self.selectAnnotation), withObject: self.annotation, afterDelay: 0.5)
            }
        }

        
        // Add an alarm pin
//        let alarm = AlarmPin(alarmName: self.annotation.title!, longitude: newCoordinate.longitude, latitude: newCoordinate.latitude, radius: fenceDistance)
//        //let coordinate = CLLocationCoordinate2D(latitude: alarm.latitude as Double, longitude: alarm.longitude as Double)
//        addAlarmPin(alarm)
//        
//        AlarmController.sharedInstance.addAlarm(alarm)
//        alarmPin = alarm
    }
    
    
    @IBAction func centerMapOnUserButtonClicked(sender: AnyObject) {
        mapView.setUserTrackingMode(MKUserTrackingMode.Follow, animated: true)
    }
    
    // MARK: To update view with model
    
    func addAlarmPin(alarmPin: AlarmPin) {
        addRadiusOverlayForAlarmPin(alarmPin)
        if alarmPin.enabled == true {
            startMonitoringAlarmPin(alarmPin)
        }
    }
    
    func removeAlarmPin(alarmPin: AlarmPin) {
        removeRadiusOverlayForAlarmPin(alarmPin)
        stopMonitoringAlarmPin(alarmPin)
    }
    
    // Updates with saved pin
    func annotationFromAlarmPinSettings(alarmPin: AlarmPin) -> [MKAnnotation] {
        
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
        //let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: Double(alarmPin.latitude), longitude: Double(alarmPin.longitude))
        mapView.addAnnotation(annotation)
        
        // Create circle with the Saved Pin
        let fenceDistance: CLLocationDistance = Double(alarmPin.radius)
        let circle = MKCircle(centerCoordinate: annotation.coordinate, radius: fenceDistance)
        
        // Creates the span and animated zoomed into an area
        let span = MKCoordinateSpanMake(0.1, 0.1)
        let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
        mapView.setRegion(region, animated: true)
        mapView.addOverlay(circle)
        
        self.annotation.title = alarmPin.alarmName
        
        return mapView.annotations
    }
    
    
    // MARK: - Overlay Functions
    
    func addRadiusOverlayForAlarmPin(alarmPin: AlarmPin) {
        // add mapView with MKCircle coordinate and radius
        let coordinate = CLLocationCoordinate2D(latitude: alarmPin.latitude as Double, longitude: alarmPin.longitude as Double)
        
        mapView?.addOverlay(MKCircle(centerCoordinate: coordinate, radius: Double(alarmPin.radius)))
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
    
    func mapViewDidFinishLoadingMap(mapView: MKMapView) {
        for currentAnnotation in mapView.annotations {
            if currentAnnotation.isEqual(self.alarmPin) {
                mapView.selectAnnotation(currentAnnotation, animated: true)
            }
        }
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        // Modify Circle attributes here
        
        if alarmPin?.enabled == true {
            if overlay is MKCircle {
                let circleRenderer = MKCircleRenderer(overlay: overlay)
                circleRenderer.lineWidth = 3.0
                circleRenderer.strokeColor = UIColor(red:0.00, green:0.48, blue:0.00, alpha:1.0)
                circleRenderer.fillColor = UIColor(red:0.00, green:0.48, blue:0.00, alpha:1.0).colorWithAlphaComponent(0.4)
                return circleRenderer
            }
        } else {
            if overlay is MKCircle {
                let circleRenderer = MKCircleRenderer(overlay: overlay)
                circleRenderer.lineWidth = 3.0
                circleRenderer.strokeColor = UIColor.redColor()
                circleRenderer.fillColor = UIColor.redColor().colorWithAlphaComponent(0.4)
                return circleRenderer
            }
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
        annotationCallout = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseID) as? MKPinAnnotationView
                
        if alarmPin?.enabled == true {
            if annotationCallout == nil {
                annotationCallout = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
                annotationCallout!.rightCalloutAccessoryView = UIButton(type: UIButtonType.DetailDisclosure) as UIView
                annotationCallout!.canShowCallout = true
                annotationCallout!.animatesDrop = true
                annotationCallout!.pinTintColor = UIColor(red:0.00, green:0.48, blue:0.00, alpha:1.0)
            }
        } else {
            if annotationCallout == nil {
                annotationCallout = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
                annotationCallout!.rightCalloutAccessoryView = UIButton(type: UIButtonType.DetailDisclosure) as UIView
                annotationCallout!.canShowCallout = true
                annotationCallout!.animatesDrop = true
                annotationCallout!.pinTintColor = UIColor.redColor()
            }
        }
        
        return annotationCallout
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // Segue to editAlarm details
        print("Callout was tapped!")
        
        if control == view.rightCalloutAccessoryView {
            performSegueWithIdentifier("toSettings", sender: view)
        }
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        // Use if I want to drag the pin
    }
    
    // Shows the callout with delay
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        
        // TODO - UPDATE MODEL'S ALARM NAME WITH ANNOTATION TITLE
        guard let pin = self.alarmPin, annotationTitle = self.annotation.title else { return }
        AlarmController.sharedInstance.updateAlarmTitle(annotationTitle, alarm: pin)
        self.performSelector(#selector(self.selectAnnotation), withObject: self.annotation, afterDelay: 0.5)
    }

    // Shows the callout with delay
    func selectAnnotation(annotation: MKAnnotation) {
        mapView.selectAnnotation(annotation, animated: true)
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        print("Tapped \(annotation.title)")
        self.performSelector(#selector(self.selectAnnotation), withObject: self.annotation, afterDelay: 0.5)
    }
    
    //MARK: - MapView Helper Functions
    
    // CL requires each geofence to be be represented as a CLCircularRegion before it can be registered for monitoring.
    func regionWithAlarmPin(alarmPin: AlarmPin) -> CLCircularRegion {
        
        // create the region to show with AlarmPin
        let coordinate = CLLocationCoordinate2D(latitude: alarmPin.latitude as Double, longitude: alarmPin.longitude as Double)
        
        let region = CLCircularRegion(center: coordinate, radius: Double(alarmPin.radius), identifier: alarmPin.alarmName)
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
                print("Okay button pressed")
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
                print("Okay button pressed")
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
                if circularRegion.identifier == alarmPin.alarmName {
                    locationManager.stopMonitoringForRegion(circularRegion)
                }
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Show user's location on map as blue dot
        mapView.showsUserLocation = true
        
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
            let alertController = UIAlertController(title: "YAY!!", message: "You're nearby your destination!", preferredStyle: .Alert)
            
            let okAction = UIAlertAction(title: "Okay", style: .Default) { (alert) -> Void in
                print("Okay button pressed")
                self.locationManager.startMonitoringForRegion(region)            }
            
            alertController.addAction(okAction)
            
            locationManager.stopMonitoringForRegion(region)
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        } else {
            // Otherwise present a Local Notification when app is closed
            let notification = UILocalNotification()
            notification.alertTitle = "Alarm Notification"
            notification.alertBody = "You're nearby your destination!"
            notification.soundName = UILocalNotificationDefaultSoundName
            UIApplication.sharedApplication().presentLocalNotificationNow(notification)
            
            locationManager.stopMonitoringForRegion(region)
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
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
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Settings don't allow tracking of the users location.")
    }
    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "toSettings" {
            
            guard let detailViewController = segue.destinationViewController as? AlarmSettingsTableViewController else { return }
            
            detailViewController.alarmPin = alarmPin
        }
    }
    
    override func motionBegan(motion: UIEventSubtype, withEvent event: UIEvent?) {
        
        if (motion == .MotionShake) {
            print("iPhone Shake Detected")
        }
    }
}


extension MapViewController: HandleMapSearch {
    func dropPinZoomIn(placemark: MKPlacemark) {
        // clear existing pins
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
        //        // cache the pin
        //        selectedPin = placemark
        
        //let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        // annotation.title = "New Pin"
        // annotation.subtitle = "Sweet Annotation Bruh!"
        
        //        if let city = placemark.locality,
        //            let state = placemark.administrativeArea {
        //            annotation.subtitle = "\(city), \(state)"
        //        }
        mapView.addAnnotation(annotation)
        
        // Create circle with the Pin
        let fenceDistance: CLLocationDistance = 3000
        let circle = MKCircle(centerCoordinate: placemark.coordinate, radius: fenceDistance)
        
        // Creates the span and animated zoomed into an area
        let span = MKCoordinateSpanMake(0.1, 0.1)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mapView.setRegion(region, animated: true)
        mapView.addOverlay(circle)
        
        // Add an alarm pin
        let alarm = AlarmPin(alarmName: annotation.title!, longitude: placemark.coordinate.longitude, latitude: placemark.coordinate.latitude, radius: fenceDistance)
        
        //let alarm = AlarmPin(coordinate: placemark.coordinate, radius: fenceDistance, identifier: "")
        addAlarmPin(alarm)
        
        if alarmPin?.enabled == true {
            startMonitoringAlarmPin(alarm)
        } else {
            if let alarmPined = alarmPin {
                stopMonitoringAlarmPin(alarmPined)
            }
        }
        
        AlarmController.sharedInstance.addAlarm(alarm)
    }
}
