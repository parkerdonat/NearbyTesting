//
//  AlarmController.swift
//  NearbyTesting
//
//  Created by Parker Donat on 5/11/16.
//  Copyright © 2016 Parker Donat. All rights reserved.
//

import Foundation
import CoreData

class AlarmController {
    
    private let kAlarmKey = "AlarmPin"
    
    static let sharedInstance = AlarmController()
    
    var fetchAlarmPins: [AlarmPin] {
        let error: NSErrorPointer = nil
        let request = NSFetchRequest(entityName: kAlarmKey)
        let results: [AnyObject]?
        do {
            results = try Stack.sharedStack.managedObjectContext.executeFetchRequest(request) as! [AlarmPin]
        } catch {
            results = nil
            return []
        }
        
        if error != nil {
            print("Error in getting alarmPins: \(error)")
        }
        return results as! [AlarmPin]
    }
    
    func addAlarm(alarm: AlarmPin) -> Void {
        saveToPersistentStorage()
    }
    
    func removePinAlarm(pin: AlarmPin) -> Void {
        Stack.sharedStack.managedObjectContext.deleteObject(pin)
        saveToPersistentStorage()
    }
    
    func updateAlarmTitle(alarmName: String, alarm: AlarmPin) {
        alarm.alarmName = alarmName
        saveToPersistentStorage()
    }
    
    func saveToPersistentStorage() {
        do {
            try Stack.sharedStack.managedObjectContext.save()
        } catch {
            print("Something went wrong with saving to core data.")
        }
    }
}