//
//  iTunesLibraryDataStore.swift
//  SyncWalkman
//
//  Created by 原園征志 on 2018/05/26.
//  Copyright © 2018年 on0z. All rights reserved.
//

import Foundation

class iTunesLibraryDataStore{
    
//    private static let instance: iTunesLibraryDataStore = iTunesLibraryDataStore()
//    open class var shared: iTunesLibraryDataStore{
//        get{
//            return instance
//        }
//    }
    
    var tracks: [Track] = []
    var playlists: [Playlist] = []
    
    private var _musicFolder: String = ""
    /// 始端は/で、終端はフォルダ名です
    var musicFolder: String{
        get{
            return _musicFolder
        }
        set{
            _musicFolder = newValue
            if _musicFolder.hasSuffix("/"){
                _musicFolder = String(_musicFolder.dropLast())
            }
        }
    }
    
    func findTrack(id: Int) throws -> (Int, Track){
        for (i, t) in self.tracks.enumerated(){
            if t.id == id{
                return (i, t)
            }
        }
        throw findError.notfound(id: id)
    }
    
    enum findError: Error{
        case notfound(id: Int)
    }
}
