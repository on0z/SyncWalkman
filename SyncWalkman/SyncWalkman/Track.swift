//
//  Track.swift
//  SyncWalkman
//
//  Created by 原園征志 on 2018/05/26.
//  Copyright © 2018年 on0z. All rights reserved.
//

import Foundation

public class Track{
    
    public var id: Int
    public var path: String
    public var name: String?
    
    var sendTargetPath: String?
    
    /**
     自身のiTunes Music Folderからの相対パスを返します
     
     正しい iTunesLibraryDataStore.shared.mediaFolder がセット済である必要があります
     */
    func getRelativePath(_ mediaFolder: String) -> String{
        if self.path.hasPrefix(mediaFolder + "/"){
            return String(self.path.dropFirst((mediaFolder + "/").count))
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
    
    init(id: Int, path: String, name: String? = nil){
        self.id = id
        self.path = path
        self.name = name
    }
}
