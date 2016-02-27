//
//  DetailsViewController.swift
//  RFDuino
//
//  Created by Jordy van Kuijk on 27/01/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import RFDuino
import CoreBluetooth

class DetailsViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var bluetoothLogo: UIImageView!
    
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var discoverButton: UIButton!
    @IBOutlet weak var sendDataButton: UIButton!
    
    var rfDuino: RFDuino?
    var isAnimating = false
    let manager = RFDuinoBTManager.sharedInstance
    
    let bluetoothColor = UIColor(red: 0.04, green: 0.24, blue: 0.57, alpha: 1.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        rfDuino?.delegate = self
        manager.delegate = self
        titleLabel.text = rfDuino?.name
        
        bluetoothLogo.setImageTintColor(UIColor.blackColor())
        manager.setLoggingEnabled(true)
        
        navigationItem.title = "RBL Nano devive"
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
            manager.disconnectRFDuinoWithoutSendCommand(rfDuino!)
        } else {
            statusLabel.text = (rfDuino?.name ?? "rfDuino") + " not connected..."
            statusLabel.delay(1.0, closure: { () -> () in
                self.statusLabel.text = "idle".uppercaseString
            })
        }
    }
    
    @IBAction func discoverServices(sender: AnyObject) {
        statusLabel.text = "discovering services".uppercaseString
        if rfDuino!.isConnected {
            rfDuino!.discoverServices()
        }
    }
    
    @IBAction func sendData(sender: UIButton) {
        statusLabel.text = "sending data".uppercaseString
        if rfDuino!.isConnected {
            rfDuino!.send(String("hello").dataUsingEncoding(NSASCIIStringEncoding)!)
        }
    }
}

extension DetailsViewController: RFDuinoBTManagerDelegate {
    func rfDuinoManagerDidDiscoverRFDuino(manager: RFDuinoBTManager, rfDuino: RFDuino) {
        
    }
    
    func rfDuinoManagerDidConnectRFDuino(manager: RFDuinoBTManager, rfDuino: RFDuino) {
        statusLabel.text = "idle".uppercaseString
        bluetoothLogo.setImageTintColor(UIColor.greenColor())
        connectButton.enabled = false
        disconnectButton.enabled = true
    }
}

extension DetailsViewController: RFDuinoDelegate {
    
    func rfDuinoDidDiscoverCharacteristics(rfDuino: RFDuino) {
        bluetoothLogo.setImageTintColor(bluetoothColor)
        statusLabel.text = "idle".uppercaseString
        discoverButton.enabled = false
    }
    
    func rfDuinoDidDiscoverServices(rfDuino: RFDuino) {
        bluetoothLogo.setImageTintColor(UIColor.blueColor())
        statusLabel.text = "idle".uppercaseString
    }
    
    func rfDuinoDidSendData(rfDuino: RFDuino, forCharacteristic: CBCharacteristic, error: NSError?) {
        if isAnimating {
            return
        }
        isAnimating = true
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.bluetoothLogo.layer.backgroundColor = UIColor.whiteColor().CGColor
            self.bluetoothLogo.layer.cornerRadius = self.bluetoothLogo.frame.size.width / 2
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                self.bluetoothLogo.layer.backgroundColor = self.bluetoothColor.colorWithAlphaComponent(0.2).CGColor
                }) { (bool) -> Void in
                self.isAnimating = false
                self.bluetoothLogo.layer.backgroundColor = UIColor.whiteColor().CGColor
                self.statusLabel.text = "idle".uppercaseString
            }
        }
    }
    
    func rfDuinoDidTimeout(rfDuino: RFDuino) {
        bluetoothLogo.setImageTintColor(UIColor.redColor())
        statusLabel.text = "idle".uppercaseString
    }
    
    func rfDuinoDidDiscover(rfDuino: RFDuino) {
        bluetoothLogo.setImageTintColor(UIColor.blackColor())
        statusLabel.text = "idle".uppercaseString
    }
    
    func rfDuinoDidDisconnect(rfDuino: RFDuino) {
        connectButton.enabled = true
        disconnectButton.enabled = false
        discoverButton.enabled = true
        statusLabel.text = "idle".uppercaseString
        bluetoothLogo.setImageTintColor(UIColor.blackColor())
    }
    
    func rfDuinoDidReceiveData(rfDuino: RFDuino, data: NSData?) {
        print("rfDuino did receive data")
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
