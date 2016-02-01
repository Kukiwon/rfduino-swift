//
//  RFDuino.swift
//  Pods
//
//  Created by Jordy van Kuijk on 27/01/16.
//
//

import Foundation
import CoreBluetooth

@objc public protocol RFDuinoDelegate {
    func rfDuinoDidTimeout(rfDuino: RFDuino)
    func rfDuinoDidDisconnect(rfDuino: RFDuino)
    func rfDuinoDidDiscover(rfDuino: RFDuino)
    func rfDuinoDidDiscoverServices(rfDuino: RFDuino)
    func rfDuinoDidDiscoverCharacteristics(rfDuino: RFDuino)
    func rfDuinoDidSendData(rfDuino: RFDuino, forCharacteristic: CBCharacteristic, error: NSError?)
}

public class RFDuino: NSObject {
    
    public var isTimedOut = false
    public var isConnected = false
    public var didDiscoverCharacteristics = false
    
    public var delegate: RFDuinoDelegate?
    public static let timeoutThreshold = 5.0
    public var RSSI: NSNumber?
    
    var whenDoneBlock: (() -> ())?
    var peripheral: CBPeripheral
    var timeoutTimer: NSTimer?
    
    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        super.init()
        self.peripheral.delegate = self
    }
}

/* Internal methods */
internal extension RFDuino {
    func confirmAndTimeout() {
        isTimedOut = false
        delegate?.rfDuinoDidDiscover(self)
        
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        timeoutTimer = NSTimer.scheduledTimerWithTimeInterval(RFDuino.timeoutThreshold, target: self, selector: Selector("didTimeout"), userInfo: nil, repeats: false)
    }
    
    func didTimeout() {
        isTimedOut = true
        isConnected = false
        delegate?.rfDuinoDidTimeout(self)
    }
    
    func didConnect() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        
        isConnected  = true
        isTimedOut = false
    }
    
    func didDisconnect() {
        isConnected = false
        confirmAndTimeout()
        delegate?.rfDuinoDidDisconnect(self)
    }
    
    func findCharacteristic(characteristicUUID characteristicUUID: RFDuinoUUID, forServiceWithUUID serviceUUID: RFDuinoUUID) -> CBCharacteristic? {
        if let discoveredServices = peripheral.services,
            let service = (discoveredServices.filter { return $0.UUID == serviceUUID.id }).first,
            let characteristics = service.characteristics {
            return (characteristics.filter { return $0.UUID ==  characteristicUUID.id}).first
        }
        return nil
    }
}

/* Public methods */
public extension RFDuino {
    func discoverServices() {
        "Going to discover services for peripheral".log()
        peripheral.discoverServices([RFDuinoUUID.Discover.id])
    }
    
    func sendDisconnectCommand(whenDone: () -> ()) {
        self.whenDoneBlock = whenDone
        // if no services were discoverd, imediately invoke done block
        if peripheral.services == nil {
            whenDone()
            return
        }
        if let characteristic = findCharacteristic(characteristicUUID: RFDuinoUUID.Disconnect, forServiceWithUUID: RFDuinoUUID.Discover) {
            var byte = UInt8(1)
            let data = NSData(bytes: &byte, length: 1)
            peripheral.writeValue(data, forCharacteristic: characteristic, type: .WithResponse)
        }
    }
    
    func send(data: NSData) {
        if let characteristic = findCharacteristic(characteristicUUID: RFDuinoUUID.Send, forServiceWithUUID: RFDuinoUUID.Discover) {
        	peripheral.writeValue(data, forCharacteristic: characteristic, type: .WithResponse)
        }
    }
}

/* Calculated vars */
public extension RFDuino {
    var name: String {
        get {
            return peripheral.name ?? "Unknown device"
        }
    }
}

extension RFDuino: CBPeripheralDelegate {
    
    public func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        "Did send data to peripheral".log()
        
        if characteristic.UUID == RFDuinoUUID.Disconnect.id {
            if let doneBlock = whenDoneBlock {
                doneBlock()
            }
        } else {
            delegate?.rfDuinoDidSendData(self, forCharacteristic: self.findCharacteristic(characteristicUUID: RFDuinoUUID.Send, forServiceWithUUID: RFDuinoUUID.Discover)!, error: error)
        }
    }
    
    public func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        "Did discover services".log()
        if let discoveredServices = peripheral.services {
            for service in discoveredServices {
                if service.UUID == RFDuinoUUID.Discover.id {
                    peripheral.discoverCharacteristics(nil, forService: service)
                }
            }
        }
        delegate?.rfDuinoDidDiscoverServices(self)
    }
    
    public func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        "Did discover characteristics for service".log()
        delegate?.rfDuinoDidDiscoverCharacteristics(self)
    }
}