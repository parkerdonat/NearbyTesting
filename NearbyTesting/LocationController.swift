//
//  LocationController.swift
//  NearbyTesting
//
//  Created by Parker Donat on 3/22/16.
//  Copyright © 2016 Parker Donat. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

public let AlarmPinNotification = "alarmPinNotificationName"

class LocationController: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
    
    static let sharedInstance = LocationController()
    
    var locationManager: CLLocationManager?
    
    
    func setUpManager() {
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            locationManager?.requestAlwaysAuthorization()
        }
        if CLLocationManager.locationServicesEnabled() {
            if let locationManager = locationManager {
                //locationManager.delegate = self
//                if locationManager.respondsToSelector(#selector(CLLocationManager.requestAlwaysAuthorization)) {
//                    locationManager.requestAlwaysAuthorization()
//                } else {
                    locationManager.desiredAccuracy = kCLLocationAccuracyBest
                    locationManager.requestLocation()
                    locationManager.startUpdatingLocation()
//                }
            }
        }
    }
    
    // MARK: - CLLocationManager Delegate Methods
    
    func handleRegionEvent(region: CLRegion) {
        // Show an alert if application is active
        if UIApplication.sharedApplication().applicationState == .Active {
            // Then show an Alert Notification here
            let alertController = UIAlertController(title: "YAY!!", message: "You've reached your desination.", preferredStyle: .Alert)
            
            let okAction = UIAlertAction(title: "Okay", style: .Default) { (alert) -> Void in
                print("Okay button pressed")
                LocationController.sharedInstance.locationManager?.startMonitoringForRegion(region)            }
            
            alertController.addAction(okAction)
            
            locationManager?.stopMonitoringForRegion(region)
            
            // How do I present this alert view controller?
            let nc = NSNotificationCenter.defaultCenter()
            nc.postNotificationName(AlarmPinNotification, object: self)
            
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
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // Draws the map for the current location
        let location = locations.last
        let center = CLLocationCoordinate2D(latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        
        // How do I update the mapview here?
        //mapView.setRegion(region, animated: false)
        locationManager?.stopUpdatingLocation()
    }
    
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        // Be notified if the user changes location preference
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {

            manager.startUpdatingLocation()
            //self.setUpManager()
        }
    }
    
    
    func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) {
        // Don't know if I need this.
    }
    
    func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
        // Catch error for the region
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Something when wrong.")
    }
    
    
    // MARK: -  Testing Boundaries
    
    //    func containsCoordinate(coordinate: CLLocationCoordinate2D) -> Bool {
    //
    //        return true
    //    }
    
}