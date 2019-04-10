//
//  SyncWalkman+Error.swift
//  SyncWalkman
//
//  Created by 原園征志 on 2019/03/25.
//  Copyright © 2019 原園征志. All rights reserved.
//

import Foundation

extension SyncWalkman{
    
    // MARK: - Load
    
    /**
     You should do this.
     
     .ditto:
         ```
         Log.shared.stderr(RequiredError.ditto.description())
         exit(1)
         ```
     
     .shasum:
         ```
         Log.shared.stderr(RequiredError.shasum.description())
         exit(1)
         ```
     
     .rm:
         ```
         Log.shared.stderr(RequiredError.rm.description())
         exit(1)
         ```
     
     */
    public enum RequiredError: Error{
        case ditto, shasum, rm
        
        public func description() -> String{
            switch self {
            case .ditto:
                return "!Error: Not found ditto in \"/usr/bin/ditto\""
            case .shasum:
                return "!Error: Not found shasum in \"/usr/bin/shasum\""
            case .rm:
                return "!Error: Not found rm in \"/bin/rm\""
            }
        }
    }
    
    /**
     notfoundMusicFolderPath: Notification.Name とセット
     */
    public enum XMLParseError: Error{
        case notfoundMusicFolderPath
        
        public func description() -> String{
            switch self {
            case .notfoundMusicFolderPath:
                return "!Error: not found iTunes Music folder path. iTunes XMLファイルが壊れている可能性があります"
                //exit(1)
            }
        }
    }
    
    /**
     You should do this
     
     - .nilParser:
         ```
         Log.shared.stderr(XMLLoadError.nilParser.description())
         exit(2)
        ```
     
     - .failedParse:
         ```
         Log.shared.stderr(XMLLoadError.failedParse.description())
         exit(2)
         ```
     */
    public enum XMLLoadError: Error{
        case nilParser, failedParse
        
        public func description() -> String{
            switch self {
            case .nilParser:
                return "!Error: Couldn't generate XML Parser"
            case .failedParse:
                return "!Error: Couldn't parse XML"
            }
        }
    }
}
