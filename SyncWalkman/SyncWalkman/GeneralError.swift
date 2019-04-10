//
//  GeneralError.swift
//  SyncWalkman
//
//  Created by 原園征志 on 2019/03/25.
//  Copyright © 2019 原園征志. All rights reserved.
//

import Foundation

/**
 You should do this.
 
 .unknown:
     Log.shared.stderr(RequiredError.unknown.description())
     exit(1)
 */
public enum GeneralError: Error{
    case unknown(String)
    
    public func description() -> String{
        switch self{
        case .unknown(let message):
            return "!Error: Unknow Error occurred. \(message)"
        }

    }
}
