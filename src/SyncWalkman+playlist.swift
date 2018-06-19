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
     転送するプレイリストをユーザーに選択させます。
     
     空白区切で数字を入力します。
     範囲指定と除外指定ができます。書式が独特なのでUsageには表示していません。
     
     # 書式:
         1 to 10 -> 1 ~ 10
         1 to 10 exclude 6 -> 1 ~ 10 - 6
         1 to 10 exclude 3 to 6 -> 1 ~ 10 3 - ~ 6
     
     - Version: 1.0
     */
    func selectSendPlaylists() -> [(Int, Playlist)]{
        stdout("↓転送するプレイリストを空白区切で選択してください")
        for (i, pl) in self.itl.playlists.enumerated(){
            stdout("\(i): \(pl.name)")
        }
        
        while true{
            stdout("↑転送するプレイリストを空白区切で選択してください\n > ", terminator: "")
            guard let s = readLine() else{
                stderr("!Warning: 正しい数字を入力してください")
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
                                // TODO: in swift4.2, removeAll(where: ) will release.
                                indexes = indexes.filter({$0 != last})
                                for m in last+1...n{
                                    // TODO: in swift4.2, removeAll(where: ) will release.
                                    indexes = indexes.filter({$0 != m})
                                }
                            }else{
                                for m in last+1...n{
                                    indexes.append(m)
                                }
                            }
                        }
                    }else if excludeFlag{
                        // TODO: in swift4.2, removeAll(where: ) will release.
                        indexes = indexes.filter({$0 != n})
                    }else{
                        indexes.append(n)
                    }
                    continueFlag = false
                    excludeFlag = false
                }
            }
            
            let i: [(Int, Playlist)] = indexes.filter({0 <= $0 && $0 < self.itl.playlists.count})
                                            .map({(index) -> (Int, Playlist) in (index, self.itl.playlists[index])})
            
            guard 0 < i.count else {
                stderr("!Warning: 正しい数字を入力してください")
                continue
            }
            
            stdout("selected playlists \(i.count):")
            for n in i.map({$0.0}){
                stdout("\t\(n): \(self.itl.playlists[n].name)")
            }
            
            if !askOK(){
                stdout("↓転送するプレイリストを空白区切で選択してください")
                for (i, pl) in self.itl.playlists.enumerated(){
                    stdout("\(i): \(pl.name)")
                }
                continue
            }
            
            return i
        }
    }
    
    func send(playlists pls: [(Int, Playlist)]){
        stdout("start send playlists")
        var sentCount: Int = 0
        let willSendCount: Int = pls.count
        for (_, pl) in pls{
            sentCount += 1
            
            //--- make playlist text
            var playlistText: String = ""
            
            for tid in pl.trackIDs{
                guard let (_, track): (Int, Track) = try? self.itl.findTrack(id: tid) else {
                    stderr("!Warning: not found Track id = \(tid)\nsent playlists \(Int(Double(sentCount)/Double(willSendCount)*100))% (\(sentCount)/\(willSendCount))", terminator: "")
                    continue
                }
                track.sendTargetPath = track.sendTargetPath ?? self.config.walkmanPath + "/MUSIC/" + track.getRelativePath(self.itl.musicFolder)
                playlistText += "/MUSIC/" + track.getRelativePath(self.itl.musicFolder) + "\n"
            }
            
            
            pl.sendTargetPath = pl.sendTargetPath ?? self.config.walkmanPath + "/MUSIC/" + pl.name + ".m3u"
            //--- update array of existsPlaylistFiles
            self.existsPlaylistFiles = self.existsPlaylistFiles.filter({$0 != pl.sendTargetPath!})
            
            //--- send playlists
            switch self.config.sendMode{
            case .normal:
                if FileManager.default.fileExists(atPath: pl.sendTargetPath!){
                    if self.config.printStateSkipped{
                        stdout("\rskipped:", pl.sendTargetPath!, "\nsent playlists \(Int(Double(sentCount)/Double(willSendCount)*100))% (\(sentCount)/\(willSendCount))", terminator: "")
                    }else{
                        stdout("\rsent playlists \(Int(Double(sentCount)/Double(willSendCount)*100))% (\(sentCount)/\(willSendCount))", terminator: "")
                    }
                    continue
                }
                break
            case .update, .updateHash, .overwrite:
                break
            }
            if self.config.printStateSent{
                stdout("\rsent:", pl.sendTargetPath!)
            }
            
            stdout("\rsent playlists \(Int(Double(sentCount)/Double(willSendCount)*100))% (\(sentCount)/\(willSendCount))", terminator: "")
            if !self.config.dryDo{
                do{
                    var directory: ObjCBool = true
                    if !FileManager.default.fileExists(atPath: self.config.walkmanPath + "/MUSIC/PLAYLIST", isDirectory: &directory){
                        try FileManager.default.createDirectory(atPath: self.config.walkmanPath + "/MUSIC/PLAYLIST", withIntermediateDirectories: true, attributes: nil)
                    }
                    try playlistText.write(toFile: pl.sendTargetPath!, atomically: true, encoding: .utf8)
                }catch let error{
                    stderr("!Warning: failed to send Playlist\(error)")
                }
            }
        }
        stdout("\nfinish send playlists")
    }
    
    func deletePlaylists(){
        stdout("start delete")
        var deletedCount: Int = 0
        for p in self.existsPlaylistFiles{
            if self.config.printStateDeleted{
                stdout("\rdeleted:", p)
            }
            if !self.config.dryDo{
                let task = Process()
                task.launchPath = "/bin/rm"
                task.arguments = ["-rf", p]
                task.launch()
                task.waitUntilExit()
            }
            deletedCount += 1
            stdout("\rdeleted playlists \(Int(Double(deletedCount)/Double(self.existsPlaylistFiles.count)*100))% (\(deletedCount)/\(self.existsPlaylistFiles.count))", terminator: "")
        }
        stdout("\nfinish delete")
    }
    
    func showPlaylistUpdateMessage(){
        stdout("Please run the below code")
        if !FileManager.default.fileExists(atPath: "/usr/local/bin/nkf"){
            stdout("$ brew install nkf")
        }
        stdout("$ cd \(self.config.walkmanPath)/MUSIC;for i in *.m3u; do mv \"$i\" \"$i.ori\"; cat \"$i.ori\" | nkf --ic=UTF-8-MAC > \"$i\"; rm -rf \"$i.ori\"; done")
    }
}
