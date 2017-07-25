//
//  ViewController.swift
//  TelinkBlue
//
//  Created by Arvin on 2017/7/19.
//  Copyright © 2017年 Arvin. All rights reserved.
//

import UIKit
import CoreBluetooth
public class DeviceCell : UITableViewCell {
    @IBOutlet weak var rssiImg: UIImageView!
    @IBOutlet weak var rssiLab: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var service: UILabel!
    @IBOutlet weak var backG: UIImageView!
    func contentWithModel(_ device : Device)  {
        let rssi : NSNumber = device.rssi as! NSNumber
        let rssiInt = abs(rssi.intValue);
        let blue = UIColor.blue
        var imgName : NSString?
        rssiLab.text = device.rssiInfo
        service.text = device.adveDataSevices
        if rssiInt>0 && rssiInt<100 {
            imgName =  NSString.init(format: "signal-strength-%d", (-rssiInt + 100)/20 + 1)
            rssiImg.image = UIImage.init(named: imgName! as String)?.imageWithTintColor(color: blue)
        }else if(rssiInt==100){
            imgName = NSString.init(format: "signal-strength-%d", (-rssiInt + 100)/20)
            rssiImg.image = UIImage.init(named: imgName! as String)?.imageWithTintColor(color: blue)
        }
        
        name.text = device.name
        service.text = device.adveDataSevices   
    }
    public override func awakeFromNib() {
        super.awakeFromNib()
        let gray = UIColor.gray
        backG.image = UIImage.init(named: "signal-strength-5.png")?.imageWithTintColor(color: gray)
    }
}
extension UIImage {
    func imageWithTintColor(color : UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, 0);
        color.setFill()
        let bounds = CGRect.init(x: 0, y: 0, width: self.size.width, height: self.size.height);
        UIRectFill(bounds);
        draw(in: bounds, blendMode: CGBlendMode.destinationIn, alpha: 1.0);
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}

class BasicVC : UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        normalSetting()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setBlock()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        initBlock()
    }
    func normalSetting() { }
    func setBlock() { }
    func initBlock() { }
}
class ViewController: BasicVC, BluetoothHandleProtocol , UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        BluetoothHandle.handle.manager?.delegate = BluetoothHandle.handle
        BluetoothHandle.startScan()
    }
    func updateData(_ freshcontrol : UIRefreshControl) {
        BluetoothHandle.handle.devicesDiscovered.removeAll()
        tableView.reloadData()
        BluetoothHandle.startScan()
        freshcontrol.endRefreshing()
    }
    override func normalSetting() {
        let freshControl = UIRefreshControl.init()
        freshControl.addTarget(self, action: #selector(updateData), for: UIControlEvents.valueChanged)
        tableView.addSubview(freshControl)
        tableView.estimatedRowHeight = 20
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    override func setBlock() {
        BluetoothHandle.handle.delegate = self
    }
    override func initBlock() {
        BluetoothHandle.handle.delegate = nil
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
    func delayDismiss(_ alert : UIAlertController) {
        alert.dismiss(animated: true, completion: nil)
    }
    
    func updatePeripheralState(_ state: PeripheralState, _ device: Device) {
        let index = BluetoothHandle.handle.devicesDiscovered.index(where: { $0.peripheral?.identifyString.compare((device.peripheral?.identifyString)!) == ComparisonResult.orderedSame })
        
        let indexPath = IndexPath.init(row: index!, section: 0)
        switch state {
        case .PeripheralStateUpdateRSSI:
            tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.none)
            break
        case .PeripheralStateDiscovered:
            tableView.insertRows(at: [indexPath], with: UITableViewRowAnimation.none)
            tableView.reloadData()
        case .PeripheralStateDiscoverATTTimout:
            let alert = UIAlertController.init(title: "tips", message: "discover time out", preferredStyle: UIAlertControllerStyle.alert)
            self.navigationController?.present(alert, animated: true, completion: nil)
            self.perform(#selector(delayDismiss(_:)), with: alert, afterDelay: 2)
            
        default:
            print("other\(state)")
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BluetoothHandle.handle.devicesDiscovered.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell") as! DeviceCell
        let  device = BluetoothHandle.handle.devicesDiscovered[indexPath.row]
        cell.contentWithModel(device)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        BluetoothHandle.handle.stopScan()
        if indexPath.row % 3 == 0{
            ShowHandle.showTips("准备连接😆", ShowtipsViewType.ShowtipsViewTypeSmall)
        }else if indexPath.row % 3 == 1{
            ShowHandle.showTips("准备连接😆", ShowtipsViewType.ShowtipsViewTypeMiddle)
        }else{
            ShowHandle.showTips("准备连接😆", ShowtipsViewType.ShowtipsViewTypeBig)
        }
        ShowHandle.delayHidden(2)
    }
}

