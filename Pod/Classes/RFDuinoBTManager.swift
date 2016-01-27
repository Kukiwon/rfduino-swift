//
//  RFDuinoBTManager.swift
//  Pods
//
//  Created by Jordy van Kuijk on 27/01/16.
//
//

import Foundation
import CoreBluetooth

public protocol RFDuinoBTManagerDelegate {
    func rfDuinoManagerDidDiscoverRFDuino(manager: RFDuinoBTManager, rfDuino: RFDuino)
    func rfDuinoManagerDidConnectRFDuino(manager: RFDuinoBTManager, rfDuino: RFDuino)
    func rfDuinoManagerDidDisconnectRFDuino(manager: RFDuinoBTManager, rfDuino: RFDuino)
}

public class RFDuinoBTManager : NSObject {
    
    /* Public variables */
    public static let sharedInstance = RFDuinoBTManager()
    public var delegate: RFDuinoBTManagerDelegate?
    
    
    /* Private variables */
    lazy private var centralManager:CBCentralManager = {
        let manager = CBCentralManager(delegate: sharedInstance, queue: dispatch_get_main_queue())
        return manager
    }()
    private let serviceUUID: CBUUID = CBUUID(string: "2220")
    private var reScanTimer: NSTimer?
    private static var reScanInterval = 3.0
    
    private var _discoveredRFDuinos: [RFDuino] = []
    public var discoveredRFDuinos: [RFDuino] = [] {
        didSet {
            if oldValue.count != discoveredRFDuinos.count {
                delegate?.rfDuinoManagerDidDiscoverRFDuino(self, rfDuino: discoveredRFDuinos.last!)
            }
        }
    }
    
    override init() {
        super.init()
        "initialized RFDuinoBTRManager".log()
    }
}

/* Public methods */
extension RFDuinoBTManager {
    public func startScanningForRFDuinos() {
        "Started scanning for peripherals".log()
        centralManager.scanForPeripheralsWithServices([serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    public func stopScanningForRFDuinos() {
        discoveredRFDuinos = []
        "Stopped scanning for peripherals".log()
        centralManager.stopScan()
    }
    
    public func connectRFDuino(rfDuino: RFDuino) {
        "Connecting to RFDuino".log()
        centralManager.connectPeripheral(rfDuino.peripheral, options: nil)
    }
    
    public func disconnectRFDuino(rfDuino: RFDuino) {
        "Disconnecting from RFDuino".log()
        centralManager.cancelPeripheralConnection(rfDuino.peripheral)
    }
}

/* Internal methods */
extension RFDuinoBTManager {
    internal func reScan() {
        reScanTimer?.invalidate()
        reScanTimer = nil
        reScanTimer = NSTimer.scheduledTimerWithTimeInterval(RFDuinoBTManager.reScanInterval, target: self, selector: Selector("startScanningForRFDuinos"), userInfo: nil, repeats: true)
    }
}

extension RFDuinoBTManager : CBCentralManagerDelegate {
    
    /* Required delegate methods */
    @objc
    public func centralManagerDidUpdateState(central: CBCentralManager) {
        switch central.state {
        case .PoweredOff:
            "Bluetooth powered off".log()
        case .PoweredOn:
            "Bluetooth powered on".log()
            startScanningForRFDuinos()
        case .Resetting:
            "Bluetooth resetting".log()
        case.Unauthorized:
            "Bluethooth unauthorized".log()
        case.Unknown:
            "Bluetooth state unknown".log()
        case.Unsupported:
            "Bluetooth unsupported".log()
        }
    }
    
    /* Optional delegate methods */
    @objc
    public func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        "Did connect peripheral".log()
        if let rfDuino = discoveredRFDuinos.findRFDuino(peripheral) {
            rfDuino.didConnect()
            delegate?.rfDuinoManagerDidConnectRFDuino(self, rfDuino: rfDuino)
        }
    }
    
    @objc
    public func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        "Did disconnect peripheral".log()
        if let rfDuino = discoveredRFDuinos.findRFDuino(peripheral) {
            rfDuino.isConnected = false
            delegate?.rfDuinoManagerDidDisconnectRFDuino(self, rfDuino: rfDuino)
        }
    }
    
    @objc
    public func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        "Did discover peripheral with name: \(peripheral.name ?? "")".log()
        discoveredRFDuinos.insertIfNotContained(RFDuino(peripheral: peripheral))
        reScan()
    }
    
    @objc
    public func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        "Did fail to connect to peripheral".log()
    }
    
    @objc
    public func centralManager(central: CBCentralManager, willRestoreState dict: [String : AnyObject]) {
        "Will restore state".log()
    }
}

extension String {
    func log() {
        print(" 📲 " + self)
    }
}
