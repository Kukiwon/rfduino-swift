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
        manager.startScanningForRFDuinos()
        tableView.rowHeight = 56
        tableView.tableFooterView = UIView()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidAppear(animated)
        if let selectedIP = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(selectedIP, animated: true)
        }
    }
        
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(manager.discoveredRFDuinos.count, 1)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if manager.discoveredRFDuinos.count == 0 {
            return tableView.dequeueReusableCellWithIdentifier("noResultsCell")!
        }
        
        let identifier = "rfDuinoCell"
        let rfDuino = manager.discoveredRFDuinos[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier)
        
        if rfDuino.isTimedOut {
            cell?.textLabel?.textColor = UIColor.grayColor()
            cell?.textLabel?.text = rfDuino.name + " (timed out)"
        } else {
            cell?.textLabel?.textColor = UIColor.blackColor()
            cell?.textLabel?.text = rfDuino.name + (rfDuino.RSSI != nil ? " \(rfDuino.RSSI!)" : "")
        }
        
        return cell!
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        let rfDuino = manager.discoveredRFDuinos[tableView.indexPathForSelectedRow!.row]
        if rfDuino.isTimedOut {
            tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow!, animated: true)
        }
        return !rfDuino.isTimedOut
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let rfDuino = manager.discoveredRFDuinos[tableView.indexPathForSelectedRow!.row]
        let d = segue.destinationViewController as? DetailsViewController
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