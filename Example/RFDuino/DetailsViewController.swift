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
        
        bluetoothLogo.setImageTintColor(color: UIColor.black)
        manager.setLoggingEnabled(enabled: true)
    }
}

extension DetailsViewController {
    
    @IBAction func connect(sender: UIButton) {
        statusLabel.text = "connecting".uppercased()
        manager.connectRFDuino(rfDuino: rfDuino!)
    }
    
    @IBAction func disconnect(sender: AnyObject) {
        statusLabel.text = "disconnecting".uppercased()
        if rfDuino!.isConnected {
            manager.disconnectRFDuino(rfDuino: rfDuino!)
        } else {
            statusLabel.text = (rfDuino?.name ?? "rfDuino") + " not connected..."
            statusLabel.delay(time: 1.0, closure: { () -> () in
                self.statusLabel.text = "idle".uppercased()
            })
        }
    }
    
    @IBAction func discoverServices(sender: AnyObject) {
        statusLabel.text = "discovering services".uppercased()
        if rfDuino!.isConnected {
            rfDuino!.discoverServices()
        }
    }
    
    @IBAction func sendData(sender: UIButton) {
        statusLabel.text = "sending data".uppercased()
        if rfDuino!.isConnected {
            rfDuino!.send(data: String("hello").data(using: String.Encoding.ascii)!)
        }
    }
}

extension DetailsViewController: RFDuinoBTManagerDelegate {
    func rfDuinoManagerDidDiscoverRFDuino(manager: RFDuinoBTManager, rfDuino: RFDuino) {
        
    }
    
    func rfDuinoManagerDidConnectRFDuino(manager: RFDuinoBTManager, rfDuino: RFDuino) {
        statusLabel.text = "idle".uppercased()
        bluetoothLogo.setImageTintColor(color: UIColor.green)
        connectButton.isEnabled = false
        disconnectButton.isEnabled = true
    }
}

extension DetailsViewController: RFDuinoDelegate {
    
    func rfDuinoDidDiscoverCharacteristics(rfDuino: RFDuino) {
        bluetoothLogo.setImageTintColor(color: bluetoothColor)
        statusLabel.text = "idle".uppercased()
        discoverButton.isEnabled = false
    }
    
    func rfDuinoDidDiscoverServices(rfDuino: RFDuino) {
        bluetoothLogo.setImageTintColor(color: UIColor.blue)
        statusLabel.text = "idle".uppercased()
    }
    
    func rfDuinoDidSendData(rfDuino: RFDuino, forCharacteristic: CBCharacteristic, error: Error?) {
        if isAnimating {
            return
        }
        isAnimating = true
        DispatchQueue.main.async {
            self.bluetoothLogo.layer.backgroundColor = UIColor.white.cgColor
            self.bluetoothLogo.layer.cornerRadius = self.bluetoothLogo.frame.size.width / 2
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                self.bluetoothLogo.layer.backgroundColor = self.bluetoothColor.withAlphaComponent(0.2).cgColor
            }) { (bool) -> Void in
                self.isAnimating = false
                self.bluetoothLogo.layer.backgroundColor = UIColor.white.cgColor
                self.statusLabel.text = "idle".uppercased()
            }
        }
    }
    
    func rfDuinoDidTimeout(rfDuino: RFDuino) {
        bluetoothLogo.setImageTintColor(color: UIColor.red)
        statusLabel.text = "idle".uppercased()
    }
    
    func rfDuinoDidDiscover(rfDuino: RFDuino) {
        bluetoothLogo.setImageTintColor(color: UIColor.black)
        statusLabel.text = "idle".uppercased()
    }
    
    func rfDuinoDidDisconnect(rfDuino: RFDuino) {
        connectButton.isEnabled = true
        disconnectButton.isEnabled = false
        discoverButton.isEnabled = true
        statusLabel.text = "idle".uppercased()
        bluetoothLogo.setImageTintColor(color: UIColor.black)
    }
    
    func rfDuinoDidReceiveData(rfDuino: RFDuino, data: Data?) {
        print("rfDuino did receive data")
    }
}

extension UIImageView {
    func setImageTintColor(color: UIColor) {
        let image = self.image?.withRenderingMode(.alwaysTemplate)
        self.image = image
        self.tintColor = color
    }
}

extension UILabel {
    func delay(time: Double, closure: @escaping ()->()) {
        let dt = DispatchTime(uptimeNanoseconds: UInt64(time))
        DispatchQueue.main.asyncAfter(deadline: dt, execute: closure)
    }
}
