//
//  HelperFunctions.swift
//  NearbyTesting
//
//  Created by Parker Donat on 3/23/16.
//  Copyright © 2016 Parker Donat. All rights reserved.
//

import UIKit
import MapKit

// MARK: Helper Functions

func showSimpleAlertWithTitle(title: String!, message: String, viewController: UIViewController) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
    let action = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
    alert.addAction(action)
    viewController.presentViewController(alert, animated: true, completion: nil)

}
