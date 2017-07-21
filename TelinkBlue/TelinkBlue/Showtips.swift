//
//  Showtips.swift
//  TelinkBlue
//
//  Created by Arvin on 2017/7/21.
//  Copyright © 2017年 Arvin. All rights reserved.
//

import Foundation
import UIKit
class ShowtipsView : UIView {
    @IBOutlet weak var activity: UIActivityIndicatorView!
    @IBOutlet weak var tips: UILabel!
}
enum ShowtipsViewType : Int {
    case ShowtipsViewTypeSmall
    case ShowtipsViewTypeMiddle
    case ShowtipsViewTypeBig
}
class ShowHandle : NSObject {
    static let showHandle = ShowHandle.init()
    var showView : ShowtipsView
    
    private override init() {
        
    }
    func showTips(_ tips : String, _ type : ShowtipsViewType) {
        let window : UIWindow = UIApplication.shared.windows.first!
        if showView != nil {
            showView = Bundle.main.loadNibNamed("ShowtipsView", owner: nil, options: nil)?.first as! ShowtipsView
            window.addSubview(showView)
        }
        
        
    }
}
