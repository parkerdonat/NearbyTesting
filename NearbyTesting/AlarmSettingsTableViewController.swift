//
//  AlarmSettingsTableViewController.swift
//  NearbyTesting
//
//  Created by Parker Donat on 4/1/16.
//  Copyright © 2016 Parker Donat. All rights reserved.
//

import UIKit

class AlarmSettingsTableViewController: UITableViewController {

    @IBAction func saveButtonTapped(sender: AnyObject) {
        // Update Pin
        navigationController?.popViewControllerAnimated(true)
    }
    @IBAction func cancelButtonTapped(sender: AnyObject) {
        
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func deleteButtonTapped(sender: AnyObject) {
        // Delete Pin
        navigationController?.popViewControllerAnimated(true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
