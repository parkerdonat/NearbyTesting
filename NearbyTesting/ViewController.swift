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
import CoreData

protocol HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark)
}

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet var mapView: MKMapView!
    let annotation = MKPointAnnotation()
    var locationManager = CLLocationManager()
    var annotationCallout: MKPinAnnotationView!
    
    
    // Search
    var resultSearchController: UISearchController? = nil
    var selectedPin:MKPlacemark? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestLocation()
            locationManager.startUpdatingLocation()
        }
        
        self.mapView.delegate = self
        mapView.showsUserLocation = true
        // Aded from Kaelin
        //mapView.setUserTrackingMode(MKUserTrackingMode.Follow, animated: true)
        
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
        //let circleRenderer = MKCircleRenderer(overlay: circle)
    
        // Creates the span and animated zoomed into an area
        let span = MKCoordinateSpanMake(0.1, 0.1)
        let region = MKCoordinateRegion(center: newCoordinate, span: span)
        mapView.setRegion(region, animated: true)
        mapView.addOverlay(circle)
        
        // Add an alarm pin
        let alarm = AlarmPin(alarmName: "Hello", longitude: newCoordinate.longitude, latitude: newCoordinate.latitude, radius: fenceDistance)
       //let alarm = AlarmPin(coordinate: newCoordindate, radius: fenceDistance, identifier: "")
        let coordinate = CLLocationCoordinate2D(latitude: alarm.latitude as! Double, longitude: alarm.longitude as! Double)
        print(coordinate)
        addAlarmPin(alarm)
        startMonitoringAlarmPin(alarm)
        
    }
    
    
    @IBAction func centerMapOnUserButtonClicked(sender: AnyObject) {
        mapView.setUserTrackingMode(MKUserTrackingMode.Follow, animated: true)
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
        let coordinate = CLLocationCoordinate2D(latitude: alarmPin.latitude as! Double, longitude: alarmPin.longitude as! Double)

        mapView?.addOverlay(MKCircle(centerCoordinate: coordinate, radius: Double(alarmPin.radius!)))
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
        var view = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseID) as? MKPinAnnotationView
        
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            view!.rightCalloutAccessoryView = UIButton(type: UIButtonType.DetailDisclosure) as UIView
            view!.canShowCallout = true
            view!.animatesDrop = true
            view!.draggable = true
            view!.pinTintColor = UIColor.redColor()
            
            // Add detail button to right callout
            // let calloutButton = UIButton.init(type: .DetailDisclosure) as UIButton
            // annotationCallout.rightCalloutAccessoryView = calloutButton
            // //pinView?.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure) as UIView
            // //self.view.addSubview(calloutButton)
            
        }
        else {
            view!.annotation = annotation
            view!.canShowCallout = true
        }
        
        return view
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
    
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        geoCoder.reverseGeocodeLocation(location) { (placemarks, error) in
            let placeArray = placemarks as [CLPlacemark]!
            var placeMark: CLPlacemark!
            placeMark = placeArray?[0]
            
            // Street Address
            if let street = placeMark.addressDictionary?["Thoroughfare"] as? String {
                self.annotation.title = street as String
                print(street)
            }
            
            // City
            if let city = placeMark.addressDictionary?["City"] as? String {
                self.annotation.subtitle = city as String
            }
        }

        annotation.title = "Unknown Street"
        annotation.subtitle = "Unknown City"
        //mapView.addAnnotation(annotation)
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
        let coordinate = CLLocationCoordinate2D(latitude: alarmPin.latitude as! Double, longitude: alarmPin.longitude as! Double)

        let region = CLCircularRegion(center: coordinate, radius: Double(alarmPin.radius!), identifier: alarmPin.alarmName!)
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
                if circularRegion.identifier == alarmPin.alarmName! {
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
            notification.alertTitle = "Alarm Notification"
            notification.alertBody = "You are near your destination!"
            notification.soundName = UILocalNotificationDefaultSoundName
            UIApplication.sharedApplication().presentLocalNotificationNow(notification)
            
            locationManager.stopMonitoringForRegion(region)
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
        print("Something when wrong.")
    }
    
}


extension ViewController: HandleMapSearch {
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
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
            annotation.subtitle = "\(city), \(state)"
        }
        mapView.addAnnotation(annotation)
        
        // Create circle with the Pin
        let fenceDistance: CLLocationDistance = 3000
        let circle = MKCircle(centerCoordinate: placemark.coordinate, radius: fenceDistance)
        let circleRenderer = MKCircleRenderer(overlay: circle)
        circleRenderer.lineWidth = 3.0
        circleRenderer.strokeColor = UIColor.purpleColor()
        circleRenderer.fillColor = UIColor.purpleColor().colorWithAlphaComponent(0.4)
        
        // Creates the span and animated zoomed into an area
        let span = MKCoordinateSpanMake(0.1, 0.1)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mapView.setRegion(region, animated: true)
        mapView.addOverlay(circle)
        
        // Add an alarm pin
        let alarm = AlarmPin(alarmName: "Hello", longitude: placemark.coordinate.longitude, latitude: placemark.coordinate.latitude, radius: fenceDistance)

        //let alarm = AlarmPin(coordinate: placemark.coordinate, radius: fenceDistance, identifier: "")
        addAlarmPin(alarm)
        startMonitoringAlarmPin(alarm)
        
    }
    
    // MARK: - PinController - TO DO MAKE AN ALARM CONTROLLER
    
    func fetchAllPins() -> [AlarmPin] {
        
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "AlarmPin")
        // Execute the Fetch Request
        let results: [AnyObject]?
        do {
            results = try Stack.sharedStack.managedObjectContext.executeFetchRequest(fetchRequest)
        } catch {
            results = nil
        }
        // Check for Errors
        
        // Return the results, cast to an array of Pin objects
        return results as! [AlarmPin]
    }
}

/*
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
 */

