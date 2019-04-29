//
//  SyncWalkman+playlist.swift
//  SyncWalkman
//
//  Created by 原園征志 on 2018/05/26.
//  Copyright © 2018年 on0z. All rights reserved.
//

import Foundation

extension SyncWalkman{
    
    /**
     転送するプレイリストをユーザーに選択させます。 for CUI
     
     空白区切で数字を入力します。
     範囲指定と除外指定ができます。書式が独特なのでUsageには表示していません。
     
     # 書式:
         1 to 10 -> 1 ~ 10
         1 to 10 exclude 6 -> 1 ~ 10 - 6
         1 to 10 exclude 3 to 6 -> 1 ~ 10 3 - ~ 6
     
     - Version: 1.0
     */
    func selectSendPlaylists() -> [(Int, Playlist)]{
        return SyncWalkman.selectSendPlaylists(itl: self.itl)
    }
    
    /**
     転送するプレイリストをユーザーに選択させます。 for CUI
     
     空白区切で数字を入力します。
     範囲指定と除外指定ができます。書式が独特なのでUsageには表示していません。
     
     # 書式:
     1 to 10 -> 1 ~ 10
     1 to 10 exclude 6 -> 1 ~ 10 - 6
     1 to 10 exclude 3 to 6 -> 1 ~ 10 3 - ~ 6
     
     - Version: 1.0
     */
    static func selectSendPlaylists(itl: iTunesLibraryDataStore) -> [(Int, Playlist)]{
        Log.shared.stdout("↓転送するプレイリストを空白区切で選択してください")
        for (i, pl) in itl.playlists.enumerated(){
            Log.shared.stdout("\(i): \(pl.name)")
        }
        
        while true{
            Log.shared.stdout("↑転送するプレイリストを空白区切で選択してください\n > ", terminator: "")
            guard let s = readLine() else{
                Log.shared.stderr("!Warning: 正しい数字を入力してください")
                continue
            }
            
            var indexes: [Int] = []
            var continueFlag: Bool = false
            var excludeFlag: Bool = false
            for char in s.split(separator: " "){
                if char == "~"{
                    continueFlag = true
                }else if char == "-"{
                    excludeFlag = true
                }else if var n = Int(char){
                    if continueFlag{
                        if var last = indexes.last{
                            if last + 1 > n { (last, n) = (n, last) }
                            if excludeFlag{
                                indexes.removeAll{$0 == last}
//                                indexes = indexes.filter({$0 != last})
                                for m in last+1...n{
                                    indexes.removeAll{$0 == m}
//                                    indexes = indexes.filter({$0 != m})
                                }
                            }else{
                                for m in last+1...n{
                                    indexes.append(m)
                                }
                            }
                        }
                    }else if excludeFlag{
                        indexes.removeAll {$0 == n}
//                        indexes = indexes.filter({$0 != n})
                    }else{
                        indexes.append(n)
                    }
                    continueFlag = false
                    excludeFlag = false
                }
            }
            
            let i: [(Int, Playlist)] = indexes.filter({0 <= $0 && $0 < itl.playlists.count})
                                            .map({(index) -> (Int, Playlist) in (index, itl.playlists[index])})
            
            guard 0 < i.count else {
                Log.shared.stderr("!Warning: 正しい数字を入力してください")
                continue
            }
            
            Log.shared.stdout("selected playlists \(i.count):")
            for n in i.map({$0.0}){
                Log.shared.stdout("\t\(n): \(itl.playlists[n].name)")
            }
            
            if !askOK(){
                Log.shared.stdout("↓転送するプレイリストを空白区切で選択してください")
                for (i, pl) in itl.playlists.enumerated(){
                    Log.shared.stdout("\(i): \(pl.name)")
                }
                continue
            }
            
            return i
        }
    }
    
    public func send(playlists pls: [Playlist]){
        self.existsPlaylistFiles = SyncWalkman.send(playlists: pls, from: self.itl, config: self.config, existsPlaylistFiles: self.existsPlaylistFiles)
    }
    
    public static func send(playlists pls: [Playlist], from itl: iTunesLibraryDataStore, config: SyncWalkmanConfig, existsPlaylistFiles _existsPlaylistFiles: [String] = []) -> [String]{
        NotificationCenter.default.post(name: didStartSendPlaylist, object: nil, userInfo: ["count" : pls.count])
        var sentCount: Int = 0
        let willSendCount: Int = pls.count
        var existsPlaylistFiles: [String] = _existsPlaylistFiles
        
        for pl in pls{
            sentCount += 1
            
            //--- make playlist text
            var playlistText: String = ""
            
            for tid in pl.trackIDs{
                guard let (_, track): (Int, Track) = try? itl.findTrack(id: tid) else {
                    NotificationCenter.default.post(name: notfoundTrack, object: nil, userInfo: ["id" : tid, "didSentCount" : sentCount, "progress" : Double(sentCount)/Double(willSendCount)])
                    continue
                }
                track.sendTargetPath = track.sendTargetPath ?? config.walkmanPath + "/MUSIC/" + track.getRelativePath(itl.musicFolder)
                playlistText += "/MUSIC/" + track.getRelativePath(itl.musicFolder) + "\n"
            }
            
            
            pl.sendTargetPath = pl.sendTargetPath ?? config.walkmanPath + "/MUSIC/" + pl.name + ".m3u"
            //--- update array of existsPlaylistFiles
            existsPlaylistFiles = existsPlaylistFiles.filter({$0 != pl.sendTargetPath!})
            
            //--- send playlists
            switch config.sendMode{
            case .normal:
                if FileManager.default.fileExists(atPath: pl.sendTargetPath!){
                    NotificationCenter.default.post(name: didSkipPlaylist, object: nil, userInfo: ["topath" : pl.sendTargetPath!, "didSendCount" : sentCount, "progress" : Double(sentCount)/Double(willSendCount)])
                    continue
                }
                break
            case .update, .updateHash, .overwrite:
                break
            }
            
            NotificationCenter.default.post(name: didSendPlaylist, object: nil, userInfo: ["topath" : pl.sendTargetPath!, "didSendCount" : sentCount, "progress" : Double(sentCount)/Double(willSendCount)])
            
            if !config.dryDo{
                do{
                    /*var directory: ObjCBool = true
                    if !FileManager.default.fileExists(atPath: config.walkmanPath + "/MUSIC/PLAYLIST", isDirectory: &directory){
                        try FileManager.default.createDirectory(atPath: config.walkmanPath + "/MUSIC/PLAYLIST", withIntermediateDirectories: true, attributes: nil)
                    }*/
                    try playlistText.write(toFile: pl.sendTargetPath!, atomically: true, encoding: .utf8)
                    
                }catch let error{
                    NotificationCenter.default.post(name: failedSendPlaylist, object: nil, userInfo: ["topath" : pl.sendTargetPath!, "didSendCount" : sentCount, "progress" : Double(sentCount)/Double(willSendCount), "error": error])
                }
            }
        }
        NotificationCenter.default.post(name: didFinishSendPlaylist, object: nil, userInfo: ["count" : sentCount])
        return existsPlaylistFiles
    }
    
    public func deletePlaylists(){
        SyncWalkman.delete(existsPlaylistFiles: self.existsPlaylistFiles, config: self.config)
    }
    
    public static func delete(existsPlaylistFiles: [String], config: SyncWalkmanConfig){
        NotificationCenter.default.post(name: didStartDeletePlaylist, object: nil, userInfo: ["count" : existsPlaylistFiles.count])
        var deletedCount: Int = 0
        for p in existsPlaylistFiles{
            if !config.dryDo{
                let task = Process()
                task.launchPath = "/bin/rm"
                task.arguments = ["-rf", p]
                task.launch()
                task.waitUntilExit()
            }
            deletedCount += 1
            NotificationCenter.default.post(name: didDeletePlaylist, object: nil, userInfo: ["path" : p, "count" : deletedCount, "progress" : Double(deletedCount)/Double(existsPlaylistFiles.count)])
        }
        NotificationCenter.default.post(name: didFinishDeletePlaylist, object: nil, userInfo: ["count" : deletedCount])
    }
    
    public func showPlaylistUpdateMessage(gui: Bool = false){
        SyncWalkman.showPlaylistUpdateMessage(config: self.config, gui: gui)
    }
    
    public static func showPlaylistUpdateMessage(config: SyncWalkmanConfig, gui: Bool = false){
        if gui{
            DispatchQueue.main.async {
                if ({ () -> NSAlert in
                    let alert = NSAlert()
                    alert.messageText = "Please run the below code"
                    var informativeText = ""
                    if !FileManager.default.fileExists(atPath: "/usr/local/bin/nkf"){
                        informativeText += "$ brew install nkf\n"
                    }else{
                        alert.addButton(withTitle: "Run")
                    }
                    informativeText += "$ cd \(config.walkmanPath)/MUSIC;for i in *.m3u; do mv \"$i\" \"$i.ori\"; cat \"$i.ori\" | nkf --ic=UTF-8-MAC > \"$i\"; rm -rf \"$i.ori\"; done"
                    alert.informativeText = informativeText
                    alert.addButton(withTitle: "Close")
                    return alert
                    }().runModal() == NSApplication.ModalResponse.alertFirstButtonReturn){
                        let task = Process()
                        task.launchPath = "/bin/sh"
                        task.arguments = ["-c", "cd \(config.walkmanPath)/MUSIC;for i in *.m3u; do mv \"$i\" \"$i.ori\"; cat \"$i.ori\" | /usr/local/bin/nkf --ic=UTF-8-MAC > \"$i\"; rm -rf \"$i.ori\"; done"]
                        task.launch()
                        task.waitUntilExit()
                }
            }
        }else{
            Log.shared.stdout("Please run the below code")
            if !FileManager.default.fileExists(atPath: "/usr/local/bin/nkf"){
                Log.shared.stdout("$ brew install nkf")
            }
            Log.shared.stdout("$ cd \(config.walkmanPath)/MUSIC;for i in *.m3u; do mv \"$i\" \"$i.ori\"; cat \"$i.ori\" | nkf --ic=UTF-8-MAC > \"$i\"; rm -rf \"$i.ori\"; done")
        }
    }
    
    public func playlistUpdateCommand(absoluteCommandPath acp: Bool) -> String{
        return SyncWalkman.playlistUpdateCommand(config: self.config, absoluteCommandPath: acp)
    }
    
    public static func playlistUpdateCommand(config: SyncWalkmanConfig, absoluteCommandPath acp: Bool) -> String{
        if acp{
            let str = { () -> String in
                if !FileManager.default.fileExists(atPath: "/usr/local/bin/nkf"){
                    return "/usr/local/bin/brew install nkf && "
                }
                return ""
            }()
            
            return str + "cd \(config.walkmanPath)/MUSIC; for i in *.m3u; do mv \"$i\" \"$i.ori\"; cat \"$i.ori\" | /usr/local/bin/nkf --ic=UTF-8-MAC > \"$i\"; rm -rf \"$i.ori\"; done"
        }else{
            let str = { () -> String in
                if !FileManager.default.fileExists(atPath: "/usr/local/bin/nkf"){
                    return "brew install nkf && "
                }
                return ""
            }()
            
            return str + "cd \(config.walkmanPath)/MUSIC; for i in *.m3u; do mv \"$i\" \"$i.ori\"; cat \"$i.ori\" | nkf --ic=UTF-8-MAC > \"$i\"; rm -rf \"$i.ori\"; done"
        }
    }
}
