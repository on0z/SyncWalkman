//
//  iTunesXMLParserDelegate.swift
//  SyncWalkman
//
//  Created by 原園征志 on 2018/05/26.
//  Copyright © 2018年 on0z. All rights reserved.
//

import Foundation

class iTunesXMLParserDelegate: NSObject, XMLParserDelegate{
    
    var loadedTrackCount: Int = 0
    var loadedPlaylistCount: Int = 0
    
    var elements: [String] = []
    var keys: [String] = []
    var tmpkey: String = ""
    
    var tmpt: (id: Int?, path: String?) = (nil, nil) //tmpTrack
    var tmppl: (id: Int?, name: String?, tIDs: [Int]) = (nil, nil, []) //tempPlaylist
    
    var optmusicFolder: String?

    func parserDidStartDocument(_ parser: XMLParser) {
        stdout("Start XML parse")
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        elements.append(elementName)
        keys.append(tmpkey)
        tmpkey = ""
//        stdlog("\(elements)\n\(keys)")
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if elements.count > 0, elements[elements.count - 1] == "key"{
            tmpkey = string
        }else{
            guard let key = keys.last else{
                return
            }
//            Example:
//            ["", "", "Tracks", "745", "Track ID"]
//            ["plist", "dict", "dict", "dict", "integer" ]
//
//            ["", "", "Tracks", "745", "Location"]
//            ["plist", "dict", "dict", "dict", "string" ]
//
//            ["", "", "Playlists", "", "Playlist ID"]
//            ["plist", "dict", "array", "dict", "integer"]
//
//            ["", "", "Playlists", "", "Name"]
//            ["plist", "dict", "array", "dict", "string"]
//
//            ["", "", "Playlists", "", "Playlist Items", "", "Track ID"]
//            ["plist", "dict", "array", "dict", "array", "dict", "integer"]

//            ["", "", "Music Folder"]
//            ["plist", "dict", "string"]

            if elements == ["plist", "dict", "dict", "dict", "integer"] && key == "Track ID"{
                guard let id = Int(string) else{
                    return
                }
                tmpt.id = id
            }else if elements == ["plist", "dict", "dict", "dict", "string"] && key == "Location"{
                if tmpt.path == nil{
                    tmpt.path = ""
                }
                let removed: String = string.removingPercentEncoding ?? ""
                if removed.hasPrefix("file://"){
                    tmpt.path! += String(removed.dropFirst(7))
                }else{
                    tmpt.path! += removed
                }
            }else if elements == ["plist", "dict", "array", "dict", "integer"] && keys == ["", "", "Playlists", "", "Playlist ID"]{ //Playlist
                guard let id = Int(string) else{
                    return
                }
                tmppl.id = id
            }else if elements == ["plist", "dict", "array", "dict", "string"] && keys == ["", "", "Playlists", "", "Name"]{
                if tmppl.name == nil{
                    tmppl.name = ""
                }
                tmppl.name! += string
            }else if elements == ["plist", "dict", "array", "dict", "array", "dict", "integer"] && keys == ["", "", "Playlists", "", "Playlist Items", "", "Track ID"]{
                guard let id = Int(string) else{
                    return
                }
                tmppl.tIDs.append(id)
            }else if elements == ["plist", "dict", "string"] && keys == ["", "", "Music Folder"]{
                if optmusicFolder == nil{
                    optmusicFolder = ""
                }
                let removed: String = string.removingPercentEncoding ?? ""
                if removed.hasPrefix("file://"){
                    optmusicFolder! += String(removed.dropFirst(7))
                }else{
                    optmusicFolder! += removed
                }
            }
        }
        
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        guard elements.count > 0 else{
            return
        }
        //---
        if elements == ["plist", "dict", "string"], keys == ["", "", "Music Folder"]{
            guard let musicFolder = optmusicFolder else {
                stderr("!Error: not found iTunes Music folder path. iTunes XMLファイルが壊れている可能性があります")
                exit(1)
            }
            iTunesLibraryDataStore.shared.musicFolder = musicFolder
        }else if elements == ["plist", "dict", "dict", "dict"], keys[2] == "Tracks"{
            loadedTrackCount += 1
            guard let id = tmpt.id else{
                stderr("\r!Warning: not found track id \(loadedTrackCount). path? = \(String(describing: tmpt.path))\nloaded songs:\t\t\(loadedTrackCount)", terminator: "")
                tmpt = (nil, nil)
                return
            }
            guard let path = tmpt.path else{
                stderr("\n!Warning: not found track path \(loadedTrackCount). id? = \(String(describing: tmpt.id))\rloaded songs:\t\t\(loadedTrackCount)", terminator: "")
                tmpt = (nil, nil)
                return
            }
            stdout("\rloaded songs:\t\t\(loadedTrackCount)", terminator: "")
            iTunesLibraryDataStore.shared.tracks.append(
                Track(id: id, path: path)
            )
            tmpt = (nil, nil)
        }else if elements == ["plist", "dict", "array", "dict"], keys[2] == "Playlists"{
            if loadedPlaylistCount == 0{
                stdout("")
            }
            loadedPlaylistCount += 1
            guard let id = tmppl.id else{
                stderr("\r!Warning: not found playlist id \(loadedPlaylistCount). name? = \(String(describing: tmppl.name))\nloaded playlists:\t\(loadedPlaylistCount)", terminator: "")
                tmppl = (nil, nil, [])
                return
            }
            guard let name = tmppl.name else{
                stderr("\r!Warning: not found playlist path \(loadedPlaylistCount). id? = \(String(describing: tmppl.id))\nloaded playlists:\t\(loadedPlaylistCount)", terminator: "")
                tmppl = (nil, nil, [])
                return
            }
            stdout("\rloaded playlists:\t\(loadedPlaylistCount)", terminator: "")
            
            iTunesLibraryDataStore.shared.playlists.append(
                Playlist(id: id, name: name, trackIDs: tmppl.tIDs)
            )
            tmppl = (nil, nil, [])
        }
        //---
        elements.removeLast()
        keys.removeLast()
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        stdout("\nFinished XML parse")
    }
}
