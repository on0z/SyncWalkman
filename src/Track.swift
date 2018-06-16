//
//  Track.swift
//  SyncWalkman
//
//  Created by 原園征志 on 2018/05/26.
//  Copyright © 2018年 on0z. All rights reserved.
//

import Foundation

class Track{
    
    var id: Int
    var path: String
    
    var name: String?
    
    var sendTargetPath: String?
    
    /**
     自身のiTunes Music Folderからの相対パスを返します
     
     正しい iTunesLibraryDataStore.shared.musicFolder がセット済である必要があります
     */
    func getRelativePath(_ musicFolder: String) -> String{
        if self.path.hasPrefix(musicFolder + "/" + "Music/"){
            return String(self.path.dropFirst((musicFolder + "/" + "Music/").count))
        } else {
            return (self.path as NSString).lastPathComponent
        }
    }
    
    @available(*, unavailable)
    var relativePath: String{
        get{
            return ""
        }
    }
    
    init(id: Int, path: String){
        self.id = id
        self.path = path
    }
}
