//
//  LocationController.swift
//  NearbyTesting
//
//  Created by Parker Donat on 3/22/16.
//  Copyright © 2016 Parker Donat. All rights reserved.
//

import UIKit
import CoreLocation


class LocationController: NSObject, CLLocationManagerDelegate {
    
    static let sharedInstance = LocationController()
    
    var locationManager: CLLocationManager!

    func setUpManager() {
     
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
    }

    func handleRegionEvent(region: CLRegion) {
        // Show an alert if application is active
        if UIApplication.sharedApplication().applicationState == .Active {
            // Then show an Alert Notification
        } else {
            // Otherwise present a Local Notification
            let notification = UILocalNotification()
            notification.soundName = "Default";
            UIApplication.sharedApplication().presentLocalNotificationNow(notification)
        }
    }
    
    // MARK: - CLLocationManager Delegate Methods
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        // Knows when passed geofence to call handleRegionEvent
        if region is CLCircularRegion {
            handleRegionEvent(region)
        }
    }
    
    func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) {
        // Calls the didEnterRegion that the state has changed. When it has changed, didEnterRegion will call the notification.
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Object that is being updated
    }
    
    func locationManager(manager: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
        // Begin monitoring region
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        // Be notified if the user changes location preference
        print("Hey, you turned off your navigation for this app. That means you won't be able to make alarms")
    }
    
    func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
        // Catch error for the region
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        // Catch error when unable to retrieve a location value
    }
    
    // MARK: -  Testing Boundaries
    
//    func containsCoordinate(coordinate: CLLocationCoordinate2D) -> Bool {
//        
//        return true
//    }
    
}