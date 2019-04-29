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
    
    @IBOutlet weak var tableView: NSTableView!
    
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
//            UserDefaults.standard.set(false, forKey: "loadFromXML")
            self.loadITLib()
            self.loadSendTrackList()
            self.loadSendPlaylists()
        }
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
    
    @IBAction func selectHelp(_ sender: NSButton){
        switch sender.tag {
        case 0:
            //iTunesライブラリ
            let alert = NSAlert()
            alert.messageText = "曲/プレイリスト情報はiTunesLibraryから読み込まれています"
            alert.informativeText = "再読み込みをするときは再読み込みボタンを押してください"
            alert.runModal()
        case 1:
            // Walkman path
            let alert = NSAlert()
            alert.messageText = "Walkmanのルートパスを選択"
            alert.informativeText = "Walkmanのルートパスを選択してください．\n例: /Volumes/WALKMAN"
            alert.runModal()
        default:
            break
        }
    }
    
    static let didPushStartButton: Notification.Name = Notification.Name("didPushStartButton")
    
    @IBAction func send(_ sender: NSButton) {
        UserDefaults.standard.set(self.syncWalkman.itl.playlists[self.sendTrackList.indexOfSelectedItem].id, forKey: "sendTrackList")
        
        NotificationCenter.default.post(name: ViewController.didPushStartButton, object: nil)
        
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.didFinish(_:)), name: SyncWalkman.didFinishSendPlaylist, object: nil)
        
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
    
    @objc func didFinish(_ noti: Notification){
        DispatchQueue.main.async {
            if ({ () -> NSAlert in
                    let alert = NSAlert()
                    alert.messageText = "Please run the below code"
                    alert.informativeText = "$ " + self.syncWalkman.playlistUpdateCommand(absoluteCommandPath: false)
                    alert.addButton(withTitle: "Run")
                    alert.addButton(withTitle: "Close")
                    return alert
                }().runModal() == NSApplication.ModalResponse.alertFirstButtonReturn){
                
                let task = Process()
                task.launchPath = "/bin/sh"
                task.arguments = ["-c", self.syncWalkman.playlistUpdateCommand(absoluteCommandPath: true)]
                print(task.arguments![1])
                task.launch()
                task.waitUntilExit()
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
        
        return self.syncWalkman.itl.playlists.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if self.isViewLoaded{
            guard let tableColumn = tableColumn else { return nil }
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
        }
        return nil
    }
    
}

//MARK: TableView delegate
extension ViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        if (tableColumn?.identifier ?? NSUserInterfaceItemIdentifier("")) == NSUserInterfaceItemIdentifier("check"){
            if (object as! Bool){
                self.sendPlaylists.append(self.syncWalkman.itl.playlists[row])
            }else{
                self.sendPlaylists = self.sendPlaylists.filter({$0.id != self.syncWalkman.itl.playlists[row].id})
            }
            UserDefaults.standard.set(self.sendPlaylists.map({$0.id}), forKey: "sendPlaylists")
        }
    }
}

