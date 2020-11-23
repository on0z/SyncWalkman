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
    
    public init(tracks: [Track] = [], playlists: [Playlist] = [], mediaFolder: String = ""){
        self.tracks = tracks
        self.playlists = playlists
        self.mediaFolder = mediaFolder
    }
    
    public internal(set) var tracks: [Track]
    public internal(set) var playlists: [Playlist]
    
    /// MusicやiTunesで「ミュージックのメディアフォルダの場所」と指定されているフォルダ．
    /// ここを音源ファイルのルートディレクトリとし，このディレクトリ以下のディレクトリ構造を保ってWalkmanへ転送することを目標とする．
    /// 始端は/で、終端はフォルダ名です
    public var mediaFolder: String = ""{
        didSet{
            if mediaFolder.hasPrefix("file://"){
                mediaFolder = String(mediaFolder.dropFirst("file://".count))
            }
            if mediaFolder.hasSuffix("/"){
                mediaFolder = String(mediaFolder.dropLast())
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
