//
//  AlarmPin+CoreDataProperties.swift
//  NearbyTesting
//
//  Created by Parker Donat on 6/15/16.
//  Copyright © 2016 Parker Donat. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension AlarmPin {

    @NSManaged var longitude: NSNumber
    @NSManaged var latitude: NSNumber
    @NSManaged var radius: NSNumber
    @NSManaged var sound: NSNumber
    @NSManaged var vibrate: NSNumber
    @NSManaged var enabled: NSNumber
    @NSManaged var identifier: String
    @NSManaged var alarmName: String

}
