//
//  AlarmSettingsTableViewController.swift
//  NearbyTesting
//
//  Created by Parker Donat on 4/1/16.
//  Copyright © 2016 Parker Donat. All rights reserved.
//

import UIKit
import MediaPlayer

class AlarmSettingsTableViewController: UITableViewController, UITextFieldDelegate, MPMediaPickerControllerDelegate {
    
    var alarmPin: AlarmPin?
    
    @IBOutlet weak var alarmNameTextField: UITextField!
    @IBOutlet var switchEnabled: UISwitch!
    @IBOutlet var switchVibrate: UISwitch!
    @IBOutlet var setMusicCell: UITableViewCell!

    
    @IBAction func saveButtonTapped(sender: AnyObject) {
        // Update Pin
        let alarm = updateAlarm()
        navigationController?.popViewControllerAnimated(true)
        (navigationController?.viewControllers.first as? MapViewController)?.annotationFromAlarmPinSettings(alarm)
    }
    
    @IBAction func cancelButtonTapped(sender: AnyObject) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func deleteButtonTapped(sender: AnyObject) {
        // Delete Pin
        guard let alarmPin = alarmPin else { return }
            AlarmController.sharedInstance.removePinAlarm(alarmPin)
            navigationController?.popViewControllerAnimated(true)
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
            return alarmPin
        } else {
            let newAlarmPin = AlarmPin(alarmName: alarmName)
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
            mediaPicker.allowsPickingMultipleItems = false
            presentViewController(mediaPicker, animated: true, completion: {})
        }
    }
    
    func mediaPicker(mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        
        self.dismissViewControllerAnimated(true, completion: {});
    }
    
    func mediaPickerDidCancel(mediaPicker: MPMediaPickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
