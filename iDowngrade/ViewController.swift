//
//  ViewController.swift
//  iDowngrade
//
//  Created by Stas on 7/15/18.
//  Copyright © 2018 iSan4eZ. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var rbtnSelectFromList: NSButton!
    @IBOutlet weak var rbtnManualSelect: NSButton!
    @IBOutlet weak var cbBackupName: NSPopUpButton!
    @IBOutlet weak var txbSelectedPath: NSPathControl!
    @IBOutlet weak var btnSelectPath: NSButton!
    @IBOutlet weak var lbCurrent: NSTextField!
    @IBOutlet weak var cbNewVersion: NSPopUpButton!
    @IBOutlet weak var cbxBackup: NSButton!
    @IBOutlet weak var cbxArchive: NSButton!
    @IBOutlet weak var btnConvert: NSButton!
    
    
    let databaseUrl = "https://en.wikipedia.org/wiki/IOS_version_history"
    var currentVersion = "Unknown"
    var currentBackup : Backup!
    public static var iOSVersionsList = [iOS]()
    var backups = [Backup]()
    var backupFolders = [URL]()
    
    func MessageBox(message: String, title: String) /* -> Bool*/ {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
        //return alert.runModal() == .alertFirstButtonReturn
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backupFolders.append(FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("MobileSync/Backup"))
        loadiOSDatabase()
        backups = [Backup]()
        for folder in backupFolders{
            backups.append(contentsOf: loadBackups(path: folder))
        }
        cbBackupName.removeAllItems()
        for backup in backups{
            cbBackupName.addItem(withTitle: backup.description)
            cbBackupName.lastItem!.representedObject = backup
        }
        
        if cbBackupName.numberOfItems > 0
        {
            cbBackupName.selectItem(at: 0)
            cbBackupName_SelectedIndexChanged(cbBackupName)
            currentBackup = (cbBackupName.selectedItem!.representedObject as! Backup)
            currentVersion = currentBackup.ios.name;
        }
        else
        {
            var notFound = ""
            for folder in backupFolders{
                notFound.append("\n\(folder.path)")
            }
            MessageBox(message: "No backups were found in folders:\(notFound)", title: "Error")
            rbtnSelectFromList.isEnabled = false
            rbtnManualSelect.state = .on
        }
        fixAll()
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func backUpSelect_CheckedChanged(_ sender: Any) {
        fixAll()
    }
    
    func fixAll(){
        if rbtnSelectFromList.state == .on{
            currentBackup = (cbBackupName.selectedItem!.representedObject as! Backup)
            currentVersion = currentBackup.ios.name
        } else {
            if txbSelectedPath.url != nil{
                currentBackup = (txbSelectedPath.pathComponentCells().first!.representedObject as! Backup)
                currentVersion = currentBackup.ios.name
            } else {
                currentVersion = "Unknown"
            }
        }
        
        cbBackupName.isEnabled = rbtnSelectFromList.state == .on
        
        txbSelectedPath.isEnabled = rbtnManualSelect.state == .on
        btnSelectPath.isEnabled = rbtnManualSelect.state == .on
        
        lbCurrent.stringValue = "Current version: \(currentVersion)"
        cbNewVersion.isEnabled = currentVersion != "Unknown"
        
        btnConvert.isEnabled = (((rbtnManualSelect.state == .on && txbSelectedPath.url != nil) || (rbtnSelectFromList.state == .on && cbBackupName.selectedItem != nil)) && cbNewVersion.selectedItem != nil)
    }
    
    func loadBackups(path: URL) -> [Backup]{
        var result = [Backup]()
        
        if FileManager.default.fileExists(atPath: path.path){
            for folder in path.subDirectories
            {
                do{
                    result.append(try Backup(path: folder))
                } catch {
                    print("Error")
                    continue
                }
            }
        } else {
            print("Dir not exists")
        }
        
        return result;
    }
    
    func loadiOSDatabase(){
            do {
                let htmlCode = try String(contentsOf: URL(string: databaseUrl)!)
                let rawContents = htmlCode.sliceToArray(from: "<tr valign=\"top\"", to: "</td>")!
                for m in rawContents{
                    let ios = iOS()
                    var raw = ""
                    let temp = m.sliceToArray(from: "<th style=", to: "</th>")
                    if temp!.count > 0{
                        raw = m.sliceToArray(from: "<th style=", to: "</th>")![0]
                    } else {
                        raw = m.sliceToArray(from: "style=", to: "</th>")![0]
                    }
                    raw = raw.replacingOccurrences(of: "</th>", with: "").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "<sup", with: "")
                    
                    raw = String(raw.split(separator: ">")[1].components(separatedBy: " id=")[0])
                    ios.name = raw
                    raw = String(raw.split(separator: " ")[0])
                    ios.version = raw
                    
                    raw = m.sliceToArray(from: "<td>", to: "\n")![0]
                    raw = String(raw.split(separator: "<")[0].split(separator: "\n")[0].split(separator: " ")[0])
                    
                    ios.buildNumber = raw;
                    
                    ViewController.iOSVersionsList.append(ios)
                }
            } catch {
                print("Error")
                // contents could not be loaded
            }
    }
    
    @IBAction func btnSelectPath_Click(_ sender: Any) {
        guard let window = view.window else { return }
        
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        panel.beginSheetModal(for: window) { (result) in
            if result == NSApplication.ModalResponse.OK {
                do{
                    if (panel.urls.count > 0){
                        self.txbSelectedPath.url = panel.urls[0]
                        self.currentBackup = try Backup(path: panel.urls[0])
                        self.txbSelectedPath.pathComponentCells().first?.representedObject = self.currentBackup
                        self.currentVersion = self.currentBackup.ios.name
                        
                        self.cbNewVersion.removeAllItems()
                        for i in 0...ViewController.iOSVersionsList.count-1
                        {
                            if (ViewController.iOSVersionsList[i].version == self.currentVersion){
                                break
                            }
                            self.cbNewVersion.insertItem(withTitle: ViewController.iOSVersionsList[i].description, at: 0)
                            self.cbNewVersion.item(at: 0)!.representedObject = ViewController.iOSVersionsList[i]
                        }
                        self.cbNewVersion.selectItem(at: 0)
                        
                        self.fixAll()
                    }
                } catch{
                    self.MessageBox(message: "Directory is not containing backup or corrupted", title: "Error")
                }
            }
        }
    }
    
    @IBAction func cbBackupName_SelectedIndexChanged(_ sender: Any) {
        if (cbBackupName.selectedItem != nil)
        {
            currentBackup = (cbBackupName.selectedItem!.representedObject as! Backup)
            currentVersion = currentBackup.ios.name;
            cbNewVersion.removeAllItems()
            for i in 0...ViewController.iOSVersionsList.count-1
            {
                if (ViewController.iOSVersionsList[i].version == currentVersion){
                    break
                }
                cbNewVersion.insertItem(withTitle: ViewController.iOSVersionsList[i].description, at: 0)
                cbNewVersion.item(at: 0)?.representedObject = ViewController.iOSVersionsList[i]
            }
            cbNewVersion.selectItem(at: 0)
        }
        fixAll()
    }
    
    @IBAction func btnConvert_Click(_ sender: Any) {
        do
         {
            try currentBackup.changeiOSto(newiOS: (cbNewVersion.selectedItem!.representedObject as! iOS), backItUp: cbxBackup.state == .on, archive: cbxArchive.state == .on)
            MessageBox(message: "Convertion complete!\nNow you can restore your device from this backup!", title: "Success")
        }
        catch
        {
            MessageBox(message: "\(error)",title: "Error")
        }
        reload()
    }
    
    func reload(){
        backups = [Backup]()
        for folder in backupFolders{
            backups.append(contentsOf: loadBackups(path: folder))
        }
        cbBackupName.removeAllItems()
        for backup in backups{
            cbBackupName.addItem(withTitle: backup.description)
            cbBackupName.lastItem!.representedObject = backup
        }
        
        if cbBackupName.numberOfItems > 0
        {
            cbBackupName.selectItem(at: 0)
            currentBackup = (cbBackupName.selectedItem!.representedObject as! Backup)
            currentVersion = currentBackup.ios.name;
            fixAll();
        }
        else
        {
            rbtnSelectFromList.isEnabled = false
            rbtnManualSelect.state = .on
        }
    }
}

extension URL {
    var isDirectory: Bool {
        return (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
    var subDirectories: [URL] {
        guard isDirectory else { return [] }
        return (try? FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]).filter{ $0.isDirectory }) ?? []
    }
}

extension String {
    
    func sliceToArray(from: String, to: String) -> [String]? {
        var result = [String]()
        if self.contains(from){
            var startRange = self.range(of: from)!
            let endRange = range(of: to, range: (startRange.upperBound..<self.endIndex))!
            while let a = range(of: from, range: (startRange.upperBound..<endRange.lowerBound)) {
                startRange = a
            }
            result.append(String(self[startRange.upperBound..<endRange.lowerBound]))
            let next = self[startRange.upperBound..<self.endIndex]
            let out = String(next).sliceToArray(from: from, to: to)
            if out != nil && out!.count > 0{
                for i in out!{
                    result.append(i)
                }
            }
        }
        return result
    }
    
    func slice(from: String, to: String) -> String? {
        if self.contains(from){
            let startRange = self.range(of: from)!
            let endRange = range(of: to, range: (startRange.upperBound..<self.endIndex))!
            return(String(self[startRange.upperBound..<endRange.lowerBound]))
        }
        return nil
    }
}
