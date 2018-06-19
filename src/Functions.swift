//
//  Functions.swift
//  SyncWalkman
//
//  Created by 原園征志 on 2018/05/26.
//  Copyright © 2018年 on0z. All rights reserved.
//

import Foundation

func stdout(_ str: String..., separator: String = " ", terminator: String = "\n"){
    let stdout = FileHandle.standardOutput
    let data = (str.joined(separator: separator) + terminator).data(using: .utf8)!
    stdout.write(data)
}

func stdlog(_ str: String..., separator: String = " ", terminator: String = "\n"){
    let stdout = FileHandle.standardOutput
    let data = (str.joined(separator: separator) + terminator).data(using: .utf8)!
    stdout.write(data)
}

func stderr(_ str: String..., separator: String = " ", terminator: String = "\n"){
    let stdout = FileHandle.standardError
    let data = (str.joined(separator: separator) + terminator).data(using: .utf8)!
    stdout.write(data)
}

func askOK() -> Bool{
    while true{
        stdout("OK? (y/n)\n > ", terminator: "")
        guard let s = readLine() else{
            continue
        }
        if s == "y"{
            return true
        }else if s == "n"{
            return false
        }
    }
}
