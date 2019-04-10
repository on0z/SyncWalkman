//
//  main.swift
//  SyncWalkman
//
//  Created by 原園征志 on 2018/05/26.
//  Copyright © 2018年 on0z. All rights reserved.
//

import Foundation
import SyncWalkman

func main(argc: Int, argv: [String]) -> Int{
    let syncWalkman = SyncWalkman(argc: argc, argv: argv)
    syncWalkman.main()
    return 0
}

_ = main(argc: Int(CommandLine.argc), argv: CommandLine.arguments)
