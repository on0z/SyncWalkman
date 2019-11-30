//
//  SyncWalkman+load.swift
//  SyncWalkman
//
//  Created by 原園征志 on 2018/05/26.
//  Copyright © 2018年 on0z. All rights reserved.
//

import Foundation
import iTunesLibrary

extension SyncWalkman{
    
    /**
     必要なコマンドが揃っているか確認します
     
     - throws:
         - RequiredError.ditto: !Error: Not found ditto in \"/usr/bin/ditto\"; exit(1)
         - RequiredError.shasum: !Error: Not found shasum in \"/usr/bin/shasum\"; exit(1)
         - RequiredError.rm: !Error: Not found ditto in \"/bin/rm\"; exit(1)
     
     - Version: 1.0
     
     必要なコマンド
     - /usr/bin/ditto
     - /usr/bin/shasum
     - /bin/rm
     */
    public func requiresCheck() throws{
        guard FileManager.default.fileExists(atPath: "/usr/bin/ditto") else {
            throw RequiredError.ditto
        }
        if self.config.sendMode == .updateHash{
            guard FileManager.default.fileExists(atPath: "/usr/bin/shasum") else {
                throw RequiredError.shasum
            }
        }
        guard FileManager.default.fileExists(atPath: "/bin/rm") else {
            throw RequiredError.rm
        }
    }
    
    /**
     iTunes Library XMLを読み込みます。convenience
     
     - parameters:
         - xmlPath: xmlのpathを指定。
     
     - throws:
         - nilParser:   !Error: Couldn't generate XML Parser; exit(2)
         - failedParse: !Error: Couldn't parse XML; exit(2)
     
     - Version: 1.0
     
     **/
    public func loadXML(config: SyncWalkmanConfig? = nil) throws{
        if let config = config{
            self.itl = try SyncWalkman.loadXML(xmlPath: config.itunesXmlPath, config: config)
        }else{
            self.itl = try SyncWalkman.loadXML(xmlPath: self.config.itunesXmlPath, config: self.config)
        }
    }
    
    /**
     iTunes Library XMLを読み込みます
     
     - parameters:
         - xmlPath: xmlのpathを指定。
     
     - throws:
         - nilParser:   !Error: Couldn't generate XML Parser
         - failedParse: !Error: Couldn't parse XML
     
     - Version: 1.0
     
     **/
    public static func loadXML(xmlPath _xmlPath: String, config: SyncWalkmanConfig? = nil) throws -> iTunesLibraryDataStore{
        let xmlPath = URL(fileURLWithPath: _xmlPath)
        guard let parser = XMLParser(contentsOf: xmlPath) else{
            throw XMLLoadError.nilParser
        }
        let delegate = iTunesXMLParserDelegate()
        delegate.config = config
        parser.delegate = delegate
        let succeeded: Bool = parser.parse()
        if succeeded{
            return delegate.itl
        }else{
            throw parser.parserError ?? XMLLoadError.failedParse
        }
    }
    
    /**
     iTunes LibraryをiTunesLibrary.frameworkから読み込みます。
     
     - Version: 1.0
     **/
    public static func loadITLib() throws -> iTunesLibraryDataStore{
        let _itl: ITLibrary = try ITLibrary(apiVersion: "1.0")
        return iTunesLibraryDataStore(
            tracks:
                _itl.allMediaItems.compactMap{ (item) -> Track? in
                    guard item.locationType == .file else { return nil }
                    guard var location = item.location?.absoluteString.removingPercentEncoding else { return nil }
                    if location.hasPrefix("file://"){
                        location = String(location.dropFirst(7))
                    }
                    return Track(id: Int(truncating: item.persistentID), path: location, name: item.title)
                }
            , playlists:
                _itl.allPlaylists.compactMap({ (item) -> Playlist? in
                    return Playlist(
                        id: Int(truncating: item.persistentID),
                        name: item.name,
                        trackIDs: item.items.map({Int(truncating: $0.persistentID)})
                    )
                })
            , musicFolder:
                { (location: String?) -> String in
                    guard var location = location else { return "" }
                    if location.hasPrefix("file://"){
                        location = String(location.dropFirst(7))
                    }
                    if location.hasSuffix("/"){
                        location = String(location.dropLast())
                    }
                    return location
                }(_itl.mediaFolderLocation?.absoluteString.removingPercentEncoding)
        )
    }
    
    /**
     転送済の既存の楽曲ファイルを抽出
     
     自動でSyncWalkman.existsTrackFileに追加
     
     - version: 0.0
     */
    public func enumerateExistsTrackFiles(){
        self.existsTrackFiles = SyncWalkman.enumerateExistsTrackFiles(config: self.config)
    }
    
    /**
     転送済の既存の楽曲ファイルを抽出
     
     自動でSyncWalkman.existsTrackFileに追加
     
     - version: 1.0
     */
    public static func enumerateExistsTrackFiles(config: SyncWalkmanConfig) -> [String]{
        var existsTrackFiles: [String] = []
        
        NotificationCenter.default.post(name: didStartEnumTrackFiles, object: nil, userInfo: nil)
        guard let subpaths = FileManager.default.subpaths(atPath: config.walkmanPath + "/MUSIC/") else {
            return []
        }
        for path in subpaths{
            let ext = (path as NSString).pathExtension.lowercased()
            if ext == "mp3"
                || ext == "m4a"
                || ext == "aiff"
                || ext == "aif"
                || ext == "mp4"
                || ext == "wav"{
                NotificationCenter.default.post(name: didFoundTrackFile, object: nil, userInfo: ["path":config.walkmanPath + "/MUSIC/" + path])
                existsTrackFiles.append(config.walkmanPath + "/MUSIC/" + path)
            }
        }
        NotificationCenter.default.post(name: didFinishEnumTrackFiles, object: nil, userInfo: ["count" : existsTrackFiles.count])
        return existsTrackFiles
    }
    
    public func enumerateExistsPlaylistFiles(){
        self.existsPlaylistFiles = SyncWalkman.enumerateExistsPlaylistFiles(config: self.config)
    }
    
    /**
     転送済の既存のプレイリストファイルを抽出
     
     自動でSyncWalkman.existsPlaylistFilesに追加
     
     - version: 0.0
     */
    public static func enumerateExistsPlaylistFiles(config: SyncWalkmanConfig) -> [String]{
        var existsPlaylistFiles: [String] = []
        
        NotificationCenter.default.post(name: didStartEnumPlaylistFiles, object: nil, userInfo: nil)
        guard let subpaths = FileManager.default.subpaths(atPath: config.walkmanPath + "/MUSIC/") else {
            return []
        }
        for path in subpaths{
            let ext = (path as NSString).pathExtension
            if ext == "m3u"
                || ext == "m3u8"{
                NotificationCenter.default.post(name: didFoundPlaylistFile, object: nil, userInfo: ["path" : config.walkmanPath + "/MUSIC/" + path])
                existsPlaylistFiles.append(config.walkmanPath + "/MUSIC/" + path)
            }
        }
        NotificationCenter.default.post(name: didFinishEnumPlaylistFiles, object: nil, userInfo: ["count" : existsPlaylistFiles.count])
        return existsPlaylistFiles
    }

}
