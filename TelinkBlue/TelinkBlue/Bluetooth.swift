//
//  Bluetooth.swift
//  TelinkBlue
//
//  Created by Arvin on 2017/7/19.
//  Copyright © 2017年 Arvin. All rights reserved.
//

import Foundation
import CoreBluetooth
let AdvDataManafacturerData = "kCBAdvDataManufacturerData"
let AdvDataConnectedAble = "kCBAdvDataIsConnectable"
let AdvDataLocalName = "kCBAdvDataLocalName"
let AdvDataServiceUUIDs = "kCBAdvDataServiceUUIDs"
let Unknow = "UnKnow"
let UnName = "UnName"
let TimeForUpdateRSSI = 2.0

public class Device: NSObject {
    var peripheral : CBPeripheral?
    var sevices : [CBMutableService] = [CBMutableService].init()
    var state : PeripheralState?
    var beenConnect : Bool?
    var advertisement : NSMutableDictionary = NSMutableDictionary.init()
    var rssi : Any?
    var name = "UnName"
    var adveDataSevices : String {
        for str in advertisement.allKeys {
            if (str as! String).compare(AdvDataServiceUUIDs)==ComparisonResult.orderedSame {
                if advertisement[str] is Array<Any> {
                    let s = advertisement.value(forKey: str as! String) as! Array<Any>
                    return "\(s.count) Services"
                }
            }
        }
        return "NoServices"
    }
    var rssiInfo : String {
        if rssi is NSNumber {
            let rssiValue : Int = (rssi as! NSNumber).intValue
            if rssiValue < 0 { return String(rssiValue) }
            return "---"
        }
        if (rssi is String) || (rssi is NSString) {
            return rssi as! String
        }
        return UnName
    }
}
@objc public enum PeripheralState :Int {
    case PeripheralStateDiscovered = 1, PeripheralStateUpdateRSSI, PeripheralStateDidConnect, PeripheralStateFinishDiscoverATT,PeripheralStateDiscoverATTTimout
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
public let disconverATTTime : TimeInterval = 10

class BluetoothHandle: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var manager : CBCentralManager?
    var delegate : BluetoothHandleProtocol?
    var devicesDiscovered = [Device]()
    var currentDevice : Device?
    var descriptors = [CBDescriptor]()
    var disconverATTTimer : Timer?
    var updateRSSITimer : Timer?
    
    static let handle = BluetoothHandle.init()
    static func startScan() { BluetoothHandle.handle.startScan() }
    static func stopScan() { BluetoothHandle.handle.stopScan() }
    func startScan() { manager?.scanForPeripherals(withServices: nil, options: nil) }
    func stopScan() { manager?.stopScan() }
    func connect(_ peripheral : CBPeripheral?) {
        if (peripheral == nil) || (peripheral?.state != CBPeripheralState.connected) { return }
        if currentDevice?.peripheral?.state==CBPeripheralState.connected {
            manager?.cancelPeripheralConnection((currentDevice?.peripheral)!)
        }
        manager?.connect(peripheral!, options: [CBConnectPeripheralOptionNotifyOnConnectionKey : true])
    }
    
    private override init() {
        manager = CBCentralManager.init(delegate: nil, queue: DispatchQueue.main)
    }
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        delegate?.updateBluetoothState(central.state)
    }
    func whetherContainObj(_ source : [Device], _ peripheral : CBPeripheral) -> Any {
        for device in source {
            if device.peripheral?.identifyString.compare(peripheral.identifyString)==ComparisonResult.orderedSame {
                return device;
            }
        }
        return NSNotFound
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if updateRSSITimer == nil {
            updateRSSITimer = Timer.scheduledTimer(timeInterval: TimeForUpdateRSSI, target: self, selector: #selector(startScan), userInfo: nil, repeats: true)
        }
        let obj = self.whetherContainObj(devicesDiscovered, peripheral)
        var device : Device?
        if obj is Device {
            device = obj as? Device
            device?.rssi = RSSI
            device?.state = PeripheralState.PeripheralStateUpdateRSSI
        }else{
            device = Device()
            device?.peripheral = peripheral
            device?.rssi = RSSI
            if advertisementData.count > 2&&advertisementData[AdvDataLocalName] != nil {
                device?.name = (advertisementData[AdvDataLocalName] as! String)
                device?.advertisement.addEntries(from: advertisementData)
            }else if (peripheral.name != nil) {
                device?.name = peripheral.name!
            }
            device?.state = PeripheralState.PeripheralStateDiscovered
            devicesDiscovered.append(device!)
        }
        delegate?.updatePeripheralState!((device?.state)!, device!)
        print("\(advertisementData)\n")
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let device = whetherContainObj(devicesDiscovered, peripheral)
        let obj = device as! Device
        obj.state = PeripheralState.PeripheralStateDidConnect
        delegate?.updatePeripheralState!(obj.state!, obj)
        self.currentDevice = obj
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        
        disconverATTTimer = Timer.scheduledTimer(timeInterval: disconverATTTime, target: self, selector: #selector(BluetoothHandle.discoverATTTimeout), userInfo: nil, repeats: true)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            let mutSerivce = CBMutableService.init(type: service.uuid, primary: true)
            self.currentDevice?.sevices.append(mutSerivce)
            peripheral.discoverCharacteristics(nil, for: service)
        }
        descriptors.removeAll()
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for mutser in (self.currentDevice?.sevices)! {
            if mutser.uuid.uuidString.compare(service.uuid.uuidString) == ComparisonResult.orderedSame {
                mutser.characteristics = NSArray.init(array: service.characteristics!) as? [CBCharacteristic]
//                mutser.characteristics = service.characteristics
            }
        }
        for cha in service.characteristics! {
            peripheral.readValue(for: cha)
            peripheral.discoverDescriptors(for: cha)
        }
        
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        for des in characteristic.descriptors! {
            peripheral.readValue(for: des)
            descriptors.append(des)
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        if descriptors.contains(descriptor) {
            descriptors.remove(at: descriptors.index(of: descriptor)!)
        }
        if descriptors.count < 1 {
            self.currentDevice?.state = PeripheralState.PeripheralStateFinishDiscoverATT
            delegate?.updatePeripheralState!(PeripheralState.PeripheralStateFinishDiscoverATT, currentDevice!)
        }
    }
    
    func discoverATTTimeout() {
        self.currentDevice?.state = PeripheralState.PeripheralStateDiscoverATTTimout
        delegate?.updatePeripheralState!(PeripheralState.PeripheralStateDiscoverATTTimout, currentDevice!)
    }
}
