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
}

internal enum RFDuinoUUID {
    case Discover
    case Disconnect
    case Receive
    case Send
    
    var id: CBUUID {
        get {
            switch self {
            case .Discover:
                return CBUUID(string: "2220")
            case .Receive:
                return CBUUID(string: "2221")
            case .Send:
                return CBUUID(string: "2222")
            case .Disconnect:
                return CBUUID(string: "2223")
            }
        }
    }
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
    private var reScanTimer: NSTimer?
    private static var reScanInterval = 3.0
    internal static var logging = false
    
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
public extension RFDuinoBTManager {
    
    func setLoggingEnabled(enabled: Bool) {
        RFDuinoBTManager.logging = enabled
    }
    
    func startScanningForRFDuinos() {
        "Started scanning for peripherals".log()
        centralManager.scanForPeripheralsWithServices([RFDuinoUUID.Discover.id], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    func stopScanningForRFDuinos() {
        discoveredRFDuinos = []
        "Stopped scanning for peripherals".log()
        centralManager.stopScan()
    }
    
    func connectRFDuino(rfDuino: RFDuino) {
        "Connecting to RFDuino".log()
        centralManager.connectPeripheral(rfDuino.peripheral, options: nil)
    }
    
    func disconnectRFDuino(rfDuino: RFDuino) {
        "Disconnecting from RFDuino".log()
        rfDuino.sendDisconnectCommand { () -> () in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.centralManager.cancelPeripheralConnection(rfDuino.peripheral)
            })
        }
    }
}

/* Internal methods */
extension RFDuinoBTManager {
    func reScan() {
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
            rfDuino.didDisconnect()
        }
    }
    
    @objc
    public func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        "Did discover peripheral with name: \(peripheral.name ?? "")".log()
        discoveredRFDuinos.insertIfNotContained(RFDuino(peripheral: peripheral))
        let rfDuino = discoveredRFDuinos.findRFDuino(peripheral)
        rfDuino?.RSSI = RSSI
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
        if RFDuinoBTManager.logging {
            print(" 📲 " + self)
        }
    }
}
