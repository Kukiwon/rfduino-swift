//
//  DiscoveryTableViewController.swift
//  RFDuino
//
//  Created by Jordy van Kuijk on 27/01/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import RFDuino
import CoreBluetooth

class DiscoveryTableViewController: UITableViewController {
    
    lazy var manager:RFDuinoBTManager = {
       let manager = RFDuinoBTManager.sharedInstance
        manager.delegate = self
        return manager
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // The Nordic UART UUIDs
        RFDuinoUUIDS.discoverUUID = "713D0000-503E-4C75-BA94-3148F18D941E"
        RFDuinoUUIDS.receiveUUID = "713D0002-503E-4C75-BA94-3148F18D941E"
        RFDuinoUUIDS.sendUUID = "713D0003-503E-4C75-BA94-3148F18D941E"
        
        navigationItem.title = "RBL Nano devices"
        
        manager.startScanningForRFDuinos()
        manager.setLoggingEnabled(enabled: true)
        tableView.rowHeight = 56
        tableView.tableFooterView = UIView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let selectedIP = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIP, animated: true)
        }
    }
        
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(manager.discoveredRFDuinos.count, 1)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if manager.discoveredRFDuinos.count == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "noResultsCell")!
        }
        
        let identifier = "rfDuinoCell"
        let rfDuino = manager.discoveredRFDuinos[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        
        if rfDuino.isTimedOut {
            cell?.textLabel?.textColor = UIColor.gray
            cell?.textLabel?.text = rfDuino.name + " (timed out)"
        } else {
            cell?.textLabel?.textColor = UIColor.black
            cell?.textLabel?.text = rfDuino.name + (rfDuino.RSSI != nil ? " \(rfDuino.RSSI!)" : "")
        }
        
        return cell!
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        let rfDuino = manager.discoveredRFDuinos[tableView.indexPathForSelectedRow!.row]
        if rfDuino.isTimedOut {
            tableView.deselectRow(at: tableView.indexPathForSelectedRow!, animated: true)
        }
        return !rfDuino.isTimedOut
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let rfDuino = manager.discoveredRFDuinos[tableView.indexPathForSelectedRow!.row]
        let d = segue.destination as? DetailsViewController
        d?.rfDuino = rfDuino
    }
}

extension DiscoveryTableViewController: RFDuinoBTManagerDelegate {
    func rfDuinoManagerDidDiscoverRFDuino(manager: RFDuinoBTManager, rfDuino: RFDuino) {
        rfDuino.delegate = self
        tableView.reloadData()
    }
}

extension DiscoveryTableViewController: RFDuinoDelegate {
    func rfDuinoDidTimeout(rfDuino: RFDuino) {
        tableView.reloadData()
    }
    
    func rfDuinoDidDiscover(rfDuino: RFDuino) {
        tableView.reloadData()
    }
}
