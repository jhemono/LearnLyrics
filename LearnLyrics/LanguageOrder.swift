//
//  LanguageOrder.swift
//  LearnLyrics
//
//  Created by Julien Hémono on 13/07/15.
//  Copyright © 2015 Julien Hémono. All rights reserved.
//

import Foundation

class LanguageOrder {
    class func sharedOrder() -> LanguageOrder {
        struct Singleton {
            static let singleton = LanguageOrder()
        }
        return Singleton.singleton
    }
    
    private struct Constants {
        static let OrderDefaultsKey = "LearnLyricsLanguageOrder"
    }
    
    private let defaults = NSUserDefaults.standardUserDefaults()
    
    private var languageList: [String] {
        get {
            return (defaults.arrayForKey(Constants.OrderDefaultsKey) as? [String]) ?? []
        }
        set {
            defaults.setObject(newValue, forKey: Constants.OrderDefaultsKey)
        }
    }
    
    func raiseLanguage(lyric: Lyrics) {
        let code = lyric.language
        var list = languageList
        if let index = list.indexOf(code) where index != list.startIndex {
            list.removeAtIndex(index)
            list.insert(code, atIndex: 0)
            languageList = list
        }
    }
    
    func orderLyrics(set: Set<Lyrics>) -> [Lyrics] {
        var list = languageList
        var codeSet = Set(set.map { $0.language }).subtract(list)
        if !codeSet.isEmpty {
            list.extend(codeSet)
            languageList = list
        }
        var dict = [String: Lyrics]()
        for lyric in set {
            dict[lyric.language] = lyric
        }
        var result = [Lyrics]()
        for code in list {
            if let lyric = dict[code] {
                result.append(lyric)
            }
        }
        return result
    }
}