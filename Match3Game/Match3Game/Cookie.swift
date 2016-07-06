//
//  Cookie.swift
//  Match3Game
//
//  Created by Appable on 6/14/16.
//  Copyright © 2016 Appable. All rights reserved.
//

import Foundation
import SpriteKit

enum CookieType: Int, CustomStringConvertible {
  case Unknown = 0, Red, Blue, Orange, Purple, Green, Yellow, Rainbow
  var spriteName: String {
    let spriteNames = [
      "Red",
      "Blue",
      "Orange",
      "Purple",
      "Green",
      "Yellow",
      "Rainbow"
    ]
    
    return spriteNames[rawValue - 1]
  }
  
  var description: String {
    return  spriteName
  }
  var highlightedSpriteName: String {
    return spriteName + "-Highlighted"
  }
  var verticalSpriteName: String {
    return spriteName + "-Vert"
  }
  var horizontalSpriteName: String {
    return spriteName + "-Horz"
  }
  var crossSpriteName : String {
    return spriteName + "-Cross"
  }
  static func random() -> CookieType {
    return CookieType(rawValue: Int(arc4random_uniform(6)) + 1)!
  }
}

func ==(lhs: Cookie, rhs: Cookie) -> Bool {
  return lhs.column == rhs.column && lhs.row == rhs.row
}

class Cookie: CustomStringConvertible, Hashable {
  var cookieSpecial: String
  var column: Int
  var row: Int
  let cookieType: CookieType
  var sprite: SKSpriteNode?
  var description: String {
    return "type:\(cookieType) square:(\(column),\(row))"
  }
  var hashValue: Int {
    return row*10 + column
  }
  
  init(column: Int, row: Int, cookieType: CookieType, cookieSpecial: String) {
    self.column = column
    self.row = row
    self.cookieType = cookieType
    self.cookieSpecial = cookieSpecial
  }
}