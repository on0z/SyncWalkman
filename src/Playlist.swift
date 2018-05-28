//
//  Playlist.swift
//  SyncWalkman
//
//  Created by 原園征志 on 2018/05/26.
//  Copyright © 2018年 on0z. All rights reserved.
//

import Foundation

class Playlist{
    
    var id: Int
    var name: String
    var trackIDs: [Int] = []
    
    var sendTargetPath: String?
    
    init(id: Int, name: String, trackIDs: [Int] = []){
        self.id = id
        self.name = name
        self.trackIDs = trackIDs
    }
}
