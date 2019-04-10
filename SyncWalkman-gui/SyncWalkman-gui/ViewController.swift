//
//  ViewController.swift
//  SyncWalkman-gui
//
//  Created by 原園征志 on 2019/03/11.
//  Copyright © 2019 原園征志. All rights reserved.
//

import Cocoa
import SyncWalkman

class ViewController: NSViewController {
    
    var syncWalkman: SyncWalkman = SyncWalkman(config: SyncWalkmanConfig(
        xmlPath: "",
        walkmanPath: "",
        sendTrack: false,
        sendPlaylist: false,
        mode: .normal,
        doDelete: false))
    
    var observers = [NSKeyValueObservation]()
    
    var log: [(status: String, message: String)] = []
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var logTableViewSource: NSStackView!
    @IBOutlet weak var logTableView: NSTableView!
    
    @IBOutlet weak var itunesXmlPathLabel: NSTextField!
    @IBOutlet weak var itunesXmlSelectButton: NSButton!
    @IBOutlet weak var walkmanPathLabel: NSTextField!
    @IBOutlet weak var isSendTrackButton: NSButton!
    @IBOutlet weak var isSendPlayListButton: NSButton!
    
    @IBOutlet weak var normalRadioButton: NSButton!
    @IBOutlet weak var updateRadioButton: NSButton!
    @IBOutlet weak var updateHashRadioButton: NSButton!
    @IBOutlet weak var overrideRadioButton: NSButton!
    
    @IBOutlet weak var doDeleteButton: NSButton!
    @IBOutlet weak var sendTrackList: NSPopUpButton!
    var sendPlaylists: [Playlist] = []
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    @IBOutlet weak var resultLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.tableView.headerView = nil
        
        do{
            try self.syncWalkman.requiresCheck()
        } catch let error{
            NSAlert(error: error).runModal()
        }
        
        self.loadUserDefault()
        self.setupState()
        self.setupObserver()
        
        self.syncWalkman.productName = "SyncWalkman-gui version 1.0\n"
        //        Log.shared.gui = true
        if !UserDefaults.standard.bool(forKey: "loadFromXML"){
            self.loadITLib()
            self.loadSendTrackList()
            self.loadSendPlaylists()
        }
        
        self.logTableViewSource.isHidden = true
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}

//MARK: IBActions
extension ViewController{
    
    @IBAction func selectFile(_ sender: NSButton) {
        if sender.tag == 0 {
            if self.itunesXmlPathLabel.stringValue == "iTunesライブラリは.itlファイルから読み込まれています"{
                self.loadITLib()
            }else{
                let panel = NSOpenPanel()
                panel.allowsMultipleSelection = false
                panel.canChooseFiles = true
                panel.canChooseDirectories = false
                panel.allowedFileTypes = ["xml"]
                panel.begin { (response) in
                    if response == .OK{
                        guard let _path = panel.url?.absoluteString else { return }
                        guard var path = _path.removingPercentEncoding else { return }
                        if path.hasPrefix("file://"){
                            path = String(path.dropFirst(7))
                        }
                        print(path)
                        self.syncWalkman.config.itunesXmlPath = path
                        UserDefaults.standard.set(path, forKey: "itunesXmlPath")
                        self.itunesXmlPathLabel.stringValue = path
                        
                        // loadXML
                        do{
                            try self.syncWalkman.loadXML()
                            self.tableView.reloadData()
                            self.sendTrackList.removeAllItems()
                            self.sendTrackList.addItems(withTitles: self.syncWalkman.itl.playlists.enumerated().map({"\($0)\t\($1.name)"}))
                            self.loadSendTrackList()
                            self.loadSendPlaylists()
                        } catch let error{
                            switch error {
                            case SyncWalkman.XMLLoadError.nilParser:
                                print(SyncWalkman.XMLLoadError.nilParser.description())
                            case SyncWalkman.XMLLoadError.failedParse:
                                print(SyncWalkman.XMLLoadError.failedParse.description())
                            default:
                                print("!Error: Unknow Error occurred. Failed to load XML. \(error)")
                            }
                        }
                    }
                }
            }
        }else if sender.tag == 1{
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.directoryURL = URL(fileURLWithPath: "/Volumes", isDirectory: true)
            panel.begin { (response) in
                if response == .OK{
                    guard let _path = panel.url?.absoluteString else { return }
                    guard var path = _path.removingPercentEncoding else { return }
                    if path.hasPrefix("file://"){
                        path = String(path.dropFirst(7))
                    }
                    print(path)
                    self.syncWalkman.config.walkmanPath = path
                    UserDefaults.standard.set(self.syncWalkman.config.walkmanPath, forKey: "walkmanPath")
                    self.walkmanPathLabel.stringValue = self.syncWalkman.config.walkmanPath
                }
            }
        }
    }
    
    @IBAction func selectedCheckButton(_ sender: NSButton){
        switch sender.tag{
        case 0:
            self.syncWalkman.config.sendTrack = (sender.state == .on)
            UserDefaults.standard.set(self.syncWalkman.config.sendTrack, forKey: "sendTrack")
        case 1:
            self.syncWalkman.config.sendPlaylist = (sender.state == .on)
            UserDefaults.standard.set(self.syncWalkman.config.sendPlaylist, forKey: "sendPlaylist")
        case 2:
            self.syncWalkman.config.doDelete = (sender.state == .on)
            UserDefaults.standard.set(self.syncWalkman.config.doDelete, forKey: "doDelete")
        default:
            print("🐶 selectedCheckButton(_:) : whatButton?")
        }
    }
    
    @IBAction func selectedRadio(sender: NSButton){
        self.syncWalkman.config.sendMode = SyncWalkmanConfig.SendMode(rawValue: sender.tag % 4) ?? .normal
        UserDefaults.standard.set(self.syncWalkman.config.sendMode.rawValue, forKey: "sendMode")
    }
    
    @IBAction func selectOrDeselectAll(_ sender: NSButton) {
        if self.sendPlaylists.count == self.syncWalkman.itl.playlists.count{
            self.sendPlaylists.removeAll()
        }else{
            self.sendPlaylists = self.syncWalkman.itl.playlists
        }
        self.tableView.reloadData()
    }
    
    @IBAction func showLog(_ sender: NSButton){
        self.logTableViewSource.isHidden = sender.state == .off
    }
    
    @IBAction func send(_ sender: NSButton) {
        UserDefaults.standard.set(self.syncWalkman.itl.playlists[self.sendTrackList.indexOfSelectedItem].id, forKey: "sendTrackList")
        
        self.log.removeAll()
        self.resultLabel.stringValue = ""
        let selectedTrackListIndex = self.sendTrackList.indexOfSelectedItem
        
        DispatchQueue.global(qos: .default).async {
            if self.syncWalkman.config.sendTrack{
                self.syncWalkman.enumerateExistsTrackFiles()
                self.syncWalkman.send(tracks: self.syncWalkman.itl.playlists[selectedTrackListIndex])
                if self.syncWalkman.config.doDelete{
                    self.syncWalkman.deleteTracks()
                }
            }
            if self.syncWalkman.config.sendPlaylist{
                self.syncWalkman.enumerateExistsPlaylistFiles()
                self.syncWalkman.send(playlists: self.sendPlaylists)
                if self.syncWalkman.config.doDelete{
                    self.syncWalkman.deletePlaylists()
                }
                self.syncWalkman.showPlaylistUpdateMessage(gui: true)
            }
        }
    }
    
}

//MARK: setup functions
extension ViewController{
    
    func loadUserDefault(){
        if let itunesXmlPath = UserDefaults.standard.object(forKey: "itunesXmlPath") as? String{
            self.syncWalkman.config.itunesXmlPath = itunesXmlPath
            self.itunesXmlPathLabel.stringValue = itunesXmlPath
        }
        if let walkmanPath = UserDefaults.standard.object(forKey: "walkmanPath") as? String{
            self.syncWalkman.config.walkmanPath = walkmanPath
            self.walkmanPathLabel.stringValue = walkmanPath
        }
        self.syncWalkman.config.sendTrack = UserDefaults.standard.bool(forKey: "sendTrack")
        self.syncWalkman.config.sendPlaylist = UserDefaults.standard.bool(forKey: "sendPlaylist")
        self.syncWalkman.config.sendMode = SyncWalkmanConfig.SendMode(rawValue: UserDefaults.standard.integer(forKey: "sendMode")) ?? .normal
        self.syncWalkman.config.doDelete = UserDefaults.standard.bool(forKey: "doDelete")
    }
    
    func setupState(){
        self.isSendTrackButton.state = self.syncWalkman.config.sendTrack ? .on : .off
        self.isSendPlayListButton.state = self.syncWalkman.config.sendPlaylist ? .on : .off
        switch self.syncWalkman.config.sendMode.rawValue{
        case 1:
            self.updateRadioButton.state = .on
        case 2:
            self.updateHashRadioButton.state = .on
        case 3:
            self.overrideRadioButton.state = .on
        default:
            self.normalRadioButton.state = .on
        }
        self.doDeleteButton.state = self.syncWalkman.config.doDelete ? .on : .off
    }
    
    func setupObserver(){
        self.syncWalkman.addObserver()
        
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
        
        self.observers.append(self.syncWalkman.observe(\.progress, options: .new, changeHandler: { (log, change) in
            DispatchQueue.main.async {
                self.progressIndicator.doubleValue = change.newValue ?? 0
            }
        }))
    }
    
    func loadITLib(){
        do{
            self.syncWalkman.itl = try SyncWalkman.loadITLib()
            self.itunesXmlPathLabel.stringValue = "iTunesライブラリは.itlファイルから読み込まれています"
            self.itunesXmlSelectButton.title = "再読み込み"
            self.tableView.reloadData()
            self.sendTrackList.removeAllItems()
            self.sendTrackList.addItems(withTitles: self.syncWalkman.itl.playlists.enumerated().map({"\($0)\t\($1.name)"}))
        } catch let error{
            //            "!Error: Unknow Error occurred. Failed to load iTunes Library. \(error)"
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }
    
    func loadSendTrackList(){
        let id = UserDefaults.standard.integer(forKey: "sendTrackList")
        for (i, pl) in self.syncWalkman.itl.playlists.enumerated(){
            if pl.id == id{
                self.sendTrackList.selectItem(at: i)
                return
            }
        }
    }
    
    func loadSendPlaylists(){
        guard let ids = UserDefaults.standard.object(forKey: "sendPlaylists") as? [Int] else { return }
        
        self.sendPlaylists = ids.compactMap({ (id) -> Playlist? in
            for pl in self.syncWalkman.itl.playlists{
                if pl.id == id{
                    return pl
                }
            }
            return nil
        })
    }
    
}

//MARK: noti receive
extension ViewController{
    
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
extension ViewController: NSTableViewDataSource{
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if !self.isViewLoaded{
            return 0
        }
        
        switch tableView {
        case self.tableView:
            return self.syncWalkman.itl.playlists.count
        case self.logTableView:
            return self.log.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if self.isViewLoaded{
            guard let tableColumn = tableColumn else { return nil }
            if tableView == self.tableView{
                if tableColumn.identifier == NSUserInterfaceItemIdentifier("check"){
                    for pl in self.sendPlaylists{
                        if pl.id == self.syncWalkman.itl.playlists[row].id{
                            return true
                        }
                    }
                    return false
                }else if tableColumn.identifier == NSUserInterfaceItemIdentifier("title"){
                    return self.syncWalkman.itl.playlists[row].name
                }
            }else if tableView == self.logTableView{
                if tableColumn.identifier == NSUserInterfaceItemIdentifier("Status"){
                    return self.log[row].status
                }else if tableColumn.identifier == NSUserInterfaceItemIdentifier("Message"){
                    return self.log[row].message
                }
            }
        }
        return nil
    }
    
}

//MARK: TableView delegate
extension ViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        if self.tableView == self.tableView && (tableColumn?.identifier ?? NSUserInterfaceItemIdentifier("")) == NSUserInterfaceItemIdentifier("check"){
            if (object as! Bool){
                self.sendPlaylists.append(self.syncWalkman.itl.playlists[row])
            }else{
                self.sendPlaylists = self.sendPlaylists.filter({$0.id != self.syncWalkman.itl.playlists[row].id})
            }
            UserDefaults.standard.set(self.sendPlaylists.map({$0.id}), forKey: "sendPlaylists")
        }
    }
}

