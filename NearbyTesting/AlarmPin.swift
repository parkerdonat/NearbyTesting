//
//  AlarmPin.swift
//  NearbyTesting
//
//  Created by Parker Donat on 3/23/16.
//  Copyright © 2016 Parker Donat. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Foundation
import CoreData

@objc(AlarmPin)
class AlarmPin: NSManagedObject, MKAnnotation {
    
    convenience init(alarmName: String, identifier: String, longitude: Double = 0.0, latitude: Double = 0.0, radius: Double = 0.0, context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("AlarmPin", inManagedObjectContext: context)!
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.alarmName = alarmName
        self.identifier = identifier
        self.enabled = true
        self.vibrate = true
        self.sound = true
        
        // Assign and convert our doubles into an NSNumber to enter into coreData
        self.latitude = NSNumber(double: latitude)
        self.longitude = NSNumber(double: longitude)
        self.radius = NSNumber(double: radius)
        
    }
    //returning the coordinate so as to conform to MKAnnotation protocol
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude as Double, longitude: longitude as Double)
    }
    
}


/*
 var coordinate: CLLocationCoordinate2D
 var radius: CLLocationDistance
 var identifier: String
 
 init(coordinate: CLLocationCoordinate2D, radius: CLLocationDistance, identifier: String) {
 self.coordinate = coordinate
 self.radius = radius
 self.identifier = identifier
 }
 
 @NSManaged var alarmName: String?
 @NSManaged var vibrate: NSNumber?
 @NSManaged var sound: NSNumber?
 @NSManaged var longitude: NSNumber?
 @NSManaged var latitude: NSNumber?
 @NSManaged var enabled: NSNumber?
 @NSManaged var radius: NSNumber?
 */