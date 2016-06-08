//
//  AlarmPin+CoreDataProperties.swift
//  NearbyTesting
//
//  Created by Parker Donat on 4/5/16.
//  Copyright © 2016 Parker Donat. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension AlarmPin {

    @NSManaged var alarmName: String
    @NSManaged var vibrate: NSNumber
    @NSManaged var sound: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var latitude: NSNumber
    @NSManaged var enabled: NSNumber
    @NSManaged var radius: NSNumber

}
