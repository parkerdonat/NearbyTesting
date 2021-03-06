//
//  AlarmSettingsTableViewController.swift
//  NearbyTesting
//
//  Created by Parker Donat on 4/1/16.
//  Copyright © 2016 Parker Donat. All rights reserved.
//

import UIKit
import MapKit
import MediaPlayer

class AlarmSettingsTableViewController: UITableViewController, UITextFieldDelegate, MPMediaPickerControllerDelegate {
    
    var alarmPin: AlarmPin?
    
    @IBOutlet weak var alarmNameTextField: UITextField!
    @IBOutlet var switchEnabled: UISwitch!
    @IBOutlet var switchVibrate: UISwitch!
    @IBOutlet var setMusicCell: UITableViewCell!
    
    static let sharedInstance = AlarmSettingsTableViewController()
    
    @IBAction func saveButtonTapped(sender: AnyObject) {
        //Check if textField is nil 
        if alarmNameTextField.text == "" {
            let alertController = UIAlertController(title: "Empty Alarm Name", message: "Your alarm must have an name to save.", preferredStyle: .Alert)
            
            let okAction = UIAlertAction(title: "Okay", style: .Default) { (alert) -> Void in
                print("Okay button pressed")
            }
            
            alertController.addAction(okAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        
        // Update Pin
        let alarm = updateAlarm()
        navigationController?.popViewControllerAnimated(true)
        (navigationController?.viewControllers.first as? MapViewController)?.annotationFromAlarmPinSettings(alarm)
    }
    
    @IBAction func cancelButtonTapped(sender: AnyObject) {
        let alarm = updateAlarm()
        navigationController?.popViewControllerAnimated(true)
        (navigationController?.viewControllers.first as? MapViewController)?.annotationFromAlarmPinSettings(alarm)
    }
    
    @IBAction func deleteButtonTapped(sender: AnyObject) {
        // Delete Pin
        guard let alarmPin = alarmPin else { return }
        AlarmController.sharedInstance.removePinAlarm(alarmPin)
        
        for region in MapViewController.sharedInstance.locationManager.monitoredRegions {
            if let circularRegion = region as? CLCircularRegion {
                if circularRegion.identifier == alarmPin.alarmName {
                    print("Going to remove region \(region.identifier)")
                    MapViewController.sharedInstance.locationManager.stopMonitoringForRegion(circularRegion)
                }
            }
        }
        
        navigationController?.popViewControllerAnimated(true)
        (navigationController?.viewControllers.first as? MapViewController)?.annotationFromAlarmPinSettings(alarmPin)
    }
    
    @IBAction func enableSwitchTapped(sender: AnyObject) {
        print("Enable Switch tapped")
    }
    
    @IBAction func vibrateSwitchTapped(sender: AnyObject) {
        print("Vibrate Switch tapped")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        alarmNameTextField.delegate = self
        
        if let alarm = alarmPin {
            updateViewWithAlarm(alarm)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func updateAlarm() -> AlarmPin {
        let alarmName = alarmNameTextField.text!
        let enabled = switchEnabled.on
        let vibrate = switchVibrate.on
        
        if let alarmPin = alarmPin {
            alarmPin.alarmName = alarmName
            alarmPin.enabled = enabled
            alarmPin.vibrate = vibrate
            alarmPin.identifier = alarmPin.alarmName
            return alarmPin
        } else {
            let newAlarmPin = AlarmPin(alarmName: alarmName, identifier: alarmName)
            AlarmController.sharedInstance.addAlarm(newAlarmPin)
            return newAlarmPin
        }
    }
    
    func updateViewWithAlarm(alarmPin: AlarmPin) {
        self.alarmPin = alarmPin
        
        alarmNameTextField.text = alarmPin.alarmName
        
        let enabled = alarmPin.enabled as Bool
        switchEnabled.on = enabled
        
        let vibrate = alarmPin.vibrate as Bool
        switchVibrate.on = vibrate
    }
    
    
    @IBAction func userTappedView(sender: AnyObject) {
        alarmNameTextField.resignFirstResponder()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        if (cell == setMusicCell) {
            
            let mediaPicker = MPMediaPickerController(mediaTypes: .Music)
            mediaPicker.delegate = self
            mediaPicker.prompt = "Select a song from your music"
            mediaPicker.showsCloudItems = false
            mediaPicker.allowsPickingMultipleItems = false
            presentViewController(mediaPicker, animated: true, completion: {})
        }
    }
    
    func mediaPicker(mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        //Get [MPMediaItem]
        let items = mediaItemCollection.items
        //Iterate on each MPMediaItem
        for item in items {
            //Retrieve persistent ID
            let persistentID = item.valueForProperty(MPMediaItemPropertyPersistentID) as! NSNumber
            //Use the persistent ID as you like.
            print(persistentID.unsignedLongLongValue)
        }
        self.dismissViewControllerAnimated(true, completion: {})
    }
    
    func mediaPickerDidCancel(mediaPicker: MPMediaPickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
