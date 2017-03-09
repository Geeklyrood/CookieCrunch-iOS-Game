//
//  Cookie.swift
//  CookieCrunch
//
//  Created by Rood, Keenan on 2/21/17.
//  Copyright © 2017 Rood, Keenan. All rights reserved.
//

import SpriteKit

enum CookieType: Int, CustomStringConvertible {
  case unknown = 0, croissant, cupcake, danish, donut, macaroon, sugarCookie
  
  var spriteName: String {
    let spriteNames = ["Croissant", "Cupcake", "Danish", "Donut", "Macaroon", "SugarCookie"]
    return spriteNames[rawValue - 1]
  }
  
  var highlightedSpriteName: String {
    return spriteName + "-Highlighted"
  }
  
  static func random() -> CookieType {
    return CookieType(rawValue: Int(arc4random_uniform(6)) + 1)!
  }
  
  var description: String {
    return spriteName
  }
  
}

class Cookie: CustomStringConvertible {
  
  var column: Int
  var row: Int
  let cookieType: CookieType
  var sprite: SKSpriteNode?
  
  init(column: Int, row: Int, cookieType: CookieType) {
    self.column = column
    self.row = row
    self.cookieType = cookieType
  }

  var description: String {
    return "type: \(cookieType) square: (\(column), \(row))"
  }
  
}

extension Cookie: Hashable {
  var hashValue: Int {
    return row * 10 + column
  }
}
func ==(lhs: Cookie, rhs: Cookie) -> Bool {
  return lhs.column == rhs.column && lhs.row == rhs.row
}

