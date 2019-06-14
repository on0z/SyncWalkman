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
        
        do{
            try SyncWalkmanManager.shared.syncWalkman.requiresCheck()
        } catch let error{
            NSAlert(error: error).runModal()
        }
        
        self.loadUserDefault()
        self.setupState()
        self.setupObserver()
        
        SyncWalkmanManager.shared.syncWalkman.productName = "SyncWalkman-gui version 3.0\n"
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
                self.loadSendTrackList()
                self.loadSendPlaylists()
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
                        SyncWalkmanManager.shared.syncWalkman.config.itunesXmlPath = path
                        UserDefaults.standard.set(path, forKey: "itunesXmlPath")
                        self.itunesXmlPathLabel.stringValue = path
                        
                        // loadXML
                        do{
                            try SyncWalkmanManager.shared.syncWalkman.loadXML()
                            self.tableView.reloadData()
                            self.tableView.sizeToFit()
                            self.sendTrackList.removeAllItems()
                            self.sendTrackList.addItems(withTitles: SyncWalkmanManager.shared.syncWalkman.itl.playlists.enumerated().map({"\($0)\t\($1.name)"}))
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
                    SyncWalkmanManager.shared.syncWalkman.config.walkmanPath = path
                    UserDefaults.standard.set(SyncWalkmanManager.shared.syncWalkman.config.walkmanPath, forKey: "walkmanPath")
                    self.walkmanPathLabel.stringValue = SyncWalkmanManager.shared.syncWalkman.config.walkmanPath
                }
            }
        }
    }
    
    @IBAction func selectedCheckButton(_ sender: NSButton){
        switch sender.tag{
        case 0:
            SyncWalkmanManager.shared.syncWalkman.config.sendTrack = (sender.state == .on)
            UserDefaults.standard.set(SyncWalkmanManager.shared.syncWalkman.config.sendTrack, forKey: "sendTrack")
        case 1:
            SyncWalkmanManager.shared.syncWalkman.config.sendPlaylist = (sender.state == .on)
            UserDefaults.standard.set(SyncWalkmanManager.shared.syncWalkman.config.sendPlaylist, forKey: "sendPlaylist")
        case 2:
            SyncWalkmanManager.shared.syncWalkman.config.doDelete = (sender.state == .on)
            UserDefaults.standard.set(SyncWalkmanManager.shared.syncWalkman.config.doDelete, forKey: "doDelete")
        default:
            print("🐶 selectedCheckButton(_:) : whatButton?")
        }
    }
    
    @IBAction func selectedRadio(sender: NSButton){
        SyncWalkmanManager.shared.syncWalkman.config.sendMode = SyncWalkmanConfig.SendMode(rawValue: sender.tag % 4) ?? .normal
        UserDefaults.standard.set(SyncWalkmanManager.shared.syncWalkman.config.sendMode.rawValue, forKey: "sendMode")
    }
    
    @IBAction func selectOrDeselectAll(_ sender: NSButton) {
        if self.sendPlaylists.count == SyncWalkmanManager.shared.syncWalkman.itl.playlists.count{
            self.sendPlaylists.removeAll()
        }else{
            self.sendPlaylists = SyncWalkmanManager.shared.syncWalkman.itl.playlists
        }
        self.tableView.reloadData()
        self.tableView.sizeToFit()
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
    static let didFinishAllProcess: Notification.Name = Notification.Name("didFinishAllProcess")
    
    @IBAction func send(_ sender: NSButton) {
        UserDefaults.standard.set(SyncWalkmanManager.shared.syncWalkman.itl.playlists[self.sendTrackList.indexOfSelectedItem].id, forKey: "sendTrackList")
        
        NotificationCenter.default.post(name: ViewController.didPushStartButton, object: nil)
        
        let selectedTrackListIndex = self.sendTrackList.indexOfSelectedItem
        
        DispatchQueue.global(qos: .default).async {
            if SyncWalkmanManager.shared.syncWalkman.config.sendTrack{
                SyncWalkmanManager.shared.syncWalkman.enumerateExistsTrackFiles()
                SyncWalkmanManager.shared.syncWalkman.send(tracks: SyncWalkmanManager.shared.syncWalkman.itl.playlists[selectedTrackListIndex])
                if SyncWalkmanManager.shared.syncWalkman.config.doDelete{
                    SyncWalkmanManager.shared.syncWalkman.deleteTracks()
                }
            }
            if SyncWalkmanManager.shared.syncWalkman.config.sendPlaylist{
                SyncWalkmanManager.shared.syncWalkman.enumerateExistsPlaylistFiles()
                SyncWalkmanManager.shared.syncWalkman.send(playlists: self.sendPlaylists)
                if SyncWalkmanManager.shared.syncWalkman.config.doDelete{
                    SyncWalkmanManager.shared.syncWalkman.deletePlaylists()
                }
            }
            NotificationCenter.default.post(name: ViewController.didFinishAllProcess, object: nil)
        }
    }
    
}

//MARK: setup functions
extension ViewController{
    
    func loadUserDefault(){
        if let itunesXmlPath = UserDefaults.standard.object(forKey: "itunesXmlPath") as? String{
            SyncWalkmanManager.shared.syncWalkman.config.itunesXmlPath = itunesXmlPath
            self.itunesXmlPathLabel.stringValue = itunesXmlPath
        }
        if let walkmanPath = UserDefaults.standard.object(forKey: "walkmanPath") as? String{
            SyncWalkmanManager.shared.syncWalkman.config.walkmanPath = walkmanPath
            self.walkmanPathLabel.stringValue = walkmanPath
        }
        SyncWalkmanManager.shared.syncWalkman.config.sendTrack = UserDefaults.standard.bool(forKey: "sendTrack")
        SyncWalkmanManager.shared.syncWalkman.config.sendPlaylist = UserDefaults.standard.bool(forKey: "sendPlaylist")
        SyncWalkmanManager.shared.syncWalkman.config.sendMode = SyncWalkmanConfig.SendMode(rawValue: UserDefaults.standard.integer(forKey: "sendMode")) ?? .normal
        SyncWalkmanManager.shared.syncWalkman.config.doDelete = UserDefaults.standard.bool(forKey: "doDelete")
    }
    
    func setupState(){
        self.isSendTrackButton.state = SyncWalkmanManager.shared.syncWalkman.config.sendTrack ? .on : .off
        self.isSendPlayListButton.state = SyncWalkmanManager.shared.syncWalkman.config.sendPlaylist ? .on : .off
        switch SyncWalkmanManager.shared.syncWalkman.config.sendMode.rawValue{
        case 1:
            self.updateRadioButton.state = .on
        case 2:
            self.updateHashRadioButton.state = .on
        case 3:
            self.overrideRadioButton.state = .on
        default:
            self.normalRadioButton.state = .on
        }
        self.doDeleteButton.state = SyncWalkmanManager.shared.syncWalkman.config.doDelete ? .on : .off
    }
    
    func setupObserver(){
        SyncWalkmanManager.shared.syncWalkman.addObserver()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.didFinish(_:)), name: SyncWalkman.didFinishSendPlaylist, object: nil)
        
        self.observers.append(SyncWalkmanManager.shared.syncWalkman.observe(\.progress, options: .new, changeHandler: { (log, change) in
            DispatchQueue.main.async {
                self.progressIndicator.doubleValue = change.newValue ?? 0
            }
        }))
    }
    
    func loadITLib(){
        do{
            SyncWalkmanManager.shared.syncWalkman.itl = try SyncWalkman.loadITLib()
            self.itunesXmlPathLabel.stringValue = "iTunesライブラリは.itlファイルから読み込まれています"
            self.itunesXmlSelectButton.title = "再読み込み"
            self.tableView.reloadData()
            self.tableView.sizeToFit()
            self.sendTrackList.removeAllItems()
            self.sendTrackList.addItems(withTitles: SyncWalkmanManager.shared.syncWalkman.itl.playlists.enumerated().map({"\($0)\t\($1.name)\t - \($1.trackIDs.count)曲"}))
        } catch let error{
            //            "!Error: Unknow Error occurred. Failed to load iTunes Library. \(error)"
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }
    
    func loadSendTrackList(){
        let id = UserDefaults.standard.integer(forKey: "sendTrackList")
        for (i, pl) in SyncWalkmanManager.shared.syncWalkman.itl.playlists.enumerated(){
            if pl.id == id{
                self.sendTrackList.selectItem(at: i)
                return
            }
        }
    }
    
    func loadSendPlaylists(){
        guard let ids = UserDefaults.standard.object(forKey: "sendPlaylists") as? [Int] else { return }
        
        self.sendPlaylists = ids.compactMap({ (id) -> Playlist? in
            for pl in SyncWalkmanManager.shared.syncWalkman.itl.playlists{
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
                    alert.informativeText = "$ " + SyncWalkmanManager.shared.syncWalkman.playlistUpdateCommand(absoluteCommandPath: false)
                    alert.addButton(withTitle: "Run")
                    alert.addButton(withTitle: "Close")
                    return alert
                }().runModal() == NSApplication.ModalResponse.alertFirstButtonReturn){
                    DispatchQueue.global().async {
                        let task = Process()
                        task.launchPath = "/bin/sh"
                        task.arguments = ["-c", SyncWalkmanManager.shared.syncWalkman.playlistUpdateCommand(absoluteCommandPath: true)]
                        task.launch()
                        task.waitUntilExit()
                    }
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
        
        return SyncWalkmanManager.shared.syncWalkman.itl.playlists.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if self.isViewLoaded{
            guard let tableColumn = tableColumn else { return nil }
            if tableColumn.identifier == NSUserInterfaceItemIdentifier("check"){
                for pl in self.sendPlaylists{
                    if pl.id == SyncWalkmanManager.shared.syncWalkman.itl.playlists[row].id{
                        return true
                    }
                }
                return false
            }else if tableColumn.identifier == NSUserInterfaceItemIdentifier("title"){
                return SyncWalkmanManager.shared.syncWalkman.itl.playlists[row].name
            }else if tableColumn.identifier == NSUserInterfaceItemIdentifier("SongsCount"){
                return "\(SyncWalkmanManager.shared.syncWalkman.itl.playlists[row].trackIDs.count)曲"
            }
        }
        return nil
    }
    
}

//MARK: TableView delegate
extension ViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        if (tableColumn?.identifier ?? NSUserInterfaceItemIdentifier("")) == NSUserInterfaceItemIdentifier("check"){
            let selectedRowIndexes = tableView.selectedRowIndexes
            for index in selectedRowIndexes{
                self.sendPlaylists = self.sendPlaylists.filter({$0.id != SyncWalkmanManager.shared.syncWalkman.itl.playlists[index].id})
                if (object as! Bool){
                    self.sendPlaylists.append(SyncWalkmanManager.shared.syncWalkman.itl.playlists[index])
                }
            }
            tableView.reloadData()
//            tableView.selectRowIndexes(<#T##indexes: IndexSet##IndexSet#>, byExtendingSelection: <#T##Bool#>)
            UserDefaults.standard.set(self.sendPlaylists.map({$0.id}), forKey: "sendPlaylists")
        }
    }
}

