//
//  SyncWalkmanConfig.swift
//  SyncWalkman
//
//  Created by 原園征志 on 2018/05/26.
//  Copyright © 2018年 on0z. All rights reserved.
//

import Foundation

class SyncWalkmanConfig{

    var itunesXmlPath: String
    var walkmanPath: String

    var sendTrack: Bool = false
    var sendPlaylist: Bool = false
    
    var sendMode: sendMode = .normal
    var doDelete: Bool = false

    var printState: Bool = false
    var dryDo: Bool = false

    init(xmlPath: String, walkmanPath: String, sendTrack: Bool = true, sendPlaylist: Bool = false, mode: sendMode = .normal, doDelete: Bool = false, printState: Bool = false, dryDo: Bool = false){
        self.itunesXmlPath = xmlPath
        self.walkmanPath = walkmanPath
        self.sendTrack = sendTrack
        self.sendPlaylist = sendPlaylist
        self.sendMode = mode
        self.doDelete = doDelete
        self.printState = printState
        self.dryDo = dryDo
    }

    convenience init(argc: Int, argv: [String]){
        // ---
        var optxmlPath: String?
        var optwalkmanPath: String?
        
        var sendTrack: Bool = false
        var sendPlaylist: Bool = false

        var writeMode: sendMode = .normal
        var doDelete: Bool = false

        var printState: Bool = false
        var dryDo: Bool = false
        // ---

        var argfFlag = false
        var argwFlag = false

        for arg in argv.dropFirst(){
            if argfFlag{
                optxmlPath = arg
            }else if argwFlag{
                optwalkmanPath = arg
            }else if arg == "-f"{
                argfFlag = true
                continue
            }else if arg == "-w"{
                argwFlag = true
                continue
            }else if arg == "--version"{
                stdout(SyncWalkman.version)
                exit(0)
            }else if arg == "--help"{
                stdout(SyncWalkman.usage)
                exit(0)
            }else if arg.hasPrefix("-"){
                if arg.contains("s"){ //send song(track)
                    sendTrack = true
                }
                if arg.contains("p"){ //send playlist
                    sendPlaylist = true
                }
                if arg.contains("u"){ //send mode update
                    writeMode = .update
                }
                if arg.contains("o"){ //send mode over write
                    writeMode = .overwrite
                }
                if arg.contains("d"){ //do delete true
                    doDelete = true
                }
                if arg.contains("v"){ //print status
                    printState = true
                }
                if arg.contains("n"){
                    dryDo = true
                }
                if arg.contains("h"){
                    stdout(SyncWalkman.usage)
                    exit(0)
                }
            }else{
                stderr("!Error: Unexpected arguments")
                exit(1)
            }
            argfFlag = false
            argwFlag = false
        }
        
        guard let xmlPath = optxmlPath else{
            stderr("!Error: Requires iTunes Library XML File Path.")
            
            exit(1)
        }
        
        guard xmlPath.hasSuffix(".xml") else{
            stderr("!Error: Requires iTunes Library XML File Path.")
            
            exit(1)
        }
        
        if optwalkmanPath == nil{
            guard let devs = try? FileManager.default.contentsOfDirectory(atPath: "/Volumes") else {
                stderr("!Error: Not found walkman devices.")
                exit(2)
            }
            if devs.count < 2{
                stderr("!Error: Not found walkman devices.")
                exit(1)
            }
            stdout("↓Walkmanのパスが指定されませんでした。Walkmanのパスを選択して下さい。")
            for (i, dev) in devs.enumerated(){
                stdout("\(i): /Volumes/\(dev)")
            }
            while true{
                stdout("↑Walkmanのパスを選択して下さい。\n > ", terminator: "")
                guard let s = readLine() else{
                    stderr("正しい数字を入力してください")
                    continue
                }
                guard let i = Int(s) else{
                    stderr("正しい数字を入力してください")
                    continue
                }
                guard 0 <= i && i < devs.count else {
                    stderr("正しい数字を入力してください")
                    continue
                }
                stdout("selected:", "\"/Volumes/" + devs[i], terminator: "\"\t")
                if !askOK(){
                    stdout("↓Walkmanのパスを選択して下さい。")
                    for (i, dev) in devs.enumerated(){
                        stdout("\(i): /Volumes/\(dev)")
                    }
                    continue
                }
                
                optwalkmanPath = "/Volumes/" + devs[i]
                break
            }
        }
        
        guard let walkmanPath = optwalkmanPath else{
            stderr("!Error: Requires Walkman Path.")
            
            exit(1)
        }
        
        var isDirectory: ObjCBool = true
        stdout(walkmanPath)
        guard FileManager.default.fileExists(atPath: walkmanPath, isDirectory: &isDirectory) else {
            stderr("!Error: Not found walkman device.")
            exit(1)
        }
        
        if sendTrack == false && sendPlaylist == false{
            sendTrack = true
        }

        self.init(xmlPath: xmlPath, walkmanPath: walkmanPath, sendTrack: sendTrack, sendPlaylist: sendPlaylist, mode: writeMode, doDelete: doDelete, printState: printState, dryDo: dryDo)
        _ = sayConfig()
    }

    func sayConfig() -> String{
        let str = """
Imported Config:
    XML Path:           \(self.itunesXmlPath)
    Walkman Directory:  \(self.walkmanPath)
    send songs          \(self.sendTrack)
    send playlists      \(self.sendPlaylist)
    send mode:          \(self.sendMode.rawValue) \(self.sendMode.str)
    do delete:          \(self.doDelete)
    print status        \(self.printState)
    dry do              \(self.dryDo)
"""
        stdout(str)
        return str
    }
}

extension SyncWalkmanConfig{
    enum sendMode: String{
        case normal
        case update
        case overwrite
        
        var str: String{
            get{
                switch self{
                case .normal:
                    return "スキップモード"
                case .update:
                    return "更新モード"
                case .overwrite:
                    return "強制上書きモード"
                }
            }
        }
    }
}
