//
//  SyncWalkman.swift
//  SyncWalkman
//
//  Created by 原園征志 on 2018/05/26.
//  Copyright © 2018年 on0z. All rights reserved.
//

import Foundation

class SyncWalkman{
    
    static let version: String = "0.0.0-b1 (1)\nMIT Lisence  2018 原園 征志"
    static let usage: String = """
Usage:      $ SyncWalkman [-s] [-p] [-u | -o] [-d] [-v] [-w /Volumes/WALKMAN] -f "/path/to/iTunes Library.xml"
        Show Version:
            $ SyncWalkman --version
        Show Help:
            $ SyncWalkman -h
Argments:   -f iTunes XML Path: Path to iTunes Library XML File
            -w Walkman Path:    Path to Walkman root
Options:    -s: send song
            -p: send playlists
            -u: Update
            -o: Override
            -d: Delete songs will not be sent
            -v: Print a line of status
            -n: dry do
"""
    
    let config: SyncWalkmanConfig
    let itl: iTunesLibraryDataStore = iTunesLibraryDataStore.shared
    var existsTrackFiles: [String] = []
    var existsPlaylistFiles: [String] = []
    
    init(argc: Int, argv: [String]){
        self.config = SyncWalkmanConfig(argc: argc, argv: argv)
    }

    func main(){
        self.requiresCheck()
        self.loadXML()
        if self.config.sendTrack{
            self.enumerateExistsTrackFiles()
            let (_, pl) = self.selectSendTracks()
            self.send(tracks: pl)
            if self.config.doDelete{
                self.deleteTracks()
            }
        }
        if self.config.sendPlaylist{
            self.enumerateExistsPlaylistFiles()
            let pls: [(Int, Playlist)] = self.selectSendPlaylists()
            self.send(playlists: pls)
            if self.config.doDelete{
                self.deletePlaylists()
            }
            self.showPlaylistUpdateMessage()
        }
    }
}
