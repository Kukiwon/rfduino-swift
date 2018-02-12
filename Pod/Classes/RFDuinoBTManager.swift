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

public extension RFDuinoBTManagerDelegate {
    func rfDuinoManagerDidDiscoverRFDuino(manager: RFDuinoBTManager, rfDuino: RFDuino){}
    func rfDuinoManagerDidConnectRFDuino(manager: RFDuinoBTManager, rfDuino: RFDuino){}
}

public struct RFDuinoUUIDS {
    public static var discoverUUID: String?
    public static var disconnectUUID: String?
    public static var receiveUUID: String?
    public static var sendUUID: String?
}

internal enum RFDuinoUUID: String {
    case Discover = "2220"
    case Disconnect = "2221"
    case Receive = "2222"
    case Send = "2223"
    
    var id: CBUUID {
        get {
            switch self {
                case .Discover: return CBUUID(string: RFDuinoUUIDS.discoverUUID ?? self.rawValue)
                case .Disconnect: return CBUUID(string: RFDuinoUUIDS.disconnectUUID ?? self.rawValue)
                case .Receive: return CBUUID(string: RFDuinoUUIDS.receiveUUID ?? self.rawValue)
                case .Send: return CBUUID(string: RFDuinoUUIDS.sendUUID ?? self.rawValue)
            }
        }
    }
}

public class RFDuinoBTManager : NSObject {
    /* Public variables */
    public static let sharedInstance = RFDuinoBTManager()
    public var delegate: RFDuinoBTManagerDelegate?
    
    /* Private variables */
    lazy fileprivate var centralManager:CBCentralManager = {
        let manager = CBCentralManager(delegate: RFDuinoBTManager.sharedInstance, queue: DispatchQueue.main)
        return manager
    }()
    fileprivate var reScanTimer: Timer?
    fileprivate static var reScanInterval = 3.0
    internal static var logging = false
    
    private var _discoveredRFDuinos: [RFDuino] = []
    public var discoveredRFDuinos: [RFDuino] = [] {
        didSet {
            if oldValue.count < discoveredRFDuinos.count {
                delegate?.rfDuinoManagerDidDiscoverRFDuino(manager: self, rfDuino: discoveredRFDuinos.last!)
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
    
    @objc func startScanningForRFDuinos() {
        "Started scanning for peripherals".log()
        centralManager.scanForPeripherals(withServices: [RFDuinoUUID.Discover.id], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    func stopScanningForRFDuinos() {
        discoveredRFDuinos = []
        "Stopped scanning for peripherals".log()
        centralManager.stopScan()
    }
    
    func connectRFDuino(rfDuino: RFDuino) {
        "Connecting to RFDuino".log()
        centralManager.connect(rfDuino.peripheral, options: nil)
    }
    
    func disconnectRFDuino(rfDuino: RFDuino) {
        "Disconnecting from RFDuino".log()
        rfDuino.sendDisconnectCommand { () -> () in
            DispatchQueue.main.async {
                self.centralManager.cancelPeripheralConnection(rfDuino.peripheral)
            }
        }
    }
    
    func disconnectRFDuinoWithoutSendCommand(rfDuino: RFDuino) {
        self.centralManager.cancelPeripheralConnection(rfDuino.peripheral)
    }
}

/* Internal methods */
extension RFDuinoBTManager {
    func reScan() {
        reScanTimer?.invalidate()
        reScanTimer = nil
        reScanTimer = Timer.scheduledTimer(timeInterval: RFDuinoBTManager.reScanInterval, target: self, selector: #selector(RFDuinoBTManager.startScanningForRFDuinos), userInfo: nil, repeats: true)
    }
}

extension RFDuinoBTManager : CBCentralManagerDelegate {
    
    /* Required delegate methods */
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff:
            "Bluetooth powered off".log()
        case .poweredOn:
            "Bluetooth powered on".log()
            startScanningForRFDuinos()
        case .resetting:
            "Bluetooth resetting".log()
        case.unauthorized:
            "Bluethooth unauthorized".log()
        case.unknown:
            "Bluetooth state unknown".log()
        case.unsupported:
            "Bluetooth unsupported".log()
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        "Did disconnect peripheral".log()
        if let rfDuino = discoveredRFDuinos.findRFDuino(peripheral: peripheral) {
            rfDuino.didDisconnect()
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        "Did discover peripheral with name: \(peripheral.name ?? "")".log()
        discoveredRFDuinos.insertIfNotContained(rfDuino: RFDuino(peripheral: peripheral))
        let rfDuino = discoveredRFDuinos.findRFDuino(peripheral: peripheral)
        rfDuino?.RSSI = RSSI
        reScan()
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        "Did fail to connect to peripheral".log()
    }
    
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        "Will restore state".log()
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        "Did connect peripheral".log()
        if let rfDuino = discoveredRFDuinos.findRFDuino(peripheral: peripheral) {
            rfDuino.didConnect()
            delegate?.rfDuinoManagerDidConnectRFDuino(manager: self, rfDuino: rfDuino)
        }
    }
}

extension String {
    func log() {
        if RFDuinoBTManager.logging {
            print(" 📲 " + self)
        }
    }
}
