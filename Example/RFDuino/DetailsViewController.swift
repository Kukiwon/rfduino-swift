//
//  DetailsViewController.swift
//  RFDuino
//
//  Created by Jordy van Kuijk on 27/01/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import RFDuino

class DetailsViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var bluetoothLogo: UIImageView!
    
    var rfDuino: RFDuino?
    let manager = RFDuinoBTManager.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        rfDuino?.delegate = self
        manager.delegate = self
        titleLabel.text = rfDuino?.name
    }
}

extension DetailsViewController {
    
    @IBAction func connect(sender: UIButton) {
        statusLabel.text = "connecting".uppercaseString
        manager.connectRFDuino(rfDuino!)
    }
    
    @IBAction func disconnect(sender: AnyObject) {
        statusLabel.text = "disconnecting".uppercaseString
        if rfDuino!.isConnected {
            manager.disconnectRFDuino(rfDuino!)
        } else {
            statusLabel.text = (rfDuino?.name ?? "rfDuino") + " not connected..."
            statusLabel.delay(1.0, closure: { () -> () in
                self.statusLabel.text = "idle".uppercaseString
            })
        }
    }
    
    @IBAction func discoverServices(sender: AnyObject) {
        statusLabel.text = "discovering services".uppercaseString
    }
    
    @IBAction func sendData(sender: UIButton) {
        statusLabel.text = "sending data".uppercaseString
    }
}

extension DetailsViewController: RFDuinoBTManagerDelegate {
    func rfDuinoManagerDidDiscoverRFDuino(manager: RFDuinoBTManager, rfDuino: RFDuino) {
        
    }
    
    func rfDuinoManagerDidConnectRFDuino(manager: RFDuinoBTManager, rfDuino: RFDuino) {
        statusLabel.text = "idle".uppercaseString
        bluetoothLogo.setImageTintColor(UIColor.greenColor())
    }
    
    func rfDuinoManagerDidDisconnectRFDuino(manager: RFDuinoBTManager, rfDuino: RFDuino) {
        statusLabel.text = "idle".uppercaseString
        bluetoothLogo.setImageTintColor(UIColor.blackColor())
    }
}

extension DetailsViewController: RFDuinoDelegate {
    func rfDuinoDidTimeout(rfDuino: RFDuino) {
        bluetoothLogo.setImageTintColor(UIColor.orangeColor())
    }
    
    func rfDuinoDidDiscover(rfDuino: RFDuino) {
        bluetoothLogo.setImageTintColor(UIColor.blackColor())
    }
}

extension UIImageView {
    func setImageTintColor(color: UIColor) {
        let image = self.image?.imageWithRenderingMode(.AlwaysTemplate)
        self.image = image
        self.tintColor = color
    }
}

extension UILabel {
    func delay(time: Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(time * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
}
