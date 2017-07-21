//
//  Showtips.swift
//  TelinkBlue
//
//  Created by Arvin on 2017/7/21.
//  Copyright © 2017年 Arvin. All rights reserved.
//

import Foundation
import UIKit
let screenWidth = UIScreen.main.bounds.size.width
let screenHeight = UIScreen.main.bounds.size.height
let showTipsViewCorneradius = 16
class ShowtipsView : UIView {
    @IBOutlet weak var activity: UIActivityIndicatorView!
    @IBOutlet weak var tips: UILabel!
    
}
enum ShowtipsViewType : CGFloat {
    case ShowtipsViewTypeSmall = 0.4, ShowtipsViewTypeMiddle = 0.6, ShowtipsViewTypeBig = 1
}
class ShowHandle : NSObject {
    static let showHandle = ShowHandle.init()
    var showView : ShowtipsView?
    let window : UIWindow = UIApplication.shared.windows.first!
    var dispatchTimer : DispatchSourceTimer?
    
    private override init() {
        
    }
    
    public static func showTips(_ tips : String, _ type : ShowtipsViewType) {
        if showHandle.showView == nil {
            showHandle.showView = Bundle.main.loadNibNamed("ShowtipsView", owner: nil, options: nil)?.first as? ShowtipsView
            showHandle.window.addSubview(showHandle.showView!)
        }
        let w = screenWidth * type.rawValue
        let h = (type.rawValue==1 ? screenHeight : screenWidth) * type.rawValue
        showHandle.showView?.layer.cornerRadius = CGFloat(type.rawValue==1 ? 0 : showTipsViewCorneradius)
        showHandle.showView?.bounds = CGRect.init(x: 0, y: 0, width: w, height: h)
        showHandle.showView?.center = showHandle.window.center
        showHandle.showView?.tips.text = tips
        showHandle.showView?.activity.startAnimating()
        showHandle.window.setNeedsDisplay()
    }
   public static func hidden() {
        var contain = false
        for view in showHandle.window.subviews {
            if view is ShowtipsView {
                contain = true
            }
        }
        if contain {
            showHandle.showView?.removeFromSuperview()
            showHandle.showView = nil
        }
    }
    public static func delayHidden(_ time : TimeInterval) {
        if showHandle.dispatchTimer != nil {
            showHandle.dispatchTimer?.cancel()
            showHandle.dispatchTimer = nil;
        }
        showHandle.dispatchTimer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags.init(rawValue: 0), queue: DispatchQueue.main)
        showHandle.dispatchTimer?.scheduleRepeating(deadline: .now()+time, interval: time, leeway: .seconds(0))
        showHandle.dispatchTimer?.setEventHandler(handler: {
            hidden()
            showHandle.dispatchTimer?.cancel()
            showHandle.dispatchTimer = nil
        })
        showHandle.dispatchTimer?.resume()
    }
}
