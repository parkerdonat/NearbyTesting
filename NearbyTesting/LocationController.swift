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
    
    var manager: CLLocationManager!
    
    func setUpManager() {
     
        manager.delegate = self
        manager.requestAlwaysAuthorization()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
        
    }

    
    func handleRegionEvent(region: CLRegion) {
        // Show an alert if application is active
        if UIApplication.sharedApplication().applicationState == .Active {
            // Show Alert Notification
        } else {
            // Otherwise present a local notification
            let notification = UILocalNotification()
            notification.soundName = "Default";
            UIApplication.sharedApplication().presentLocalNotificationNow(notification)
        }
    }
    
    @objc func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        // Use to know when passed geofence
        if region is CLCircularRegion {
            handleRegionEvent(region)
        }
    }
    
    // MARK: - CLLocationManager Delegate Methods
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Object that is being updated
    }
    
    func locationManager(manager: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
        // Begin monitoring region
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        // Be notified if the user changes location preference
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