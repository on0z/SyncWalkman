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

    var sendTrack: Bool
    var sendPlaylist: Bool
    
    var sendMode: sendMode
    var doDelete: Bool

    var printStateFound: Bool
    var printStateSent: Bool
    var printStateSkipped: Bool
    var printStateDeleted: Bool
    var printStateFunction: Bool
    var dryDo: Bool

    init(xmlPath: String,
         walkmanPath: String,
         sendTrack: Bool,
         sendPlaylist: Bool,
         mode: sendMode,
         doDelete: Bool,
         printStateFound: Bool,
         printStateSent: Bool,
         printStateSkipped: Bool,
         printStateDeleted: Bool,
         printStateFunction: Bool,
         dryDo: Bool){
        self.itunesXmlPath = xmlPath
        self.walkmanPath = walkmanPath
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

    convenience init(argc: Int, argv: [String]){
        // ---
        var optxmlPath: String?
        var optwalkmanPath: String?
        
        var sendTrack: Bool = false
        var sendPlaylist: Bool = false

        var writeMode: sendMode = .normal
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
                argvFlag = true
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
                    printStateFound = true
                    printStateSent = true
                    printStateSkipped = true
                    printStateDeleted = true
                    printStateFunction = true
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
            argvFlag = false
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
