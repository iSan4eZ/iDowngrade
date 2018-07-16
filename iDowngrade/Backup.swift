//
//  Backup.swift
//  iDowngrade
//
//  Created by Stas on 7/15/18.
//  Copyright © 2018 iSan4eZ. All rights reserved.
//

import Cocoa

class Backup: NSObject {
    
    var name : String!
    var ios = iOS()
    var device = Device()
    var path : URL!
    var date : Date!
    private let formatter = DateFormatter()
    
    enum BackupError: Error {
        case noInfoPlist
        case another
    }
    
    init(path: URL) throws {
        formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        let fileManager = FileManager.default;
        if fileManager.fileExists(atPath: path.appendingPathComponent("Info.plist").path){
            var plistDict: NSDictionary?
            plistDict = NSDictionary(contentsOfFile: path.appendingPathComponent("Info.plist").path)
            if let backup = plistDict {
                self.name = path.lastPathComponent
                self.path = path
                self.date = (backup["Last Backup Date"] as! Date)
                self.ios.buildNumber = (backup["Build Version"] as! String)
                self.ios.version = (backup["Product Version"] as! String)
                let temp = self.ios.version
                self.ios.name = ViewController.iOSVersionsList.filter{
                    $0.version == temp
                    }.first?.name
                self.device.deviceName = (backup["Device Name"] as! String)
                self.device.deviceType = (backup["Product Name"] as! String)
                self.device.deviceVersion = (backup["Product Type"] as! String)
            }
        }else{
            throw BackupError.noInfoPlist
        }
    }
    
    func changeiOSto(newiOS: iOS, backItUp: Bool, archive: Bool) throws {
        let fManager = FileManager.default
        if fManager.fileExists(atPath: path.appendingPathComponent("Info.plist").path){
            do {
                if backItUp{
                    try fManager.copyItem(at: path.appendingPathComponent("Info.plist"), to: path.appendingPathComponent("Info - \(formatter.string(from: Date())).plist"))
                }
                if archive{
                    let newPath = path.deletingLastPathComponent().appendingPathComponent("\(path.lastPathComponent) - \(formatter.string(from: Date()))")
                    try fManager.moveItem(at: path, to: newPath)
                    path = newPath
                }
                let pList = NSMutableDictionary(contentsOfFile: path.appendingPathComponent("Info.plist").path)!
                pList["Product Version"] = newiOS.version
                pList["Build Version"] = newiOS.buildNumber
            
                try pList.write(to: path.appendingPathComponent("Info.plist"))
            }catch{
                ViewController().MessageBox(message: "\(error)", title: "Error")
                throw BackupError.another
            }
        } else {
            throw BackupError.noInfoPlist
        }
    }
    
    public override var description: String {
        return ("\(device) (\(ios)) - \(formatter.string(from: date!))");
    }
}
