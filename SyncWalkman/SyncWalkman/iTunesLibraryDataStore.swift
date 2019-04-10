//
//  iTunesLibraryDataStore.swift
//  SyncWalkman
//
//  Created by 原園征志 on 2018/05/26.
//  Copyright © 2018年 on0z. All rights reserved.
//

import Foundation

public class iTunesLibraryDataStore{
    
//    private static let instance: iTunesLibraryDataStore = iTunesLibraryDataStore()
//    open class var shared: iTunesLibraryDataStore{
//        get{
//            return instance
//        }
//    }
    
    public init(tracks: [Track] = [], playlists: [Playlist] = [], musicFolder: String = ""){
        self.tracks = tracks
        self.playlists = playlists
        self.musicFolder = musicFolder
    }
    
    public internal(set) var tracks: [Track]
    public internal(set) var playlists: [Playlist]
    
    /// 始端は/で、終端はフォルダ名です
    var musicFolder: String = ""{
        didSet{
            if musicFolder.hasSuffix("/"){
                musicFolder = String(musicFolder.dropLast())
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
