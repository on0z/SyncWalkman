//
//  SyncWalkman+load.swift
//  SyncWalkman
//
//  Created by 原園征志 on 2018/05/26.
//  Copyright © 2018年 on0z. All rights reserved.
//

import Foundation

extension SyncWalkman{
    
    /**
     必要なコマンドが揃っているか確認します
     
     - Version: 0.1
     
     必要なコマンド
     - /usr/bin/ditto
     - /usr/bin/shasum
     - /bin/rm
     */
    func requiresCheck(){
        guard FileManager.default.fileExists(atPath: "/usr/bin/ditto") else {
            stderr("!Error: Not found ditto in \"/usr/bin/ditto\"")
            exit(1)
        }
        guard FileManager.default.fileExists(atPath: "/usr/bin/shasum") else {
            stderr("!Error: Not found shasum in \"/usr/bin/shasum\"")
            exit(1)
        }
        guard FileManager.default.fileExists(atPath: "/bin/rm") else {
            stderr("!Error: Not found ditto in \"/bin/rm\"")
            exit(1)
        }
    }
    
    /**
     iTunes Library XMLを読み込みます
     
     - parameters:
         - xmlPath: xmlのpathを指定。nilならself.config.itunesXmlPathを読む。defaultでnil
     
     - Version: 0.0
     */
    func loadXML(xmlPath _xmlPath: String? = nil){
        
        let xmlPath = URL(fileURLWithPath: _xmlPath ?? self.config.itunesXmlPath)
        guard let parser = XMLParser(contentsOf: xmlPath) else{
            stderr("!Error: Couldn't generate XML Parser")
            exit(2)
        }
        let delegate = iTunesXMLParserDelegate()
        delegate.config = self.config
        parser.delegate = delegate
        let succeeded: Bool = parser.parse()
        if succeeded{
            self.itl = delegate.itl
        }else{
            stderr("!Error: Couldn't parse XML")
            exit(2)
        }
    }
    
    /**
     転送済の既存の楽曲ファイルを抽出
     
     自動でSyncWalkman.existsTrackFileに追加
     
     - version: 0.0
     */
    func enumerateExistsTrackFiles(){
        if self.config.printStateFunction{
            stdout("start enumerate exists song files")
        }
        guard let subpaths = FileManager.default.subpaths(atPath: self.config.walkmanPath + "/MUSIC/") else {
            stdout("!Warning: notfound any song files")
            return
        }
        for path in subpaths{
            let ext = (path as NSString).pathExtension
            if ext == "mp3"
                || ext == "m4a"
                || ext == "aiff"
                || ext == "aif"
                || ext == "mp4"
                || ext == "flac"{
                if self.config.printStateFound{
                    stdout("found:", self.config.walkmanPath + "/MUSIC/" + path)
                }
                self.existsTrackFiles.append(self.config.walkmanPath + "/MUSIC/" + path)
            }
        }
        stdout("found: \(self.existsTrackFiles.count)")
        if self.config.printStateFunction{
            stdout("finish enumerate exists song files")
        }
    }
    
    /**
     転送済の既存のプレイリストファイルを抽出
     
     自動でSyncWalkman.existsPlaylistFilesに追加
     
     - version: 0.0
     */
    func enumerateExistsPlaylistFiles(){
        if self.config.printStateFunction{
            stdout("start enumerate exists playlist files")
        }
        guard let subpaths = FileManager.default.subpaths(atPath: self.config.walkmanPath + "/MUSIC/") else {
            stdout("!Warning: notfound any playlist files")
            return
        }
        for path in subpaths{
            let ext = (path as NSString).pathExtension
            if ext == "m3u"
                || ext == "m3u8"{
                if self.config.printStateFound{
                    stdout("found:", self.config.walkmanPath + "/MUSIC/" + path)
                }
                self.existsPlaylistFiles.append(self.config.walkmanPath + "/MUSIC/" + path)
            }
        }
        stdout("found: \(self.existsPlaylistFiles.count)")
        if self.config.printStateFunction{
            stdout("finish enumerate exists playlist files")
        }
    }

}
