//
//  iOS.swift
//  iDowngrade
//
//  Created by Stas on 7/15/18.
//  Copyright © 2018 iSan4eZ. All rights reserved.
//

import Cocoa

class iOS: NSObject {
    var name : String!
    var version : String!
    var buildNumber : String!
    
    public override var description: String{
        return name
    }
}
