//
//  SyncWalkman.swift
//  SyncWalkman
//
//  Created by 原園征志 on 2018/05/26.
//  Copyright © 2018年 on0z. All rights reserved.
//

import Foundation

public class SyncWalkman: NSObject{
    
    public var productName = ""
    static let version: String = "SyncWalkman Framework version 2.0\nMIT Lisence  2018 原園 征志  (https://github.com/on0z/SyncWalkman)"
    static let usage: String = """
Usage:      $ SyncWalkman [-s] [-p] [-u | -h | -o] [-d] [-v | -v .found|.sent|.skip|.del|.func] [-w /Volumes/WALKMAN] -f "/path/to/iTunes Library.xml"
        Show Version:
            $ SyncWalkman --version
        Show Help:
            $ SyncWalkman -h
Argments:   -f iTunes XML Path: Path to iTunes Library XML File
            -w Walkman Path:    Path to Walkman root
Options:    -s: send song
            -p: send playlists
            -u: send mode Update (compared by modified date and file size)
            -h: send mode Update (compared by hash)
            -o: send mode Overwrite
            -d: Delete songs that are not sent
            -v: Print a line of status
                Individual options for each situation.
                 .found
                 .sent
                 .skip
                 .del
                 .func
            -n: dry do
"""
    
    public var config: SyncWalkmanConfig
    @available(*, introduced: 1.0)
    public var itl: iTunesLibraryDataStore = iTunesLibraryDataStore()
    
    var existsTrackFiles: [String] = []
    var existsPlaylistFiles: [String] = []
    
    @objc public dynamic var progress: Double = 0
    
    @available(*, introduced: 1.0)
    public init(config: SyncWalkmanConfig){
        self.config = config
    }
    
    @available(*, introduced: 1.0)
    convenience public init(argc: Int, argv: [String]){
        self.init(config: SyncWalkmanConfig(argc: argc, argv: argv))
    }
    
    @available(*, introduced: 1.0, deprecated: 2.0)
    public func main_(){
        do{
            try self.requiresCheck()
        } catch let error{
            switch error {
            case RequiredError.ditto:
                Log.shared.stderr(RequiredError.ditto.description())
                exit(1)
            case RequiredError.shasum:
                Log.shared.stderr(RequiredError.shasum.description())
                exit(1)
            case RequiredError.rm:
                Log.shared.stderr(RequiredError.rm.description())
                exit(1)
            default:
                Log.shared.stderr(GeneralError.unknown("Failed to check requires command.").description())
                exit(1)
            }
        }
        do {
            try self.loadXML(config: self.config)
        } catch let error {
            switch error {
            case XMLLoadError.nilParser:
                Log.shared.stderr(XMLLoadError.nilParser.description())
                exit(2)
            case XMLLoadError.failedParse:
                Log.shared.stderr(XMLLoadError.failedParse.description())
                exit(2)
            default:
                Log.shared.stderr(GeneralError.unknown("Failed to load XML.").description())
                exit(2)
            }
        }
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
            let pls: [Playlist] = self.selectSendPlaylists().map{$1}
            self.send(playlists: pls)
            if self.config.doDelete{
                self.deletePlaylists()
            }
            self.showPlaylistUpdateMessage()
        }
    }
    
    @available(*, introduced: 2.0)
    public func main(){
        do{
            try self.requiresCheck()
        } catch let error{
            switch error {
            case RequiredError.ditto:
                print(RequiredError.ditto.description())
                exit(1)
            case RequiredError.shasum:
                print(RequiredError.shasum.description())
                exit(1)
            case RequiredError.rm:
                print(RequiredError.rm.description())
                exit(1)
            default:
                Log.shared.stderr(GeneralError.unknown("Failed to check requires command.").description())
                exit(1)
            }
        }
        do {
            self.itl = try SyncWalkman.loadITLib()
        } catch let error {
            Log.shared.stderr(GeneralError.unknown("Failed to load iTunes Library. \(error)").description())
            exit(2)
        }
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
            let pls: [Playlist] = self.selectSendPlaylists().map{$1}
            self.send(playlists: pls)
            if self.config.doDelete{
                self.deletePlaylists()
            }
            self.showPlaylistUpdateMessage()
        }
    }
}
