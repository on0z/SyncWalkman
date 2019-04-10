//
//  SyncWalkmanConfig.swift
//  SyncWalkman
//
//  Created by 原園征志 on 2018/05/26.
//  Copyright © 2018年 on0z. All rights reserved.
//

import Foundation

public class SyncWalkmanConfig{
    
    public var guiMode = false

    public var itunesXmlPath: String
    public var walkmanPath: String{ // Walkmanのルートパス
        didSet {
            if walkmanPath.hasSuffix("/"){
                walkmanPath.removeLast()
            }
        }
    }

    public var sendTrack: Bool
    public var sendPlaylist: Bool
    
    public var sendMode: SendMode
    public var doDelete: Bool

    var printStateFound: Bool
    var printStateSent: Bool
    var printStateSkipped: Bool
    var printStateDeleted: Bool
    var printStateFunction: Bool
    var dryDo: Bool

    public init(guiMode: Bool = false,
         xmlPath: String,
         walkmanPath: String,
         sendTrack: Bool,
         sendPlaylist: Bool,
         mode: SendMode,
         doDelete: Bool,
         printStateFound: Bool = false,
         printStateSent: Bool = false,
         printStateSkipped: Bool = false,
         printStateDeleted: Bool = false,
         printStateFunction: Bool = false,
         dryDo: Bool = false){
        self.guiMode = guiMode
        self.itunesXmlPath = xmlPath
        self.walkmanPath = walkmanPath
        if self.walkmanPath.hasSuffix("/"){
            self.walkmanPath.removeLast()
        }
        self.sendTrack = sendTrack
        self.sendPlaylist = sendPlaylist
        self.sendMode = mode
        self.doDelete = doDelete
        self.printStateFound = printStateFound
        self.printStateSent = printStateSent
        self.printStateSkipped = printStateSkipped
        self.printStateDeleted = printStateDeleted
        self.printStateFunction = printStateFunction
        self.dryDo = dryDo
    }

    public convenience init(argc: Int, argv: [String]){
        // ---
        var optxmlPath: String?
        var optwalkmanPath: String?
        
        var sendTrack: Bool = false
        var sendPlaylist: Bool = false

        var writeMode: SendMode = .normal
        var doDelete: Bool = false

        var printStateFound: Bool = false
        var printStateSent: Bool = false
        var printStateSkipped: Bool = false
        var printStateDeleted: Bool = false
        var printStateFunction: Bool = false
        
        var dryDo: Bool = false
        // ---

        var argfFlag = false
        var argwFlag = false
        var argvFlag = false

        for arg in argv.dropFirst(){
            if argfFlag{
                optxmlPath = arg
            }else if argwFlag{
                optwalkmanPath = arg
            }else if argvFlag && arg.hasPrefix("."){
                if arg.contains(".found"){
                    printStateFunction = true
                }
                if arg.contains(".sent"){
                    printStateSent = true
                }
                if arg.contains(".skip"){
                    printStateSkipped = true
                }
                if arg.contains(".del"){
                    printStateDeleted = true
                }
                if arg.contains(".func"){
                    printStateFunction = true
                }
            }else if argvFlag && !arg.hasPrefix("."){
                printStateFound = true
                printStateSent = true
                printStateSkipped = true
                printStateDeleted = true
                printStateFunction = true
            }else if arg == "-f"{
                argfFlag = true
                continue
            }else if arg == "-w"{
                argwFlag = true
                continue
            }else if arg == "-v"{
                if argc == 2{
                    Log.shared.stdout(SyncWalkman.version)
                    exit(0)
                }else{
                    argvFlag = true
                    continue
                }
            }else if arg == "--version"{
                Log.shared.stdout(SyncWalkman.version)
                exit(0)
            }else if arg == "--help"{
                Log.shared.stdout(SyncWalkman.usage)
                exit(0)
            }else if arg == "-h" && argc == 2{
                Log.shared.stdout(SyncWalkman.usage)
                exit(0)
            }else if arg.hasPrefix("-"){
                if arg.contains("s"){ //send song(track)
                    sendTrack = true
                }
                if arg.contains("p"){ //send playlist
                    sendPlaylist = true
                }
                if arg.contains("h"){ //send mode update, compared by hash
                    writeMode = .updateHash
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
                    printStateFound = true
                    printStateSent = true
                    printStateSkipped = true
                    printStateDeleted = true
                    printStateFunction = true
                }
                if arg.contains("n"){
                    dryDo = true
                }
            }else{
                Log.shared.stderr("!Error: Unexpected arguments")
                exit(1)
            }
            argfFlag = false
            argwFlag = false
            argvFlag = false
        }
        
        guard let xmlPath = optxmlPath else{
            Log.shared.stderr("!Error: Requires iTunes Library XML File Path.")
            
            exit(1)
        }
        
        guard xmlPath.hasSuffix(".xml") else{
            Log.shared.stderr("!Error: Requires iTunes Library XML File Path.")
            
            exit(1)
        }
        
        if optwalkmanPath == nil{
            guard let devs = try? FileManager.default.contentsOfDirectory(atPath: "/Volumes") else {
                Log.shared.stderr("!Error: Not found walkman devices.")
                exit(2)
            }
            if devs.count < 2{
                Log.shared.stderr("!Error: Not found walkman devices.")
                exit(1)
            }
            Log.shared.stdout("↓Walkmanのパスが指定されませんでした。Walkmanのパスを選択して下さい。")
            for (i, dev) in devs.enumerated(){
                Log.shared.stdout("\(i): /Volumes/\(dev)")
            }
            while true{
                Log.shared.stdout("↑Walkmanのパスを選択して下さい。\n > ", terminator: "")
                guard let s = readLine() else{
                    Log.shared.stderr("正しい数字を入力してください")
                    continue
                }
                guard let i = Int(s) else{
                    Log.shared.stderr("正しい数字を入力してください")
                    continue
                }
                guard 0 <= i && i < devs.count else {
                    Log.shared.stderr("正しい数字を入力してください")
                    continue
                }
                Log.shared.stdout("selected:", "\"/Volumes/" + devs[i], terminator: "\"\t")
                if !askOK(){
                    Log.shared.stdout("↓Walkmanのパスを選択して下さい。")
                    for (i, dev) in devs.enumerated(){
                        Log.shared.stdout("\(i): /Volumes/\(dev)")
                    }
                    continue
                }
                
                optwalkmanPath = "/Volumes/" + devs[i]
                break
            }
        }
        
        guard let walkmanPath = optwalkmanPath else{
            Log.shared.stderr("!Error: Requires Walkman Path.")
            
            exit(1)
        }
        
        var isDirectory: ObjCBool = true
        Log.shared.stdout(walkmanPath)
        guard FileManager.default.fileExists(atPath: walkmanPath, isDirectory: &isDirectory) else {
            Log.shared.stderr("!Error: Not found walkman device.")
            exit(1)
        }
        
        // sendTrackもsendPlaylistもfalseのとき、sendTrackをtrueにします。
        sendTrack = sendTrack || !sendPlaylist

        self.init(xmlPath: xmlPath, walkmanPath: walkmanPath, sendTrack: sendTrack, sendPlaylist: sendPlaylist, mode: writeMode, doDelete: doDelete, printStateFound: printStateFound, printStateSent: printStateSent, printStateSkipped: printStateSkipped, printStateDeleted: printStateDeleted, printStateFunction: printStateFunction, dryDo: dryDo)
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
    print status
        found           \(self.printStateFound)
        sent            \(self.printStateSent)
        skipped         \(self.printStateSkipped)
        deleted         \(self.printStateDeleted)
        function        \(self.printStateFunction)
    dry do              \(self.dryDo)
"""
        Log.shared.stdout(str)
        return str
    }
}

extension SyncWalkmanConfig{
    public enum SendMode: Int{
        case normal
        case update
        case updateHash
        case overwrite
        
        var str: String{
            get{
                switch self{
                case .normal:
                    return "スキップモード"
                case .update:
                    return "更新モード"
                case .updateHash:
                    return "更新モード(Hash)"
                case .overwrite:
                    return "強制上書きモード"
                }
            }
        }
    }
}
