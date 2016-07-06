//
//  Chain.swift
//  Match3Game
//
//  Created by Appable on 6/16/16.
//  Copyright © 2016 Appable. All rights reserved.
//

import Foundation
class Chain: Hashable, CustomStringConvertible {
  var cookies = [Cookie]()
  var score = 0
  
  enum ChainType: CustomStringConvertible {
    case Horizontal
    case Vertical
    case Rainbow
    case Cross
    
    var description: String {
      switch self {
      case .Horizontal: return "Horizontal"
      case .Vertical: return "Vertical"
      case .Rainbow: return "Rainbow"
      case .Cross: return "Cross"
      }
    }
  }
  
  var chainType: ChainType
  
  init(chainType: ChainType) {
    self.chainType = chainType
  }
  
  func addCookie(cookie: Cookie) {
    cookies.append(cookie)
  }
  
  func firstCookie() -> Cookie {
    return cookies[0]
  }
  
  func lastCookie() -> Cookie {
    return cookies[cookies.count - 1]
  }
  
  var length: Int {
    return cookies.count
  }
  
  var description: String {
    return "type:\(chainType) cookies:\(cookies)"
  }
  
  var hashValue: Int {
    return cookies.reduce (0) { $0.hashValue ^ $1.hashValue }
  }
}

func ==(lhs: Chain, rhs: Chain) -> Bool {
  return lhs.cookies == rhs.cookies
}