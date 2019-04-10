//
//  Log.swift
//  SyncWalkman
//
//  Created by 原園征志 on 2019/03/24.
//  Copyright © 2019 原園征志. All rights reserved.
//

import Cocoa

public class Log: NSObject {

    public static let shared: Log = Log()
    private override init(){}
    
    public var gui: Bool = false
    
    public var log: String = ""
    
    func stdout(_ str: String..., separator: String = " ", terminator: String = "\n"){
        if self.gui{
            self.log += (str.joined(separator: separator) + terminator)
        }else{
            let stdout = FileHandle.standardOutput
            let data = (str.joined(separator: separator) + terminator).data(using: .utf8)!
            stdout.write(data)
        }
    }
    
    func stdlog(_ str: String..., separator: String = " ", terminator: String = "\n"){
        if self.gui{
            self.log += (str.joined(separator: separator) + terminator)
        }else{
            let stdout = FileHandle.standardOutput
            let data = (str.joined(separator: separator) + terminator).data(using: .utf8)!
            stdout.write(data)
        }
    }
    
    func stderr(_ str: String..., separator: String = " ", terminator: String = "\n"){
        if self.gui{
            self.log += (str.joined(separator: separator) + terminator)
        }else{
            let stdout = FileHandle.standardError
            let data = (str.joined(separator: separator) + terminator).data(using: .utf8)!
            stdout.write(data)
        }
    }
    
    func didSendTrack(){
        
    }
    
    func failedSendTrack(){
        
    }
    
    func didSendPlaylist(){
        
    }
    
    func failedSendPlaylist(){
        
    }
}
