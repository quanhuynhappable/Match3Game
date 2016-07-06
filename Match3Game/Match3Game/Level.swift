//
//  Level.swift
//  Match3Game
//
//  Created by Appable on 6/14/16.
//  Copyright © 2016 Appable. All rights reserved.
//

import Foundation

let NumColumns = 9
let NumRows = 9
let NumLevels = 4

class Level {
  //MARK: Properties
  var swap: Swap?
  var targetScore = 0
  var maximumMoves = 0
  private var cookies = Array2D<Cookie>(columns: NumColumns, rows: NumColumns)
  private var tiles = Array2D<Tile>(columns: NumColumns, rows: NumColumns)
  private var possibleSwaps = Set<Swap>()
  private var comboMultiplier = 1
  
  init(filename: String) {
    guard let dictionary = Dictionary<String, AnyObject>.loadJSONFromBundle(filename) else { return }
    guard let tilesArray = dictionary["tiles"] as? [[Int]] else { return }
    for (row, rowArray) in tilesArray.enumerate() {
      let tileRow = NumRows - row - 1
      for (column, value) in rowArray.enumerate() {
        if value == 1 {
          tiles[column, tileRow] = Tile()
        }
      }
    }
    targetScore = dictionary["targetScore"] as! Int
    maximumMoves = dictionary["moves"] as! Int
  }
  
  //MARK: Setting Features
  func shuffle() -> Set<Cookie> {
    var set: Set<Cookie>
    repeat {
      set = createInitialCookies()
      detectPossibleSwaps()
      print("possible swaps: \(possibleSwaps)")
    } while possibleSwaps.count == 0
    return set
  }
  
  private func createInitialCookies() -> Set<Cookie> {
    var set = Set<Cookie>()
    for row in 0..<NumRows {
      for column in 0..<NumColumns {
        if tiles[column, row] != nil {
          var cookieType: CookieType
          repeat {
            cookieType = CookieType.random()
          } while (column >= 2 &&
            cookies[column - 1, row]?.cookieType == cookieType &&
            cookies[column - 2, row]?.cookieType == cookieType)
            || (row >= 2 &&
              cookies[column, row - 1]?.cookieType == cookieType &&
              cookies[column, row - 2]?.cookieType == cookieType)
          let cookieSpecial = "None"
          let cookie = Cookie(column: column, row: row, cookieType: cookieType, cookieSpecial: cookieSpecial)
          cookies[column, row] = cookie
          set.insert(cookie)
        }
      }
    }
    return set
  }
  
  func fillHoles() -> [[Cookie]] {
    var columns = [[Cookie]]()
    for column in 0..<NumColumns {
      var array = [Cookie]()
      for row in 0..<NumRows {
        if tiles[column, row] != nil && cookies[column, row] == nil {
          for lookup in (row + 1)..<NumRows {
            if let cookie = cookies[column, lookup] {
              cookies[column,lookup] = nil
              cookies[column, row] = cookie
              cookie.row = row
              array.append(cookie)
              break
            }
          }
        }
      }
      if !array.isEmpty {
        columns.append(array)
      }
    }
    return columns
  }
  
  func topUpCookies() -> [[Cookie]] {
    var columns = [[Cookie]]()
    var cookieType: CookieType = .Unknown
    for column in 0..<NumColumns {
      var array = [Cookie]()
      var row = NumRows - 1
      while row >= 0 && cookies[column, row] == nil {
        if tiles[column, row] != nil {
          var newCookieType: CookieType
          repeat {
            newCookieType = CookieType.random()
          } while newCookieType == cookieType
          cookieType = newCookieType
          let cookieSpecial = "None"
          let cookie = Cookie(column: column, row: row, cookieType: cookieType, cookieSpecial: cookieSpecial)
          cookies[column, row] = cookie
          array.append(cookie)
        }
        row -= 1
      }
      if !array.isEmpty {
        columns.append(array)
      }
    }
    return columns
  }
  
  func cookieAtColumn(column: Int, row: Int) -> Cookie? {
    assert(column >= 0 && column < NumColumns)
    assert(row >= 0 && row < NumRows)
    return cookies[column, row]
  }
  
  func tileAtColumn(column: Int, row: Int) -> Tile? {
    assert(column >= 0 && column < NumColumns)
    assert(row >= 0 && row < NumRows)
    return tiles[column, row]
  }
  
  private func calculateScores(chains: Set<Chain>) {
    for chain in chains {
      chain.score = 60 * (chain.length - 2) * comboMultiplier
      if chain.length == 1 {
        chain.score = 60 * comboMultiplier
      }
      comboMultiplier += 1
    }
  }
  
  func resetComboMultiplier() {
    comboMultiplier = 1
  }
  
  //MARK: Swap Methods
  func performSwap(swap: Swap, completion: ()) {
    self.swap = swap
    let columnA = swap.cookieA.column
    let rowA = swap.cookieA.row
    let columnB = swap.cookieB.column
    let rowB = swap.cookieB.row
    
    cookies[columnA, rowA] = swap.cookieB
    swap.cookieB.column = columnA
    swap.cookieB.row = rowA
    
    cookies[columnB, rowB] = swap.cookieA
    swap.cookieA.column = columnB
    swap.cookieA.row = rowB
  }
  
  
  func detectPossibleSwaps() {
    var set = Set<Swap>()
    for row in 0..<NumRows {
      for column in 0..<NumColumns {
        if let cookie = cookies[column, row] {
          if column < NumColumns - 1 {
            if let other = cookies[column + 1, row] {
              cookies[column, row] = other
              cookies[column + 1, row] = cookie
              if hasChainAtColumn(column + 1, row: row) ||
                 hasChainAtColumn(column, row: row) {
                  set.insert(Swap(cookieA: cookie, cookieB: other))
              }
              cookies[column, row] = cookie
              cookies[column + 1, row] = other
            }
          }
          if row < NumRows - 1 {
            if let other = cookies[column, row + 1] {
              cookies[column, row] = other
              cookies[column, row + 1] = cookie
              if hasChainAtColumn(column, row: row + 1) ||
                 hasChainAtColumn(column, row: row) {
                  set.insert(Swap(cookieA: cookie, cookieB: other))
              }
              cookies[column, row] = cookie
              cookies[column, row + 1] = other
            }
          }
        }
      }
    }
    possibleSwaps = set
  }
  
  func isPossibleSwap(swap: Swap) -> Bool {
    if swap.cookieA.cookieType == CookieType.Rainbow ||
      swap.cookieB.cookieType == CookieType.Rainbow {
        return true
    }
    return possibleSwaps.contains(swap)
  }
  //MARK: Matches Methods
  func removeMatches(rainbowChains: Set<Chain>) -> (Set<Chain>, Set<Cookie>, Set<Cookie>) {
    var horizontalChains = detectHorizontalMatches()
    var verticalChains = detectVerticalMatches()
    var crossChains = Set<Chain>()
    for horzChain in horizontalChains {
      for vertChain in verticalChains {
        for horzCookie in horzChain.cookies {
          for vertCookie in vertChain.cookies {
            if horzCookie == vertCookie {
              cookies[horzCookie.column, horzCookie.row]?.cookieSpecial = "Center"
              let crossChain = detectCrossMatches(horzChain, vertChain: vertChain)
              crossChains.insert(crossChain)
              horizontalChains.remove(horzChain)
              verticalChains.remove(vertChain)
            }
          }
        }
      }
    }
    let (cRainbowCookies, crossCookies, specialCrossChains) = removeCookies(crossChains, rainbowChains: rainbowChains)
    let (hRainbowCookies, horzCookies, specialHorizontalChains) = removeCookies(horizontalChains, rainbowChains: rainbowChains)
    let (vRainbowCookies, vertCookies, specialVerticalChains) = removeCookies(verticalChains, rainbowChains: rainbowChains)
    horizontalChains = horizontalChains.union(specialHorizontalChains)
    verticalChains = verticalChains.union(specialVerticalChains)
    crossChains = crossChains.union(specialCrossChains)
    calculateScores(horizontalChains)
    calculateScores(verticalChains)
    calculateScores(rainbowChains)
    calculateScores(crossChains)
    return (horizontalChains.union(verticalChains).union(crossChains),
            horzCookies.union(vertCookies).union(crossCookies),
            hRainbowCookies.union(vRainbowCookies).union(cRainbowCookies))
  }
  
  private func removeCookies(chains: Set<Chain>, rainbowChains: Set<Chain>) -> (Set<Cookie>, Set<Cookie>, Set<Chain>) {
    for chain in rainbowChains {
      for cookie in chain.cookies {
        cookies[cookie.column, cookie.row] = nil
      }
    }
    var rainbowCookies = Set<Cookie>()
    var specialCookies = Set<Cookie>()
    var newChains = Set<Chain>()
    for chain in chains {
      var isSpecial = false
      var horzChains = Set<Chain>()
      var vertChains = Set<Chain>()
      var crossChains = Set<Chain>()
      for cookie in chain.cookies {
        if cookie.cookieSpecial != "None" {
          if cookie.cookieSpecial == "Vertical" {
            var vertChain = Chain(chainType: .Vertical)
            checkVerticalCookie(cookie, chain: &vertChain)
            vertChains.insert(vertChain)
            isSpecial = true
          } else if cookie.cookieSpecial == "Horizontal" {
            var horzChain = Chain(chainType: .Horizontal)
            checkHorizontalCookie(cookie, chain: &horzChain)
            horzChains.insert(horzChain)
            isSpecial = true
          } else if cookie.cookieSpecial == "Cross" {
            var crossChain = Chain(chainType: .Cross)
            checkCrossCookie(cookie, chain: &crossChain)
            crossChains.insert(crossChain)
            isSpecial = true
          }
        }
      }
      if isSpecial == false {
        if chain.length >= 5 {
          var sameRow = true
          var sameColumn = true
          let cookieInChain = chain.cookies[0]
          for cookie in chain.cookies {
            if cookie.row != cookieInChain.row {
              sameRow = false
            }
            if cookie.column != cookieInChain.column {
              sameColumn = false
            }
          }
          if sameRow || sameColumn {
            let aCookie = chain.cookies[2]
            let rainbowCookie = Cookie(column: aCookie.column, row: aCookie.row, cookieType: CookieType.Rainbow, cookieSpecial: "Rainbow")
            for cookie in chain.cookies {
              cookies[cookie.column, cookie.row] = nil
            }
            cookies[aCookie.column, aCookie.row] = rainbowCookie
            rainbowCookies.insert(rainbowCookie)
          } else {
            var centerCookie = Cookie!()
            for cookie in chain.cookies {
              if cookie.cookieSpecial == "Center" {
                centerCookie = cookie
              }
              cookies[cookie.column, cookie.row] = nil
            }
            let specialCookie = Cookie(column: centerCookie.column, row: centerCookie.row, cookieType: centerCookie.cookieType, cookieSpecial: "\(chain.chainType)")
            cookies[centerCookie.column, centerCookie.row] = specialCookie
            specialCookies.insert(specialCookie)
          }
        } else if chain.length == 4 {
          var swapCookie = Cookie?()
          var aCookie = chain.cookies[2]
          if swap?.cookieA.cookieType == aCookie.cookieType {
            swapCookie = swap?.cookieA
          } else if swap?.cookieB.cookieType == aCookie.cookieType {
            swapCookie = swap?.cookieB
          }
          for cookie in chain.cookies {
            if cookie.column == swapCookie?.column && cookie.row == swapCookie?.row {
              aCookie = cookie
              self.swap = nil
            }
          }
          let specialCookie = Cookie(column: aCookie.column, row: aCookie.row, cookieType: aCookie.cookieType, cookieSpecial: "\(chain.chainType)")
          for cookie in chain.cookies {
            cookies[cookie.column, cookie.row] = nil
          }
          cookies[aCookie.column, aCookie.row] = specialCookie
          specialCookies.insert(specialCookie)
        } else {
          for cookie in chain.cookies {
            cookies[cookie.column, cookie.row] = nil
          }
        }
      } else {
        newChains = horzChains.union(vertChains).union(chains).union(crossChains)
        for chain in newChains {
          for cookie in chain.cookies {
            cookies[cookie.column, cookie.row] = nil
          }
        }
      }
    }
    return (rainbowCookies, specialCookies, newChains)
  }
  
  private func checkVerticalCookie(theCookie: Cookie, inout chain: Chain) {
    chain.addCookie(theCookie)
    for column in 0...NumColumns-1 {
      if let cookie1 = cookies[column, theCookie.row] {
        if !chain.cookies.contains(cookie1) {
          if cookie1.cookieSpecial == "Horizontal" {
            checkHorizontalCookie(cookie1, chain: &chain)
          } else if cookie1.cookieSpecial == "Cross" {
            checkCrossCookie(cookie1, chain: &chain)
          } else {
            chain.addCookie(cookie1)
          }
        }
      }
    }
  }
  
  private func checkHorizontalCookie(theCookie: Cookie, inout chain: Chain) {
    chain.addCookie(theCookie)
    for row in 0...NumRows-1 {
      if let cookie1 = cookies[theCookie.column, row] {
        if !chain.cookies.contains(cookie1) {
          if cookie1.cookieSpecial == "Vertical" {
            checkVerticalCookie(cookie1, chain: &chain)
          } else if cookie1.cookieSpecial == "Cross" {
            checkCrossCookie(cookie1, chain: &chain)
          } else {
            chain.addCookie(cookie1)
          }
        }
      }
    }
  }
  
  private func checkCrossCookie(theCookie: Cookie, inout chain: Chain) {
    chain.addCookie(theCookie)
    for column1 in theCookie.column-1...theCookie.column+1 {
      for row1 in theCookie.row-1...theCookie.row+1 {
        if (column1 >= 0 && column1 < NumColumns) && (row1 >= 0 && row1 < NumRows) {
          if let cookie1 = cookies[column1, row1] {
            if !chain.cookies.contains(cookie1) {
              if cookie1.cookieSpecial == "Vertical" {
                checkVerticalCookie(cookie1, chain: &chain)
              } else if cookie1.cookieSpecial == "Cross" {
                checkCrossCookie(cookie1, chain: &chain)
              } else if cookie1.cookieSpecial == "Horizontal" {
                checkHorizontalCookie(cookie1, chain: &chain)
              } else {
                chain.addCookie(cookie1)
              }
            }
          }
        }
      }
    }
  }
  
  func getRainbowChains(rainbowSwapType: CookieType) -> Set<Chain> {
    var rainbowChains = Set<Chain>()
    let rainbowChain = Chain(chainType: .Rainbow)
    for column in 0..<NumColumns {
      for row in 0..<NumRows {
        if let cookie = cookies[column, row] {
          if cookie.cookieType == rainbowSwapType {
            rainbowChain.addCookie(cookie)
          }
        }
      }
    }
    rainbowChain.addCookie((swap?.cookieA)!)
    rainbowChain.addCookie((swap?.cookieB)!)
    rainbowChains.insert(rainbowChain)
    return rainbowChains
  }
  
  private func detectHorizontalMatches() -> Set<Chain> {
    var set = Set<Chain>()
    for row in 0..<NumRows {
      var column = 0
      while column < NumColumns - 2 {
        if let cookie = cookies[column, row] {
          let matchType = cookie.cookieType
          if cookies[column + 1, row]?.cookieType == matchType &&
            cookies[column + 2, row]?.cookieType == matchType {
              let chain = Chain(chainType: .Horizontal)
              repeat {
                chain.addCookie(cookies[column, row]!)
                column += 1
              } while column < NumColumns && cookies[column, row]?.cookieType == matchType
              set.insert(chain)
              continue
          }
        }
        column += 1
      }
    }
    return set
  }
  
  private func detectVerticalMatches() -> Set<Chain> {
    var set = Set<Chain>()
    for column in 0..<NumColumns {
      var row = 0
      while row < NumRows - 2 {
        if let cookie = cookies[column, row] {
          let matchType = cookie.cookieType
          if cookies[column, row + 1]?.cookieType == matchType &&
            cookies[column, row + 2]?.cookieType == matchType {
              let chain = Chain(chainType: .Vertical)
              repeat {
                chain.addCookie(cookies[column, row]!)
                row += 1
              } while row < NumRows && cookies[column, row]?.cookieType == matchType
              set.insert(chain)
              continue
          }
        }
        row += 1
      }
    }
    return set
  }
  
  func detectCrossMatches(horzChain: Chain, vertChain: Chain) -> Chain {
    let crossChain = Chain(chainType: .Cross)
    for horzCookie in horzChain.cookies {
      crossChain.addCookie(horzCookie)
    }
    for vertCookie in vertChain.cookies {
      if vertCookie.cookieSpecial != "Center" {
        crossChain.addCookie(vertCookie)
      }
    }
    return crossChain
  }
  
  private func hasChainAtColumn(column: Int, row: Int) -> Bool {
    let cookieType = cookies[column, row]!.cookieType
    
    var horzLength = 1
    var i = column - 1
    while i >= 0 && cookies[i, row]?.cookieType == cookieType {
      i -= 1
      horzLength += 1
    }
    
    i = column + 1
    while i < NumColumns && cookies[i, row]?.cookieType == cookieType {
      i += 1
      horzLength += 1
    }
    if horzLength >= 3 { return true }
    
    var vertLength = 1
    i = row - 1
    while i >= 0 && cookies[column, i]?.cookieType == cookieType {
      i -= 1
      vertLength += 1
    }
    
    i = row + 1
    while i < NumRows && cookies[column, i]?.cookieType == cookieType {
      i += 1
      vertLength += 1
    }
    return vertLength >= 3
  }
}