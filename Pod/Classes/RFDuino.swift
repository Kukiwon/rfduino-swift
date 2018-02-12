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
    @objc optional func rfDuinoDidTimeout(rfDuino: RFDuino)
    @objc optional func rfDuinoDidDisconnect(rfDuino: RFDuino)
    @objc optional func rfDuinoDidDiscover(rfDuino: RFDuino)
    @objc optional func rfDuinoDidDiscoverServices(rfDuino: RFDuino)
    @objc optional func rfDuinoDidDiscoverCharacteristics(rfDuino: RFDuino)
    @objc optional func rfDuinoDidSendData(rfDuino: RFDuino, forCharacteristic: CBCharacteristic, error: Error?)
    @objc optional func rfDuinoDidReceiveData(rfDuino: RFDuino, data: Data?)
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
    var timeoutTimer: Timer?
    
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
        delegate?.rfDuinoDidDiscover?(rfDuino: self)
        
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        timeoutTimer = Timer.scheduledTimer(timeInterval: RFDuino.timeoutThreshold, target: self, selector: #selector(RFDuino.didTimeout), userInfo: nil, repeats: false)
    }
    
    @objc func didTimeout() {
        isTimedOut = true
        isConnected = false
        delegate?.rfDuinoDidTimeout?(rfDuino: self)
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
        delegate?.rfDuinoDidDisconnect?(rfDuino: self)
    }
    
    func findCharacteristic(characteristicUUID: RFDuinoUUID, forServiceWithUUID serviceUUID: RFDuinoUUID) -> CBCharacteristic? {
        if let discoveredServices = peripheral.services,
            let service = (discoveredServices.filter { return $0.uuid == serviceUUID.id }).first,
            let characteristics = service.characteristics {
            return (characteristics.filter { return $0.uuid ==  characteristicUUID.id}).first
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
    
    func sendDisconnectCommand(whenDone: @escaping () -> ()) {
        self.whenDoneBlock = whenDone
        // if no services were discovered, imediately invoke done block
        if peripheral.services == nil {
            whenDone()
            return
        }
        if let characteristic = findCharacteristic(characteristicUUID: RFDuinoUUID.Disconnect, forServiceWithUUID: RFDuinoUUID.Discover) {
            var byte = UInt8(1)
            let data = NSData(bytes: &byte, length: 1)
            peripheral.writeValue(data as Data, for: characteristic, type: .withResponse)
        }
    }
    
    func send(data: Data) {
        if let characteristic = findCharacteristic(characteristicUUID: RFDuinoUUID.Send, forServiceWithUUID: RFDuinoUUID.Discover) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
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
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        "Did send data to peripheral".log()
        
        if characteristic.uuid == RFDuinoUUID.Disconnect.id {
            if let doneBlock = whenDoneBlock {
                doneBlock()
            }
        } else {
            delegate?.rfDuinoDidSendData?(rfDuino: self, forCharacteristic: self.findCharacteristic(characteristicUUID: RFDuinoUUID.Send, forServiceWithUUID: RFDuinoUUID.Discover)!, error: error)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        "Did discover services".log()
        if let discoveredServices = peripheral.services {
            for service in discoveredServices {
                if service.uuid == RFDuinoUUID.Discover.id {
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
        }
        delegate?.rfDuinoDidDiscoverServices?(rfDuino: self)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        for characteristic in service.characteristics! {
            ("did discover characteristic with UUID: " + characteristic.uuid.description).log()
            if characteristic.uuid == RFDuinoUUID.Receive.id {
                peripheral.setNotifyValue(true, for: characteristic)
            } else if characteristic.uuid == RFDuinoUUID.Send.id {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
        
        "Did discover characteristics for service".log()
        delegate?.rfDuinoDidDiscoverCharacteristics?(rfDuino: self)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        "Did receive data for rfDuino".log()
        delegate?.rfDuinoDidReceiveData?(rfDuino: self, data: characteristic.value)
    }
}
