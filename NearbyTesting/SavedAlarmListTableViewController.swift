//
//  SavedAlarmListTableViewController.swift
//  NearbyTesting
//
//  Created by Parker Donat on 5/11/16.
//  Copyright © 2016 Parker Donat. All rights reserved.
//

import UIKit
import MapKit

class SavedAlarmListTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        tableView.reloadData()
    }
    
    @IBAction func cancelButtonTapped(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
        //(navigationController?.viewControllers.first as? MapViewController)
    }
    
    @IBAction func deleteAllPins(sender: AnyObject) {
        showAlertForDeleteAll()
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return AlarmController.sharedInstance.fetchAlarmPins.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("savedPinCell", forIndexPath: indexPath)
        
        let alarm = AlarmController.sharedInstance.fetchAlarmPins[indexPath.row]
        
        cell.textLabel?.text = alarm.alarmName
        
        return cell
    }
    
    func showAlertForDeleteAll() {
        // Then show an Alert Notification here
        let alertController = UIAlertController(title: "WARNING!", message: "You are about to delete all your alarms. This can't be undone. Are you sure you want to do that?", preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Destructive) { (alert) -> Void in
            print("Okay button pressed")
        }
        
        let deleteAllAction = UIAlertAction(title: "Delete All", style: .Default) { (alert) -> Void in
            print("Okay button pressed")
            AlarmController.sharedInstance.clearCoreData("AlarmPin")
            for region in MapViewController.sharedInstance.locationManager.monitoredRegions {
                print("Removed region \(region.identifier)")
                MapViewController.sharedInstance.locationManager.stopMonitoringForRegion(region)
            }
            self.tableView.reloadData()
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAllAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    // Override to support editing the table view.
//    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
//        if editingStyle == .Delete {
//            
//            let alarm = AlarmController.sharedInstance.fetchAlarmPins[indexPath.row]
//            AlarmController.sharedInstance.removePinAlarm(alarm)
//            
//            for region in MapViewController.sharedInstance.locationManager.monitoredRegions {
//                if let circularRegion = region as? CLCircularRegion {
//                    if circularRegion.identifier == alarm.alarmName {
//                        MapViewController.sharedInstance.locationManager.stopMonitoringForRegion(circularRegion)
//                    }
//                }
//            }
//            
//            // Delete the row from the data source
//            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
//        }
//    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "toPinOnMap" {
            guard let mapViewController = segue.destinationViewController as? MapViewController, cell = sender as? UITableViewCell, indexPath = tableView.indexPathForCell(cell) else { return }
            let mapPin = AlarmController.sharedInstance.fetchAlarmPins[indexPath.row]
            mapViewController.alarmPin = mapPin
        }
    }
}
