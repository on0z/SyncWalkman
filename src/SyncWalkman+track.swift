//
//  SyncWalkman+track.swift
//  SyncWalkman
//
//  Created by 原園征志 on 2018/05/26.
//  Copyright © 2018年 on0z. All rights reserved.
//

import Foundation

extension SyncWalkman {

    func selectSendTracks() -> (Int, Playlist){
        stdout("↓転送する曲のプレイリストを選択してください")
        for (i, pl) in self.itl.playlists.enumerated(){
            stdout("\(i): \(pl.name)")
        }
        
        while true{
            stdout("↑転送する曲のプレイリストを選択してください\n > ", terminator: "")
            guard let s = readLine() else{
                stderr("!Warning: 正しい数字を入力してください")
                continue
            }
            guard let i = Int(s) else{
                stderr("!Warning: 正しい数字を入力してください")
                continue
            }
            guard 0 <= i && i < self.itl.playlists.count else {
                stderr("!Warning: 正しい数字を入力してください")
                continue
            }
            
            stdout("selected playlist: \(i): \(self.itl.playlists[i].name)")
            
            if !askOK(){
                stdout("↓転送する曲のプレイリストを選択してください")
                for (i, pl) in self.itl.playlists.enumerated(){
                    stdout("\(i): \(pl.name)")
                }
                continue
            }
            
            return (i, self.itl.playlists[i])
        }
    }
    
    func sha(path: String) -> String?{
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
    
    func modiDateAndSize(path: String) -> (Int, NSInteger)?{
        guard let attr: Dictionary = try? FileManager.default.attributesOfItem(atPath: path) else { return nil }
        guard let moddate: NSDate = attr[.modificationDate] as? NSDate else { return nil }
        guard let size: NSInteger = attr[.size] as? NSInteger else { return nil }
        return (Int(moddate.timeIntervalSinceReferenceDate), size)
    }
    
    func send(tracks pl: Playlist){
        stdout("start send tracks")
        var sentCount: Int = 0
        let willSendCount: Int = pl.trackIDs.count
        
        var copied: Int = 0
        var skipped: Int = 0
        
        for tid in pl.trackIDs{
            sentCount += 1
            
            //--- get track
            guard let (_, track): (Int, Track) = try? self.itl.findTrack(id: tid) else {
                stderr("\r!Warning: other error. not found Track. id = \(tid)\nsent Songs \(Double(sentCount)/Double(willSendCount))% (\(sentCount)/\(willSendCount))", terminator: "")
                continue
            }
            track.sendTargetPath = track.sendTargetPath ?? self.config.walkmanPath + "/MUSIC/" + track.getRelativePath(self.itl.musicFolder)
            //--- update array of existsTrackFiles
            self.existsTrackFiles = self.existsTrackFiles.filter({$0 != track.sendTargetPath!})
            //--- send tracks
            switch self.config.sendMode{
            case .normal:
                if FileManager.default.fileExists(atPath: track.sendTargetPath!){
                    skipped += 1
                    stdout("\r", terminator: "")
                    if self.config.printStateSkipped{
                        stdout("skipped:", track.path, "\n", terminator: "")
                    }
                    stdout("sent Songs \(Int(Double(sentCount)/Double(willSendCount)*100))% (\(sentCount)/\(willSendCount))", terminator: "")
                    continue
                }
                break
            case .update:
                if FileManager.default.fileExists(atPath: track.sendTargetPath!){
                    if let mds1 = modiDateAndSize(path: track.sendTargetPath!), let mds2 = modiDateAndSize(path: track.path){
                        if abs(mds1.0 - mds2.0) < 2 && mds1.1 == mds2.1{
                            skipped += 1
                            stdout("\r", terminator: "")
                            if self.config.printStateSkipped{
                                stdout("skipped:", track.path, "\n", terminator: "")
                            }
                            stdout("sent Songs \(Int(Double(sentCount)/Double(willSendCount)*100))% (\(sentCount)/\(willSendCount))", terminator: "")
                            continue
                        }
                    }
                }
                break
            case .updateHash:
                if FileManager.default.fileExists(atPath: track.sendTargetPath!){
                    if sha(path: track.sendTargetPath!) == sha(path: track.path){
                        skipped += 1
                        stdout("\r", terminator: "")
                        if self.config.printStateSkipped{
                            stdout("skipped:", track.path, "\n", terminator: "")
                        }
                        stdout("sent Songs \(Int(Double(sentCount)/Double(willSendCount)*100))% (\(sentCount)/\(willSendCount))", terminator: "")
                        continue
                    }
                }
                break
            case .overwrite:
                break
            }
            copied += 1
            if self.config.printStateSent{
                stdout("\rsent:", track.path, "\nto:", track.sendTargetPath!)
            }
            stdout("\rsent Songs \(Int(Double(sentCount)/Double(willSendCount)*100))% (\(sentCount)/\(willSendCount))", terminator: "")
            if !self.config.dryDo{
                let task = Process()
                task.launchPath = "/usr/bin/ditto"
                task.arguments = [track.path, track.sendTargetPath!]
                task.launch()
                task.waitUntilExit()
            }
        }
        stdout("\nfinished send tracks")
        stdout("copied \(copied), skipped \(skipped)")
    }
    
    func deleteTracks(){
        stdout("start delete")
        var deletedCount: Int = 0
        for p in self.existsTrackFiles{
            if !self.config.dryDo{
                let task = Process()
                task.launchPath = "/bin/rm"
                task.arguments = ["-rf", p]
                task.launch()
                task.waitUntilExit()
            }
            deletedCount += 1
            if self.config.printStateDeleted{
                stdout("\rdeleted:", p, "\ndeleted songs \(Int(Double(deletedCount)/Double(self.existsTrackFiles.count)*100))% (\(deletedCount)/\(self.existsTrackFiles.count))", terminator: "")
            }else{
                stdout("\rdeleted songs \(Int(Double(deletedCount)/Double(self.existsTrackFiles.count)*100))% (\(deletedCount)/\(self.existsTrackFiles.count))", terminator: "")
            }
        }
        stdout("\nfinish delete")
    }
}
