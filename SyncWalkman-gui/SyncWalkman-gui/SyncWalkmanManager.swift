//
//  SyncWalkmanManager.swift
//  SyncWalkman-gui
//
//  Created by 原園征志 on 2019/05/17.
//  Copyright © 2019 原園征志. All rights reserved.
//

import Cocoa
import SyncWalkman

class SyncWalkmanManager {

    static let shared: SyncWalkmanManager = SyncWalkmanManager()
    private init(){}
    
    public var syncWalkman: SyncWalkman = SyncWalkman(
        config: SyncWalkmanConfig(
            // ViewController
            xmlPath: "",
            walkmanPath: "",
            sendTrack: false,
            sendPlaylist: false,
            mode: .update,
            doDelete: false,
            // LogViewController
            printStateFound: false,
            printStateSent: true,
            printStateSkipped: false,
            printStateDeleted: true
        )
    )
}
