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

    @IBOutlet weak var logTableView: NSTableView!
    @IBOutlet weak var resultLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        NotificationCenter.default.addObserver(forName: ViewController.didPushStartButton, object: nil, queue: nil) { (notification) in
            self.log.removeAll()
            self.resultLabel.stringValue = ""
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.didFoundFile(_:)), name: SyncWalkman.didFoundTrackFile, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didFoundFile(_:)), name: SyncWalkman.didFoundPlaylistFile, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didSendFile(_:)), name: SyncWalkman.didSendTrack, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didSendFile(_:)), name: SyncWalkman.didSendPlaylist, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didSkipFile(_:)), name: SyncWalkman.didSkipTrack, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didSkipFile(_:)), name: SyncWalkman.didSkipPlaylist, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didDeleteFile(_:)), name: SyncWalkman.didDeleteTrack, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didDeleteFile(_:)), name: SyncWalkman.didDeletePlaylist, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didFinish(_:)), name: SyncWalkman.didFinishSendTrack, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didFinish(_:)), name: SyncWalkman.didFinishDeleteTrack, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didFinish(_:)), name: SyncWalkman.didFinishSendPlaylist, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didFinish(_:)), name: SyncWalkman.didFinishDeletePlaylist, object: nil)
    }
    
    @objc func didFoundFile(_ noti: Notification){
        self.log.append((status: "found", message: noti.userInfo!["path"] as! String))
        DispatchQueue.main.async {
            self.logTableView.reloadData()
            self.logTableView.scrollRowToVisible(self.log.count - 1)
        }
    }
    
    @objc func didSendFile(_ noti: Notification){
        self.log.append((status: "sent", message: noti.userInfo!["topath"] as! String))
        DispatchQueue.main.async {
            self.logTableView.reloadData()
            self.logTableView.scrollRowToVisible(self.log.count - 1)
        }
    }
    
    @objc func didSkipFile(_ noti: Notification){
        self.log.append((status: "skipped", message: noti.userInfo!["topath"] as! String))
        DispatchQueue.main.async {
            self.logTableView.reloadData()
            self.logTableView.scrollRowToVisible(self.log.count - 1)
        }
    }
    
    @objc func didDeleteFile(_ noti: Notification){
        self.log.append((status: "deleted", message: noti.userInfo!["path"] as! String))
        DispatchQueue.main.async {
            self.logTableView.reloadData()
            self.logTableView.scrollRowToVisible(self.log.count - 1)
        }
    }
    
    @objc func didFinish(_ noti: Notification){
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

//MARK: TableView data source
extension LogViewController: NSTableViewDataSource{
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if !self.isViewLoaded{
            return 0
        }
        
        return self.log.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if self.isViewLoaded{
            guard let tableColumn = tableColumn else { return nil }
            if tableColumn.identifier == NSUserInterfaceItemIdentifier("Status"){
                return self.log[row].status
            }else if tableColumn.identifier == NSUserInterfaceItemIdentifier("Message"){
                return self.log[row].message
            }
        }
        return nil
    }
    
}
