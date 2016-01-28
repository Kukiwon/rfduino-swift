//
//  RFDuino+Extensions.swift
//  Pods
//
//  Created by Jordy van Kuijk on 28/01/16.
//
//

import Foundation
import CoreBluetooth

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
            existingRFDuino.peripheral.delegate = existingRFDuino
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