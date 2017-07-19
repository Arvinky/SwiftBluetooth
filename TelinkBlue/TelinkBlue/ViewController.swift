//
//  ViewController.swift
//  TelinkBlue
//
//  Created by Arvin on 2017/7/19.
//  Copyright © 2017年 Arvin. All rights reserved.
//

import UIKit
import CoreBluetooth
class ViewController: UIViewController, BluetoothHandleProtocol {
    func updatePeripheralState(_ state: PeripheralState, _ device: Device) {
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        BluetoothHandle.handle.manager?.delegate = BluetoothHandle.handle
        BluetoothHandle.startScan()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        BluetoothHandle.handle.delegate = self
    }
    func updateBluetoothState(_ state: CBManagerState) {
        switch state {
        case .poweredOn:
            BluetoothHandle.startScan()
        case .poweredOff:
            let burl = URL.init(string: "prefs:root=Bluetooth")
            if UIApplication.shared.canOpenURL(burl!) {
                if #available(iOS 10.0, *) { UIApplication.shared.open(burl!, options: [:], completionHandler: nil) }
                else    {    UIApplication.shared.openURL(burl!) }
            }
        default: break
        }
    }
    
}

