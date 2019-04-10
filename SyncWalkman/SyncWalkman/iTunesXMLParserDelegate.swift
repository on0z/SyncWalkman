//
//  iTunesXMLParserDelegate.swift
//  SyncWalkman
//
//  Created by 原園征志 on 2018/05/26.
//  Copyright © 2018年 on0z. All rights reserved.
//

import Foundation

class iTunesXMLParserDelegate: NSObject, XMLParserDelegate{
    
    var itl = iTunesLibraryDataStore()
    var config: SyncWalkmanConfig?
    
    private var loadedTrackCount: Int = 0
    private var loadedPlaylistCount: Int = 0
    
    private var elements: [String] = []
    private var keys: [String] = []
    private var tmpkey: String = ""
    
    private var tmpt: (id: Int?, path: String?) = (nil, nil) //tmpTrack
    private var tmppl: (id: Int?, name: String?, tIDs: [Int]) = (nil, nil, []) //tempPlaylist
    
    private var optmusicFolder: String?

    func parserDidStartDocument(_ parser: XMLParser) {
        NotificationCenter.default.post(name: iTunesXMLParserDelegate.didStartParseXML, object: nil, userInfo: nil)
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        elements.append(elementName)
        keys.append(tmpkey)
        tmpkey = ""
//        Log.shared.stdlog("\(elements)\n\(keys)")
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
        defer{
            elements.removeLast()
            keys.removeLast()
        }
        //---
        if elements == ["plist", "dict", "string"], keys == ["", "", "Music Folder"]{
            guard let musicFolder = optmusicFolder else {
                NotificationCenter.default.post(name: iTunesXMLParserDelegate.notfoundMusicFolderPath, object: nil, userInfo: nil)
                return
            }
            NotificationCenter.default.post(name: iTunesXMLParserDelegate.didFoundMusicFolderPath, object: nil, userInfo: ["path" : musicFolder])
            itl.musicFolder = musicFolder
        }else if elements == ["plist", "dict", "dict", "dict"], keys[2] == "Tracks"{
            loadedTrackCount += 1
            guard let id = tmpt.id else{
                NotificationCenter.default.post(name: iTunesXMLParserDelegate.notfoundTrackID, object: nil, userInfo: ["count" : loadedTrackCount, "path" : String(describing: tmpt.path)])
                tmpt = (nil, nil)
                return
            }
            guard let path = tmpt.path else{
                NotificationCenter.default.post(name: iTunesXMLParserDelegate.notfoundTrackPath, object: nil, userInfo: ["count" : loadedTrackCount, "id" : String(describing: tmpt.id)])
                tmpt = (nil, nil)
                return
            }
            NotificationCenter.default.post(name: iTunesXMLParserDelegate.didFoundTrack, object: nil, userInfo: ["count" : loadedTrackCount, "id" : id, "path" : path])
            itl.tracks.append(
                Track(id: id, path: path)
            )
            tmpt = (nil, nil)
        }else if elements == ["plist", "dict", "array", "dict"], keys[2] == "Playlists"{
            loadedPlaylistCount += 1
            guard let id = tmppl.id else{
                NotificationCenter.default.post(name: iTunesXMLParserDelegate.notfoundPlaylistID, object: nil, userInfo: ["count" : loadedPlaylistCount, "name" : String(describing: tmppl.name)])
                tmppl = (nil, nil, [])
                return
            }
            guard let name = tmppl.name else{
                NotificationCenter.default.post(name: iTunesXMLParserDelegate.notfoundPlaylistName, object: nil, userInfo: ["count" : loadedPlaylistCount, "id" : String(describing: tmppl.id)])
                tmppl = (nil, nil, [])
                return
            }
            NotificationCenter.default.post(name: iTunesXMLParserDelegate.didFoundPlaylist, object: nil, userInfo: ["count" : loadedPlaylistCount, "id" : id, "name" : name])
            itl.playlists.append(
                Playlist(id: id, name: name, trackIDs: tmppl.tIDs)
            )
            tmppl = (nil, nil, [])
        }
        //---
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        NotificationCenter.default.post(name: iTunesXMLParserDelegate.didFinishParseXML, object: nil, userInfo: nil)
    }
}

// Notification.Name
extension iTunesXMLParserDelegate{
    
    static let didStartParseXML: Notification.Name = Notification.Name("didStartParseXML")
    
    static let didFoundMusicFolderPath: Notification.Name = Notification.Name("didFoundMusicFolderPath") // path: String
    static let didFoundTrack: Notification.Name = Notification.Name("didFoundTrack") // count: Int, id: Int, path: String
    static let didFoundPlaylist: Notification.Name = Notification.Name("didFoundPlaylist") // count: Int, id: Int, name: String
    
    static let notfoundTrackID: Notification.Name = Notification.Name("notfoundTrackID") // count: Int, path: String
    static let notfoundTrackPath: Notification.Name = Notification.Name("notfoundTrackPath") // count: Int, id: String
    static let notfoundPlaylistID: Notification.Name = Notification.Name("notfoundPlaylistID") // count: Int, name: String
    static let notfoundPlaylistName: Notification.Name = Notification.Name("notfoundPlaylistName") // count: Int, name: String
    static let notfoundMusicFolderPath: Notification.Name = Notification.Name("notfoundMusicFolderPath") // count: Int, id: String
    
    static let didFinishParseXML: Notification.Name = Notification.Name("didFinishParseXML")
    //: Notification.Name = Notification.Name("")
    
}
