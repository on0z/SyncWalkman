//
//  Playlist.swift
//  SyncWalkman
//
//  Created by 原園征志 on 2018/05/26.
//  Copyright © 2018年 on0z. All rights reserved.
//

import Foundation

public class Playlist{
    
    public var id: Int
    public var name: String
    public var parentID: Int?
    public var _indent: Int?  // gui用
    public var trackIDs: [Int] = []
    
    var sendTargetPath: String?
    
    init(id: Int, name: String, parentID: Int?, trackIDs: [Int] = []){
        self.id = id
        self.name = name
        self.parentID = parentID
        self.trackIDs = trackIDs
    }
}
