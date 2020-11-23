//
//  LogViewController.swift
//  SyncWalkman-gui
//
//  Created by 原園征志 on 2019/03/24.
//  Copyright © 2019 原園征志. All rights reserved.
//

import Cocoa
import SyncWalkman

class LogViewController: NSViewController {
    
    var log: [(status: String, message: String)] = []
    var showlog: [(status: String, message: String)] = []

    @IBOutlet weak var logTableView: NSTableView!
    @IBOutlet weak var resultLabel: NSTextField!
    
    @IBOutlet weak var foundButton: NSButton!
    @IBOutlet weak var sentButton: NSButton!
    @IBOutlet weak var skippedButton: NSButton!
    @IBOutlet weak var deletedButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        self.setupNotifications()
        self.setupCheckButtonState()
    }
    
}

//MARK: Setup
extension LogViewController{
    func setupNotifications(){
        NotificationCenter.default.addObserver(forName: ViewController.didPushStartButton, object: nil, queue: nil) { (notification) in
            self.log.removeAll()
            self.showlog.removeAll()
            self.resultLabel.stringValue = ""
            self.foundButton.isEnabled = false
            self.sentButton.isEnabled = false
            self.skippedButton.isEnabled = false
            self.deletedButton.isEnabled = false
        }
        
        NotificationCenter.default.addObserver(forName: ViewController.didFinishAllProcess, object: nil, queue: nil) { (notification) in
            DispatchQueue.main.async {
                self.foundButton.isEnabled = true
                self.sentButton.isEnabled = true
                self.skippedButton.isEnabled = true
                self.deletedButton.isEnabled = true
                
                let notification: NSUserNotification = NSUserNotification()
                notification.title = "転送完了"
                notification.informativeText = self.resultLabel.stringValue
                NSUserNotificationCenter.default.deliver(notification)
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.didFoundFile(_:)), name: SyncWalkman.didFoundTrackFile, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didFoundFile(_:)), name: SyncWalkman.didFoundPlaylistFile, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didSendFile(_:)), name: SyncWalkman.didSendTrack, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didSendFile(_:)), name: SyncWalkman.didSendPlaylist, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didSkipFile(_:)), name: SyncWalkman.didSkipTrack, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didSkipFile(_:)), name: SyncWalkman.didSkipPlaylist, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didDeleteFile(_:)), name: SyncWalkman.didDeleteTrack, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didDeleteFile(_:)), name: SyncWalkman.didDeletePlaylist, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didFinishEachProcess(_:)), name: SyncWalkman.didFinishSendTrack, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didFinishEachProcess(_:)), name: SyncWalkman.didFinishDeleteTrack, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didFinishEachProcess(_:)), name: SyncWalkman.didFinishSendPlaylist, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didFinishEachProcess(_:)), name: SyncWalkman.didFinishDeletePlaylist, object: nil)
    }
    
    func setupCheckButtonState(){
        self.foundButton.state = SyncWalkmanManager.shared.syncWalkman.config.printStateFound ? .on : .off
        self.sentButton.state = SyncWalkmanManager.shared.syncWalkman.config.printStateSent ? .on : .off
        self.skippedButton.state = SyncWalkmanManager.shared.syncWalkman.config.printStateSkipped ? .on : .off
        self.deletedButton.state = SyncWalkmanManager.shared.syncWalkman.config.printStateDeleted ? .on : .off
    }
}


//MAK: Notification
extension LogViewController{
    @objc func didFoundFile(_ noti: Notification){
        let element = (status: "found", message: noti.userInfo!["path"] as! String)
        self.log.append(element)
        if SyncWalkmanManager.shared.syncWalkman.config.printStateFound{
            self.showlog.append(element)
        }
        self.scrollToEnd()
    }
    
    @objc func didSendFile(_ noti: Notification){
        let element = (status: "sent", message: noti.userInfo!["topath"] as! String)
        self.log.append(element)
        if SyncWalkmanManager.shared.syncWalkman.config.printStateSent{
            self.showlog.append(element)
        }
        self.scrollToEnd()
    }
    
    @objc func didSkipFile(_ noti: Notification){
        let element = (status: "skipped", message: noti.userInfo!["topath"] as! String)
        self.log.append(element)
        if SyncWalkmanManager.shared.syncWalkman.config.printStateSkipped{
            self.showlog.append(element)
        }
        self.scrollToEnd()
    }
    
    @objc func didDeleteFile(_ noti: Notification){
        let element = (status: "deleted", message: noti.userInfo!["path"] as! String)
        self.log.append(element)
        if SyncWalkmanManager.shared.syncWalkman.config.printStateDeleted{
            self.showlog.append(element)
        }
        self.scrollToEnd()
    }
    
    func scrollToEnd(){
        DispatchQueue.main.async {
            self.logTableView.reloadData()
            self.logTableView.scrollRowToVisible(self.showlog.count - 1)
        }
    }
    
    @objc func didFinishEachProcess(_ noti: Notification){
        DispatchQueue.main.async {
            switch noti.name{
            case SyncWalkman.didFinishSendTrack:
                if self.resultLabel.stringValue != ""{
                    self.resultLabel.stringValue += "\n"
                }
                self.resultLabel.stringValue += "track: copied \(noti.userInfo!["copied"] as! Int), skipped \(noti.userInfo!["skipped"] as! Int)"
            case SyncWalkman.didFinishDeleteTrack:
                self.resultLabel.stringValue += ", deleted \(noti.userInfo!["count"] as! Int)"
            case SyncWalkman.didFinishSendPlaylist:
                if self.resultLabel.stringValue != ""{
                    self.resultLabel.stringValue += "\n"
                }
                self.resultLabel.stringValue += "playlist: sent \(noti.userInfo!["count"] as! Int)"
            case SyncWalkman.didFinishDeletePlaylist:
                self.resultLabel.stringValue += ", deleted \(noti.userInfo!["count"] as! Int)"
            default:
                break
            }
            
        }
    }
}

//MARK: IB Action
extension LogViewController{
    @IBAction func changeCheckButton(sender: NSButton){
        switch sender.tag{
        case 0:
            SyncWalkmanManager.shared.syncWalkman.config.printStateFound = (sender.state == .on)
        case 1:
            SyncWalkmanManager.shared.syncWalkman.config.printStateSent = (sender.state == .on)
        case 2:
            SyncWalkmanManager.shared.syncWalkman.config.printStateSkipped = (sender.state == .on)
        case 3:
            SyncWalkmanManager.shared.syncWalkman.config.printStateDeleted = (sender.state == .on)
        default:
            break
        }
        self.showlog = self.log.filter({ (status: String, message: String) -> Bool in
            if status == "skipped"{
                if SyncWalkmanManager.shared.syncWalkman.config.printStateSkipped{
                    return true
                }
                return false
            }else if status == "found"{
                if SyncWalkmanManager.shared.syncWalkman.config.printStateFound{
                    return true
                }
                return false
            }else if status == "sent" {
                if SyncWalkmanManager.shared.syncWalkman.config.printStateSent{
                    return true
                }
                return false
            }else if status == "deleted"{
                if SyncWalkmanManager.shared.syncWalkman.config.printStateDeleted{
                    return true
                }
                return false
            }
            return false
        })
        self.logTableView.reloadData()
    }
}

//MARK: TableView data source
extension LogViewController: NSTableViewDataSource{
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if !self.isViewLoaded{
            return 0
        }
        
        return self.showlog.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if self.isViewLoaded{
            guard let tableColumn = tableColumn else { return nil }
            if tableColumn.identifier == NSUserInterfaceItemIdentifier("Status"){
                return self.showlog[row].status
            }else if tableColumn.identifier == NSUserInterfaceItemIdentifier("Message"){
                return self.showlog[row].message
            }
        }
        return nil
    }
    
}
