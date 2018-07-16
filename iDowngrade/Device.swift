//
//  Device.swift
//  iDowngrade
//
//  Created by Stas on 7/15/18.
//  Copyright © 2018 iSan4eZ. All rights reserved.
//

import Cocoa

class Device: NSObject {
    var deviceName : String!
    var deviceType : String!
    var deviceVersion : String!
    
    public override var description: String{
        return deviceName
    }
}
