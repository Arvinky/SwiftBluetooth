//
//  Bluetooth.swift
//  TelinkBlue
//
//  Created by Arvin on 2017/7/19.
//  Copyright © 2017年 Arvin. All rights reserved.
//

import Foundation
import CoreBluetooth

public class Device: NSObject {
    var peripheral : CBPeripheral?
    var sevices : [CBMutableService]?
    var state : PeripheralState?
    var beenConnect : Bool?
    var advertisement : NSMutableDictionary?
    var rssi : Any?
    override init() {
        sevices = Array.init()
        advertisement = NSMutableDictionary.init()
    }
}
@objc public enum PeripheralState :Int {
    case PeripheralStateDiscovered = 1, PeripheralStateUpdateRSSI, PeripheralStateDidConnect
}
@objc public protocol BluetoothHandleProtocol : NSObjectProtocol {
    func updateBluetoothState(_ state : CBManagerState)
    @objc optional func updatePeripheralState(_ state : PeripheralState, _ device : Device)
}
extension CBPeripheral {
    var identifyString : String {
        return self.identifier.uuidString
    }
}
class BluetoothHandle: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var manager : CBCentralManager?
    var delegate : BluetoothHandleProtocol?
    var devicesDiscovered : [Device]?
    var currentDevice : Device?
    
    
    static let handle = BluetoothHandle.init()
    static func startScan() { BluetoothHandle.handle.manager?.scanForPeripherals(withServices: nil, options: nil) }
    static func stopScan() { BluetoothHandle.handle.manager?.stopScan() }
    
    private override init() {
        let quene = DispatchQueue.init(label: "BluetoothQuene")
        manager = CBCentralManager.init(delegate: nil, queue: quene)
    }
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        delegate?.updateBluetoothState(central.state)
    }
    func whetherContainObj(_ source : [Device], _ peripheral : CBPeripheral) -> Any {
        for device in source {
            if device.peripheral?.identifyString.compare((device.peripheral?.identifyString)!)==ComparisonResult.orderedSame {
                return device;
            }
        }
        return NSNotFound
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let obj = self.whetherContainObj(devicesDiscovered!, peripheral)
        var device : Device?
        if obj is Device {
            device = obj as? Device
            device?.rssi = RSSI
            device?.state = PeripheralState.PeripheralStateUpdateRSSI
        }else{
            device = Device()
            device?.rssi = RSSI
            device?.advertisement = NSMutableDictionary.init(dictionary: advertisementData)
            device?.state = PeripheralState.PeripheralStateDiscovered
            devicesDiscovered?.append(device!)
            delegate?.updatePeripheralState!((device?.state)!, device!)
        }
        print("\(advertisementData)\n")
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let device = whetherContainObj(devicesDiscovered!, peripheral)
        let obj = device as! Device
        obj.state = PeripheralState.PeripheralStateDidConnect
        delegate?.updatePeripheralState!(obj.state!, obj)
        self.currentDevice = obj
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            let mutSerivce = CBMutableService.init(type: service.uuid, primary: true)
            self.currentDevice?.sevices?.append(mutSerivce)
        }
    }
    
}
