//
//  Functions.swift
//  SyncWalkman
//
//  Created by 原園征志 on 2018/05/26.
//  Copyright © 2018年 on0z. All rights reserved.
//

import Foundation



func askOK() -> Bool{
    while true{
        Log.shared.stdout("OK? (y/n)\n > ", terminator: "")
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
