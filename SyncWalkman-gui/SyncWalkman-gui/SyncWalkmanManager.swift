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

extension Playlist{
    
    var indent: Int{
        if let indent = self._indent{
            return indent
        }else{
            if let parent = self.getParent(){
                self._indent = parent.indent + 1
                return self._indent!
            }else{
                self._indent = 0
                return 0
            }
        }
    }
    
    func getParent() -> Playlist?{
        return SyncWalkmanManager.shared.syncWalkman.itl.playlists.first { (playlist) -> Bool in
            playlist.id == self.parentID
        }
    }
}
