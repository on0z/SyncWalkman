//
//  SyncWalkman+Notification.swift
//  SyncWalkman
//
//  Created by 原園征志 on 2019/03/25.
//  Copyright © 2019 原園征志. All rights reserved.
//

import Foundation

public extension SyncWalkman{
    
    // MARK: - load
    static let didStartEnumTrackFiles: Notification.Name = Notification.Name("didStartEnumerateExistsTrackFiles")
    static let didFoundTrackFile: Notification.Name = Notification.Name("didFoundTrackFile") // path: String
    static let didFinishEnumTrackFiles: Notification.Name = Notification.Name("didFinishEnumerateExistsTrackFiles") // count: Int
    
    static let didStartEnumPlaylistFiles: Notification.Name = Notification.Name("didStartEnumerateExistsPlaylistFiles")
    static let didFoundPlaylistFile: Notification.Name = Notification.Name("didFoundPlaylistFile") // path: String
    static let didFinishEnumPlaylistFiles: Notification.Name = Notification.Name("didFinishEnumerateExistsPlaylistFiles") // count: Int
    
    // MARK: - Send Track
    static let didStartSendTrack: Notification.Name = Notification.Name("didStartSendTrack") // count: Int
    static let didSendTrack: Notification.Name = Notification.Name("didSendTrack") // frompath: String, topath: String, didSendCount: Int, progress: Double
    static let didSkipTrack: Notification.Name = Notification.Name("didSkipTrack") // frompath: String, topath: String, didSendCount: Int, progress: Double
    static let notfoundTrack: Notification.Name = Notification.Name("notfoundTrack") // id: Int didSendCount: Int, progress: Double //Playlistでも兼用
    static let didFinishSendTrack: Notification.Name = Notification.Name("didFinishSendTrack") // copied: Int, skipped: Int
    
    // MARK: - Delete Track
    static let didStartDeleteTrack: Notification.Name = Notification.Name("didStartDeleteTrack") // count: Int
    static let didDeleteTrack: Notification.Name = Notification.Name("didDeleteTrack") // path: String, count: Int, progress: Double
    static let didFinishDeleteTrack: Notification.Name = Notification.Name("didFinishDeleteTrack") // count: Int
    
    // MARK: - Send Playlist
    static let didStartSendPlaylist: Notification.Name = Notification.Name("didStartSendPlaylist") // count: Int
    static let didSendPlaylist: Notification.Name = Notification.Name("didSendPlaylist") // topath: String, didSendCount: Int, progress: Double
    static let didSkipPlaylist: Notification.Name = Notification.Name("didSkipPlaylist") // topath: String, didSendCount: Int, progress: Double
    static let failedSendPlaylist: Notification.Name = Notification.Name("failedSendPlaylist") // topath: String, didSendCount: Int, progress: Double, error: Error
    static let didFinishSendPlaylist: Notification.Name = Notification.Name("didFinishSendPlaylist") // count: Int
    
    // MARK: - Delete Playlist
    static let didStartDeletePlaylist: Notification.Name = Notification.Name("didStartDeletePlaylist") // count: Int
    static let didDeletePlaylist: Notification.Name = Notification.Name("didDeletePlaylist") // path: String, count: Int, progress: Double
    static let didFinishDeletePlaylist: Notification.Name = Notification.Name("didFinishDeletePlaylist") // count: Int
    
    public func addObserver(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateProgress(_:)), name: SyncWalkman.didSendTrack, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateProgress(_:)), name: SyncWalkman.didSkipTrack, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateProgress(_:)), name: SyncWalkman.notfoundTrack, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateProgress(_:)), name: SyncWalkman.didDeleteTrack, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateProgress(_:)), name: SyncWalkman.didSendPlaylist, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateProgress(_:)), name: SyncWalkman.didSkipPlaylist, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateProgress(_:)), name: SyncWalkman.failedSendPlaylist, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateProgress(_:)), name: SyncWalkman.didDeletePlaylist, object: nil)
    }
    
    @objc func updateProgress(_ noti: Notification){
        self.progress = noti.userInfo!["progress"]! as! Double
    }
    
}
