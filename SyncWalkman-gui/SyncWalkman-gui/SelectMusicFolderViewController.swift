//
//  SelectMusicFolderViewController.swift
//  SyncWalkman-gui
//
//  Created by 原園征志 on 2019/11/28.
//  Copyright © 2019 原園征志. All rights reserved.
//

import Cocoa

class SelectMusicFolderViewController: NSViewController {

    @IBOutlet weak var currentMusicFolderPathLabel: NSTextField!
    @IBOutlet weak var pathTextField: NSTextField!
    @IBAction func selectButton(_ sender: NSButton) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.begin { (response) in
            if response == .OK{
                guard let _path = panel.url?.absoluteString else { return }
                guard var path = _path.removingPercentEncoding else { return }
                if path.hasPrefix("file://"){
                    path = String(path.dropFirst(7))
                }
                print(path)
                SyncWalkmanManager.shared.syncWalkman.itl.musicFolder = path
                self.pathTextField.stringValue = path
                
                self.currentMusicFolderPathLabel.stringValue = SyncWalkmanManager.shared.syncWalkman.itl.musicFolder
            }
        }
    }
    
    @IBAction func reloadMusicFolderPath(_ sender: NSButton) {
        self.currentMusicFolderPathLabel.stringValue = SyncWalkmanManager.shared.syncWalkman.itl.musicFolder
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        self.currentMusicFolderPathLabel.stringValue = SyncWalkmanManager.shared.syncWalkman.itl.musicFolder
    }
    
}

extension SelectMusicFolderViewController: NSTextFieldDelegate{
    
    func controlTextDidChange(_ obj: Notification) {
        SyncWalkmanManager.shared.syncWalkman.itl.musicFolder = self.pathTextField.stringValue
        print(self.pathTextField.stringValue)
        
        self.currentMusicFolderPathLabel.stringValue = SyncWalkmanManager.shared.syncWalkman.itl.musicFolder
    }
    
}
