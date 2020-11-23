//
//  SyncWalkman+track.swift
//  SyncWalkman
//
//  Created by 原園征志 on 2018/05/26.
//  Copyright © 2018年 on0z. All rights reserved.
//

import Foundation

extension SyncWalkman {

    
    /// 転送するトラックを選択。for CUI
    ///
    /// - Returns: 転送するトラックと、そのインデックス
    func selectSendTracks() -> (Int, Playlist){
        return SyncWalkman.selectSendTracks(itl: self.itl)
    }
    
    /// 転送するトラックを選択。for CUI
    ///
    /// - Returns: 転送するトラックと、そのインデックス
    static func selectSendTracks(itl: iTunesLibraryDataStore) -> (Int, Playlist){
        Log.shared.stdout("↓転送する曲のプレイリストを選択してください")
        for (i, pl) in itl.playlists.enumerated(){
            Log.shared.stdout("\(i): \(pl.name)")
        }
        
        while true{
            Log.shared.stdout("↑転送する曲のプレイリストを選択してください\n > ", terminator: "")
            guard let s = readLine() else{
                Log.shared.stderr("!Warning: 正しい数字を入力してください")
                continue
            }
            guard let i = Int(s) else{
                Log.shared.stderr("!Warning: 正しい数字を入力してください")
                continue
            }
            guard 0 <= i && i < itl.playlists.count else {
                Log.shared.stderr("!Warning: 正しい数字を入力してください")
                continue
            }
            
            Log.shared.stdout("selected playlist: \(i): \(itl.playlists[i].name)")
            
            if !askOK(){
                Log.shared.stdout("↓転送する曲のプレイリストを選択してください")
                for (i, pl) in itl.playlists.enumerated(){
                    Log.shared.stdout("\(i): \(pl.name)")
                }
                continue
            }
            
            return (i, itl.playlists[i])
        }
    }
    
    static func sha(path: String) -> String?{
        let task = Process()
        task.launchPath = "/usr/bin/shasum"
        task.arguments = ["-a", "1", path]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        let out: Data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let str = String(data: out, encoding: .utf8){
            return String(str.dropLast(str.count - 40))
        }
        return nil
    }
    
    static func modiDateAndSize(path: String) -> (Int, NSInteger)?{
        guard let attr: Dictionary = try? FileManager.default.attributesOfItem(atPath: path) else { return nil }
        guard let moddate: NSDate = attr[.modificationDate] as? NSDate else { return nil }
        guard let size: NSInteger = attr[.size] as? NSInteger else { return nil }
        return (Int(moddate.timeIntervalSinceReferenceDate), size)
    }
    
    public func send(tracks pl: Playlist){
        self.existsTrackFiles = SyncWalkman.send(tracks: pl, from: self.itl, config: self.config, exists: self.existsTrackFiles)
    }
    
    public static func send(tracks pl: Playlist, from itl: iTunesLibraryDataStore, config: SyncWalkmanConfig, exists _existsTrackFiles: [String]) -> [String]{
        NotificationCenter.default.post(name: didStartSendTrack, object: nil, userInfo: ["count" : pl.trackIDs.count])
        var sentCount: Int = 0
        let willSendCount: Int = pl.trackIDs.count
        var existsTrackFiles = _existsTrackFiles
        
        var copied: Int = 0
        var skipped: Int = 0
        
        for tid in pl.trackIDs{
            sentCount += 1
            
            //--- get track
            guard let (_, track): (Int, Track) = try? itl.findTrack(id: tid) else {
                NotificationCenter.default.post(name: notfoundTrack, object: nil, userInfo: ["id" : tid, "didSentCount" : sentCount, "progress" : Double(sentCount)/Double(willSendCount)])
                continue
            }
            track.sendTargetPath = track.sendTargetPath ?? config.walkmanMUSICPath + "/" + track.getRelativePath(itl.mediaFolder)
            //--- update array of existsTrackFiles
            existsTrackFiles = existsTrackFiles.filter({$0 != track.sendTargetPath!})
            //--- send tracks
            switch config.sendMode{
            case .normal:
                if FileManager.default.fileExists(atPath: track.sendTargetPath!){
                    skipped += 1
                    NotificationCenter.default.post(name: didSkipTrack, object: nil, userInfo: ["frompath" : track.path, "topath" : track.sendTargetPath!, "didSendCount" : sentCount, "progress" : Double(sentCount)/Double(willSendCount)])
                    continue
                }
                break
            case .update:
                if FileManager.default.fileExists(atPath: track.sendTargetPath!){
                    if let mds1 = SyncWalkman.modiDateAndSize(path: track.sendTargetPath!), let mds2 = SyncWalkman.modiDateAndSize(path: track.path){
                        if abs(mds1.0 - mds2.0) < 2 && mds1.1 == mds2.1{
                            skipped += 1
                            NotificationCenter.default.post(name: didSkipTrack, object: nil, userInfo: ["frompath" : track.path, "topath" : track.sendTargetPath!, "didSendCount" : sentCount, "progress" : Double(sentCount)/Double(willSendCount)])
                            continue
                        }
                    }
                }
                break
            case .updateHash:
                if FileManager.default.fileExists(atPath: track.sendTargetPath!){
                    if sha(path: track.sendTargetPath!) == sha(path: track.path){
                        skipped += 1
                        NotificationCenter.default.post(name: didSkipTrack, object: nil, userInfo: ["frompath" : track.path, "topath" : track.sendTargetPath!, "didSendCount" : sentCount, "progress" : Double(sentCount)/Double(willSendCount)])
                        continue
                    }
                }
                break
            case .overwrite:
                break
            }
            copied += 1
            NotificationCenter.default.post(name: didSendTrack, object: nil, userInfo: ["frompath" : track.path, "topath" : track.sendTargetPath!, "didSendCount" : sentCount, "progress" : Double(sentCount)/Double(willSendCount)])
            if !config.dryDo{
                let task = Process()
                task.launchPath = "/usr/bin/ditto"
                task.arguments = [track.path, track.sendTargetPath!]
                task.launch()
                task.waitUntilExit()
            }
        }
        NotificationCenter.default.post(name: didFinishSendTrack, object: nil, userInfo: ["copied" : copied, "skipped" : skipped])
        return existsTrackFiles
    }
    
    public func deleteTracks(){
        SyncWalkman.delete(existsTrackFiles: self.existsTrackFiles, config: self.config)
    }
    
    public static func delete(existsTrackFiles: [String], config: SyncWalkmanConfig){
        NotificationCenter.default.post(name: didStartDeleteTrack, object: nil, userInfo: ["count" : existsTrackFiles.count])
        var deletedCount: Int = 0
        for p in existsTrackFiles{
            if !config.dryDo{
                let task = Process()
                task.launchPath = "/bin/rm"
                task.arguments = ["-rf", p]
                task.launch()
                task.waitUntilExit()
            }
            deletedCount += 1
            NotificationCenter.default.post(name: didDeleteTrack, object: nil, userInfo: ["path" : p, "count" : deletedCount, "progress" : Double(deletedCount)/Double(existsTrackFiles.count)])
        }
        NotificationCenter.default.post(name: didFinishDeleteTrack, object: nil, userInfo: ["count" : deletedCount])
    }
}
