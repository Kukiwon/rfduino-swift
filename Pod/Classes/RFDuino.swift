//
//  RFDuino.swift
//  Pods
//
//  Created by Jordy van Kuijk on 27/01/16.
//
//

import Foundation

public protocol RFDuinoDelegate {
    func rfDuinoDidTimeout(rfDuino: RFDuino)
    func rfDuinoDidDiscover(rfDuino: RFDuino)
}

public class RFDuino: NSObject {
    
    public var isTimedOut = false
    public var isConnected = false
    public var delegate: RFDuinoDelegate?
    public static let timeoutThreshold = 5.0
    
    var peripheral: CBPeripheral
    var timeoutTimer: NSTimer?
    
    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        super.init()
    }
    
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
}

/* Calculated vars */
public extension RFDuino {
    var name: String? {
        get {
            return peripheral.name
        }
    }
}

extension Array where Element: RFDuino {
    mutating func insertIfNotContained(rfDuino: RFDuino) {
        if !(self.contains { return $0.peripheral == rfDuino.peripheral }) {
            // append the newly discovered rfDuino
            self.append(rfDuino as! Element)
            rfDuino.confirmAndTimeout()
        } else {
            // find existing rfDuino and notify it of rediscovery
            let indexOfExistingRFDuino = self.indexOf { return $0.peripheral == rfDuino.peripheral }
            let existingRFDuino = self[indexOfExistingRFDuino!]
            existingRFDuino.confirmAndTimeout()
        }
    }
    
    func findRFDuino(peripheral: CBPeripheral) -> RFDuino? {
        let indexOfRFDuino = self.indexOf { return $0.peripheral == peripheral }
        if let index = indexOfRFDuino {
            return self[index]
        } else {
            return nil
        }
    }
}