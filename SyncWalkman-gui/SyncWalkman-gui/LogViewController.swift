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

    @IBOutlet var textView: NSTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        self.textView.string = Log.shared.log
    }
    
}
