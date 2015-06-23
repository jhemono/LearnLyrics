//: Playground - noun: a place where people can play

import UIKit

let codes = Set(NSLocale.availableLocaleIdentifiers())
for code in codes {
    print(code)
}

let code = "de"
codes.contains(code)

let locale = NSLocale(localeIdentifier: code)
let numberFormatter = NSNumberFormatter()
numberFormatter.locale = locale
numberFormatter.numberStyle = .SpellOutStyle

numberFormatter.stringFromNumber(45)