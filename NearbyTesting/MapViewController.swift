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
    let geoCoder = CLGeocoder()
    static let sharedInstance = MapViewController()
    
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
        
        for region in self.locationManager.monitoredRegions {
            print("Active region \(region.identifier)")
        }
        
        if alarmPin?.enabled == false {
            stopMonitoringAlarmPin(alarmPin)
        }
        
        if let alarmPin = alarmPin {
            annotationFromAlarmPinSettings(alarmPin)
        }
    }
    
    //MARK: - Drop a NEW PIN
    func tapGestureRecognizer(tapGestureRecognizer: UITapGestureRecognizer) {
        
        if self.locationManager.monitoredRegions.count == 20 {
            let alertController = UIAlertController(title: "So Sorry", message: "You've reached the limit of 20 saved alarms.", preferredStyle: .Alert)
            
            let enableAction = UIAlertAction(title: "Okay", style: .Default) { (alert) -> Void in
                print("Okay button pressed")
                if (self.mapView.annotations.last != nil) {
                    if let alarmPin = self.alarmPin {
                        self.stopMonitoringAlarmPin(alarmPin)
                    }
                }
                
                self.mapView.removeAnnotations(self.mapView.annotations)
                self.mapView.removeOverlays(self.mapView.overlays)
            }
            alertController.addAction(enableAction)
            self.presentViewController(alertController, animated: true, completion: nil)
            return
        }
        
        locationManager.requestAlwaysAuthorization()
        
        // Delete previous annotations so only one pin exists on the map at one time
        if (mapView.annotations.last != nil) {
            if let alarmPin = alarmPin {
            stopMonitoringAlarmPin(alarmPin)
            }
        }
        
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
        let touchPoint = tapGestureRecognizer.locationInView(self.mapView)
        let newCoordinate: CLLocationCoordinate2D = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        // Pin Annotation
        annotation.coordinate = newCoordinate
        mapView.addAnnotation(annotation)
        
        // Creates the span and animated zoomed into an area
        let span = MKCoordinateSpanMake(0.1, 0.1)
        let region = MKCoordinateRegion(center: newCoordinate, span: span)
        mapView.setRegion(region, animated: true)
        
        let location = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        geoCoder.reverseGeocodeLocation(location) { (placemarks, error) in
            let placeArray = placemarks as [CLPlacemark]!
            var placeMark: CLPlacemark!
            placeMark = placeArray?[0]
            
            if let street = placeMark.addressDictionary?["Thoroughfare"] as? String {
                self.annotation.title = street as String
                
                let fenceDistance: CLLocationDistance = 2000
                
                let identifier = NSUUID().UUIDString
                let alarm = AlarmPin(alarmName: self.annotation.title!, identifier: identifier, longitude: newCoordinate.longitude, latitude: newCoordinate.latitude, radius: fenceDistance)
                
                self.addAlarmPin(alarm)
                
                AlarmController.sharedInstance.addAlarm(alarm)
                self.alarmPin = alarm
                
                self.performSelector(#selector(self.selectAnnotation), withObject: self.annotation, afterDelay: 0.5)
            }
        }
    }
    
    @IBAction func clearMapOfAnnotations(sender: AnyObject) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
        for region in self.locationManager.monitoredRegions {
            print("Removed region \(region.identifier)")
            locationManager.stopMonitoringForRegion(region)
        }
    }
    
    @IBAction func centerMapOnUserButtonClicked(sender: AnyObject) {
        mapView.setUserTrackingMode(MKUserTrackingMode.Follow, animated: true)
    }
    
    // MARK: To update view with model
    
    func addAlarmPin(alarmPin: AlarmPin) {
        addRadiusOverlayForAlarmPin(alarmPin)
        startMonitoringAlarmPin(alarmPin)
        if alarmPin.enabled == false {
            stopMonitoringAlarmPin(alarmPin)
        }
    }
    
    func removeAlarmPin(alarmPin: AlarmPin) {
        removeRadiusOverlayForAlarmPin(alarmPin)
        stopMonitoringAlarmPin(alarmPin)
    }
    
    // Updates with saved pin
    func annotationFromAlarmPinSettings(alarmPin: AlarmPin) -> [MKAnnotation] {
        
        if alarmPin.alarmName == "" {
            mapView.removeAnnotations(mapView.annotations)
            mapView.removeOverlays(mapView.overlays)
            stopMonitoringAlarmPin(alarmPin)
            mapView.showsUserLocation = true
            return []
        }
        
        if alarmPin.enabled == false {
            if annotationCallout?.pinTintColor == nil {
                let loadSavedAnnotation = MKPinAnnotationView()
                loadSavedAnnotation.pinTintColor = UIColor.redColor()
                stopMonitoringAlarmPin(alarmPin)
            } else {
                annotationCallout.pinTintColor = UIColor.redColor()
                stopMonitoringAlarmPin(alarmPin)
            }
        } else {
            if annotationCallout?.pinTintColor == nil {
                if annotationCallout != nil  {
                    stopMonitoringAlarmPin(alarmPin)
                    return []
                }
                let loadSavedAnnotation = MKPinAnnotationView()
                loadSavedAnnotation.pinTintColor = UIColor(red:0.00, green:0.48, blue:0.00, alpha:1.0)
                startMonitoringAlarmPin(alarmPin)
            } else {
                annotationCallout.pinTintColor = UIColor(red:0.00, green:0.48, blue:0.00, alpha:1.0)
                startMonitoringAlarmPin(alarmPin)
            }
        }
        
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
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
        if annotation.title == "" {
            mapView.removeAnnotations(mapView.annotations)
            mapView.removeOverlays(mapView.overlays)
            stopMonitoringAlarmPin(alarmPin)
            mapView.showsUserLocation = true
        }
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        // Modify Circle attributes here
        
        if alarmPin?.enabled == false {
            if overlay is MKCircle {
                let circleRenderer = MKCircleRenderer(overlay: overlay)
                circleRenderer.lineWidth = 3.0
                circleRenderer.strokeColor = UIColor.redColor()
                circleRenderer.fillColor = UIColor.redColor().colorWithAlphaComponent(0.4)
                return circleRenderer
            }
        } else {
            if overlay is MKCircle {
                let circleRenderer = MKCircleRenderer(overlay: overlay)
                circleRenderer.lineWidth = 3.0
                circleRenderer.strokeColor = UIColor(red:0.00, green:0.48, blue:0.00, alpha:1.0)
                circleRenderer.fillColor = UIColor(red:0.00, green:0.48, blue:0.00, alpha:1.0).colorWithAlphaComponent(0.4)
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
        
        if alarmPin?.enabled == false {
            if annotationCallout == nil {
                annotationCallout = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
                annotationCallout!.rightCalloutAccessoryView = UIButton(type: UIButtonType.DetailDisclosure) as UIView
                annotationCallout!.canShowCallout = true
                annotationCallout!.animatesDrop = true
                annotationCallout!.pinTintColor = UIColor.redColor()
            }
        } else {
            if annotationCallout == nil {
                annotationCallout = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
                annotationCallout!.rightCalloutAccessoryView = UIButton(type: UIButtonType.DetailDisclosure) as UIView
                annotationCallout!.canShowCallout = true
                annotationCallout!.animatesDrop = true
                annotationCallout!.pinTintColor = UIColor(red:0.00, green:0.48, blue:0.00, alpha:1.0)
            }
        }
        return annotationCallout
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // Segue to editAlarm details
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
    }
    
    //MARK: - MapView Helper Functions
    
    // CL requires each geofence to be be represented as a CLCircularRegion before it can be registered for monitoring.
    func regionWithAlarmPin(alarmPin: AlarmPin) -> CLCircularRegion {
        
        // create the region to show with AlarmPin
        let coordinate = CLLocationCoordinate2D(latitude: alarmPin.latitude as Double, longitude: alarmPin.longitude as Double)
        
        let region = CLCircularRegion(center: coordinate, radius: Double(alarmPin.radius), identifier: alarmPin.identifier)
        region.notifyOnEntry = true
        print("The region identifier is \(region.identifier)")
        print("The model identifier is \(alarmPin.identifier)")
        return region
    }
    
    func startMonitoringAlarmPin(alarmPin: AlarmPin) {
        // Checks if device is available, checks authorization to be granted permission to use location services, and lastly at which region to begin monitoring
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
        let region = regionWithAlarmPin(alarmPin)
        locationManager.startMonitoringForRegion(region)
    }
    
    // Call when need to stop monitoring region
    func stopMonitoringAlarmPin(alarmPin: AlarmPin) {
        for region in locationManager.monitoredRegions {
            if let circularRegion = region as? CLCircularRegion {
                if circularRegion.identifier == alarmPin.identifier {
                    locationManager.stopMonitoringForRegion(circularRegion)
                    print("Stopped monitoring region for \(region.identifier)")
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
            if let alarmPin = alarmPin {
                
                let alertController = UIAlertController(title: "YAY!", message: "You're nearby \(alarmPin.alarmName).", preferredStyle: .Alert)
                
                let enableAction = UIAlertAction(title: "Re-enable", style: .Default) { (alert) -> Void in
                    print("Re-enable button pressed")
                    self.locationManager.startMonitoringForRegion(region)
                    self.alarmPin?.enabled = true
                    for annotation in self.mapView.annotations {
                        self.mapView.removeAnnotation(annotation)
                        self.mapView.addAnnotation(annotation)
                    }
                }
                let disableAction = UIAlertAction(title: "Disable", style: .Destructive) { (alert) -> Void in
                    print("Disable button pressed")
                    self.locationManager.stopMonitoringForRegion(region)
                    self.alarmPin?.enabled = false
                    for annotation in self.mapView.annotations {
                        self.mapView.removeAnnotation(annotation)
                        self.mapView.addAnnotation(annotation)
                    }
                }
                alertController.addAction(enableAction)
                alertController.addAction(disableAction)
                self.presentViewController(alertController, animated: true, completion: nil)
                //            locationManager.stopMonitoringForRegion(region)
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            }
            
        } else {
            // Otherwise present a Local Notification when app is closed
            let notification = UILocalNotification()
            notification.alertTitle = "Alarm Notification"
            notification.alertBody = "You're nearby \(alarmPin?.alarmName)."
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
    
    func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
        print("Monitoring failed for region with identifier: \(region!.identifier)")
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Settings don't allow tracking of the users location.")
        print("Location Manager failed with the following error: \(error)")
    }
    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "toSettings" {
            if alarmPin != nil {
                stopMonitoringAlarmPin(alarmPin)
            }
            
            guard let detailViewController = segue.destinationViewController as? AlarmSettingsTableViewController else { return }
            
            detailViewController.alarmPin = alarmPin
        }
        
        if segue.identifier == "toSavedPinsList" {
            if alarmPin != nil {
                stopMonitoringAlarmPin(alarmPin)
            }
        }
    }
}


extension MapViewController: HandleMapSearch {
    func dropPinZoomIn(placemark: MKPlacemark) {
        
        if self.locationManager.monitoredRegions.count == 20 {
            let alertController = UIAlertController(title: "So Sorry", message: "You've reached the limit of 20 saved alarms.", preferredStyle: .Alert)
            
            let enableAction = UIAlertAction(title: "Okay", style: .Default) { (alert) -> Void in
                print("Okay button pressed")
                if (self.mapView.annotations.last != nil) {
                    if let alarmPin = self.alarmPin {
                        self.stopMonitoringAlarmPin(alarmPin)
                    }
                }
                
                self.mapView.removeAnnotations(self.mapView.annotations)
                self.mapView.removeOverlays(self.mapView.overlays)
            }
            alertController.addAction(enableAction)
            self.presentViewController(alertController, animated: true, completion: nil)
            return
        }
        
        locationManager.requestAlwaysAuthorization()
        
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        mapView.addAnnotation(annotation)
        
        // Creates the span and animated zoomed into an area
        let span = MKCoordinateSpanMake(0.1, 0.1)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mapView.setRegion(region, animated: true)
        
        let fenceDistance: CLLocationDistance = 2000
        
        // Add an alarm pin
        let identifier = NSUUID().UUIDString
        let alarm = AlarmPin(alarmName: self.annotation.title!, identifier: identifier, longitude: placemark.coordinate.longitude, latitude: placemark.coordinate.latitude, radius: fenceDistance)
        
        addAlarmPin(alarm)
        
        AlarmController.sharedInstance.addAlarm(alarm)
        
        self.alarmPin = alarm
        
        self.performSelector(#selector(self.selectAnnotation), withObject: self.annotation, afterDelay: 0.5)
    }
}