//
//  GameScene.swift
//  Match3Game
//
//  Created by Appable on 6/14/16.
//  Copyright (c) 2016 Appable. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
  
  //MARK: Properties
  var level: Level!
  let TileWidth: CGFloat = 36.0
  let TileHeight: CGFloat = 34.0
  let gameLayer = SKNode()
  let cookiesLayer = SKNode()
  let tilesLayer = SKNode()
  var swipeFromColumn: Int?
  var swipeFromRow: Int?
  var swipeHandler: ((Swap) -> ())?
  var selectionSprite = SKSpriteNode()
  let swapSound = SKAction.playSoundFileNamed("Chomp.wav", waitForCompletion: false)
  let invalidSwapSound = SKAction.playSoundFileNamed("Error.wav", waitForCompletion: false)
  let matchSound = SKAction.playSoundFileNamed("Ka-Ching.wav", waitForCompletion: false)
  let fallingCookieSound = SKAction.playSoundFileNamed("Scrape.wav", waitForCompletion: false)
  let addCookieSound = SKAction.playSoundFileNamed("Drip.wav", waitForCompletion: false)
  var gameOverSprite = SKSpriteNode()
  let cropLayer = SKCropNode()
  let maskLayer = SKNode()
  
  //MARK: Init
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder) is not used in this app")
  }
  
  override init(size: CGSize) {
    super.init(size: size)
    gameLayer.hidden = true
    swipeFromColumn = nil
    swipeFromRow = nil
    anchorPoint = CGPoint(x: 0.5, y: 0.5)
    let background = SKSpriteNode(imageNamed: "Background")
    background.size = size
    addChild(background)
    addChild(gameLayer)
    let layerPosition = CGPoint(
      x: -TileWidth * CGFloat(NumColumns) / 2,
      y: -TileHeight * CGFloat(NumRows) / 2)
    tilesLayer.position = layerPosition
    gameLayer.addChild(tilesLayer)
    gameLayer.addChild(cropLayer)
    maskLayer.position = layerPosition
    cropLayer.maskNode = maskLayer
    cookiesLayer.position = layerPosition
    cropLayer.addChild(cookiesLayer)
    let _ = SKLabelNode(fontNamed: "GillSans-BoldItalic")
  }
  
  //MARK: Sprite Methods
  func addSpritesForSpecialCookies(cookies: Set<Cookie>) {
    for cookie in cookies {
      var sprite = SKSpriteNode()
      if cookie.cookieSpecial == "Horizontal" {
        sprite = SKSpriteNode(imageNamed: cookie.cookieType.verticalSpriteName)
      } else if cookie.cookieSpecial == "Vertical" {
        sprite = SKSpriteNode(imageNamed: cookie.cookieType.horizontalSpriteName)
      } else if cookie.cookieSpecial == "Rainbow" {
        sprite = SKSpriteNode(imageNamed: cookie.cookieType.spriteName)
      } else if cookie.cookieSpecial == "Cross" {
        sprite = SKSpriteNode(imageNamed: cookie.cookieType.crossSpriteName)
      }
      sprite.position = pointForColumn(cookie.column, row: cookie.row)
      cookiesLayer.addChild(sprite)
      cookie.sprite = sprite
      sprite.alpha = 0
      sprite.xScale = 0.5
      sprite.yScale = 0.5
      sprite.runAction(
        SKAction.sequence([
          SKAction.waitForDuration(0.25, withRange: 0.5),
          SKAction.group([
            SKAction.fadeInWithDuration(0.25),
            SKAction.scaleTo(1.0, duration: 0.25)
            ])
          ]))
    }
  }
  
  func addSpritesForCookies(cookies: Set<Cookie>) {
    for cookie in cookies {
      let sprite = SKSpriteNode(imageNamed: cookie.cookieType.spriteName)
      //sprite.size = CGSize(width: TileWidth, height: TileHeight)
      sprite.position = pointForColumn(cookie.column, row: cookie.row)
      cookiesLayer.addChild(sprite)
      cookie.sprite = sprite
      sprite.alpha = 0
      sprite.xScale = 0.5
      sprite.yScale = 0.5
      sprite.runAction(
        SKAction.sequence([
          SKAction.waitForDuration(0.25, withRange: 0.5),
          SKAction.group([
            SKAction.fadeInWithDuration(0.25),
            SKAction.scaleTo(1.0, duration: 0.25)
            ])
          ]))
    }
  }
  
  func addTiles() {
    for row in 0..<NumRows {
      for column in 0..<NumColumns {
        if level.tileAtColumn(column, row: row) != nil {
          let tileNode = SKSpriteNode(imageNamed: "MaskTile")
          tileNode.size = CGSize(width: TileWidth, height: TileHeight)
          tileNode.position = pointForColumn(column, row: row)
          maskLayer.addChild(tileNode)
        }
      }
    }
    
    for row in 0...NumRows {
      for column in 0...NumColumns {
        let topLeft = (column > 0) && (row < NumRows)
          && level.tileAtColumn(column - 1, row: row) != nil
        let bottomLeft  = (column > 0) && (row > 0)
          && level.tileAtColumn(column - 1, row: row - 1) != nil
        let topRight    = (column < NumColumns) && (row < NumRows)
          && level.tileAtColumn(column, row: row) != nil
        let bottomRight = (column < NumColumns) && (row > 0)
          && level.tileAtColumn(column, row: row - 1) != nil
        let value = Int(topLeft) | Int(topRight) << 1 | Int(bottomLeft) << 2 | Int(bottomRight) << 3
        if value != 0 && value != 6 && value != 9 {
          let name = String(format: "Tile_%ld", value)
          let tileNode = SKSpriteNode(imageNamed: name)
          tileNode.size = CGSize(width: TileWidth, height: TileHeight)
          var point = pointForColumn(column, row: row)
          point.x -= TileWidth/2
          point.y -= TileHeight/2
          tileNode.position = point
          tilesLayer.addChild(tileNode)
        }
      }
    }
  }
  
  func removeAllCookieSprites() {
    cookiesLayer.removeAllChildren()
  }
  
  //MARK: CGPoint Methods
  func pointForColumn(column: Int, row: Int) -> CGPoint {
    return CGPoint(
      x: CGFloat(column)*TileWidth + TileWidth/2,
      y: CGFloat(row)*TileHeight + TileHeight/2)
  }
  
  func convertPoint(point: CGPoint) -> (success: Bool, column: Int, row: Int) {
    if point.x >= 0 && point.x < CGFloat(NumColumns)*TileWidth &&
       point.y >= 0 && point.y < CGFloat(NumRows)*TileHeight {
      return (true, Int(point.x / TileWidth), Int(point.y / TileHeight))
    } else {
      return (false, 0, 0)
    }
  }
  
  //MARK: Touch Methods
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard let touch = touches.first else { return }
    let location = touch.locationInNode(cookiesLayer)
    let (success, column, row) = convertPoint(location)
    if success {
      if let cookie = level.cookieAtColumn(column, row: row) {
        showSelectionIndicatorForCookie(cookie)
        swipeFromRow = row
        swipeFromColumn = column
      }
    }
  }
  
  override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard swipeFromColumn != nil else { return }
    guard let touch = touches.first else { return }
    let location  = touch.locationInNode(cookiesLayer)
    let (success, column, row) = convertPoint(location)
    if success {
      var horzDelta = 0
      var vertDelta = 0
      if column < swipeFromColumn! {
        horzDelta = -1
      } else if column > swipeFromColumn! {
        horzDelta = 1
      } else if row < swipeFromRow! {
        vertDelta = -1
      } else if row > swipeFromRow! {
        vertDelta = 1
      }
      if horzDelta != 0 || vertDelta != 0 {
        trySwapHorizontal(horzDelta, vertical: vertDelta)
        hideSelcetionIndicator()
        swipeFromColumn = nil
      }
    }
  }
  
  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if selectionSprite.parent != nil && swipeFromColumn != nil {
      hideSelcetionIndicator()
    }
    swipeFromColumn = nil
    swipeFromRow = nil
  }
  
  override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
    if let touches = touches {
      touchesEnded(touches, withEvent: event)
    }
  }
  
  func trySwapHorizontal(horzDelta: Int, vertical vertDelta: Int) {
    let toColumn = swipeFromColumn! + horzDelta
    let toRow = swipeFromRow! + vertDelta
    guard toColumn >= 0 && toColumn < NumColumns else { return }
    guard toRow >= 0 && toRow < NumRows else { return }
    if let toCookie = level.cookieAtColumn(toColumn, row: toRow),
      let fromCookie = level.cookieAtColumn(swipeFromColumn!, row: swipeFromRow!) {
        if let handler = swipeHandler {
          let swap = Swap(cookieA: fromCookie, cookieB: toCookie)
          handler(swap)
        }
    }
  }
  
  //MARK: Setting Animate
  func animateSwap(swap: Swap, completion: () -> ()) {
    let spriteA = swap.cookieA.sprite!
    let spriteB = swap.cookieB.sprite!
    
    spriteA.zPosition = 100
    spriteB.zPosition = 90
    
    let duration: NSTimeInterval = 0.3
    
    let moveA = SKAction.moveTo(spriteB.position, duration: duration)
    moveA.timingMode = .EaseOut
    spriteA.runAction(moveA, completion: completion)
    
    let moveB = SKAction.moveTo(spriteA.position, duration: duration)
    moveB.timingMode = .EaseOut
    spriteB.runAction(moveB, completion: completion)
    
    runAction(swapSound)
  }
  
  func animateInvalidSwap(swap: Swap, completion: () -> ()) {
    let spriteA = swap.cookieA.sprite!
    let spriteB = swap.cookieB.sprite!
    
    spriteA.zPosition = 100
    spriteB.zPosition = 90
    
    let Duration: NSTimeInterval = 0.2
    
    let moveA = SKAction.moveTo(spriteB.position, duration: Duration)
    moveA.timingMode = .EaseOut
    
    let moveB = SKAction.moveTo(spriteA.position, duration: Duration)
    moveB.timingMode = .EaseOut
    
    spriteA.runAction(SKAction.sequence([moveA, moveB]), completion: completion)
    spriteB.runAction(SKAction.sequence([moveB, moveA]), completion: completion)
    
    runAction(invalidSwapSound)
  }
  
  func animateMatchedCookies(chains: Set<Chain>, completion: () -> ()) {
    for chain in chains {
      animateScoreForChain(chain)
      for cookie in chain.cookies {
        if let sprite = cookie.sprite {
          if sprite.actionForKey("removing") == nil {
            let scaleAction = SKAction.scaleTo(0.1, duration: 0.3)
            scaleAction.timingMode = .EaseOut
            sprite.runAction(SKAction.sequence([scaleAction, SKAction.removeFromParent()]), withKey: "removing")
          }
        }
      }
    }
    runAction(matchSound)
    runAction(SKAction.waitForDuration(0.3), completion: completion)
  }
  
  func animateFallingCookies(columns: [[Cookie]], completion: () -> ()) {
    var longestDuration: NSTimeInterval = 0
    for array in columns {
      for (idx, cookie) in array.enumerate() {
        let newPositon = pointForColumn(cookie.column, row: cookie.row)
        let delay = 0.05 + 0.15 * NSTimeInterval(idx)
        let sprite = cookie.sprite!
        let duration = NSTimeInterval(((sprite.position.y - newPositon.y) / TileHeight) * 0.1)
        longestDuration = max(longestDuration, duration + delay)
        let moveAction = SKAction.moveTo(newPositon, duration: duration)
        moveAction.timingMode = .EaseOut
        sprite.runAction(
          SKAction.sequence([
            SKAction.waitForDuration(delay),
            SKAction.group([moveAction, fallingCookieSound])]))
      }
    }
    runAction(SKAction.waitForDuration(longestDuration), completion: completion)
  }
  
  func animateNewCookies(columns: [[Cookie]], completion: () -> ()) {
    var longestDuration: NSTimeInterval = 0
    for array in columns {
      let startRow = array[0].row + 1
      for (idx, cookie) in array.enumerate() {
        let sprite = SKSpriteNode(imageNamed: cookie.cookieType.spriteName)
        //sprite.size = CGSize(width: TileWidth, height: TileHeight)
        sprite.position = pointForColumn(cookie.column, row: startRow)
        cookiesLayer.addChild(sprite)
        cookie.sprite = sprite
        
        let delay = 0.1 + 0.2 * NSTimeInterval(array.count - idx - 1)
        let duration = NSTimeInterval(startRow - cookie.row) * 0.1
        longestDuration = max(longestDuration, duration + delay)
        
        let newPosition = pointForColumn(cookie.column, row: cookie.row)
        let moveAction = SKAction.moveTo(newPosition, duration: duration)
        moveAction.timingMode = .EaseOut
        sprite.alpha = 0
        sprite.runAction(
          SKAction.sequence([
            SKAction.waitForDuration(delay),
            SKAction.group([
              SKAction.fadeInWithDuration(0.05),
              moveAction,
              addCookieSound])
            ]))
      }
    }
    runAction(SKAction.waitForDuration(longestDuration), completion: completion)
  }
  
  func animateScoreForChain(chain: Chain) {
    let firstSprite = chain.firstCookie().sprite!
    let lastSprite = chain.lastCookie().sprite!
    let centerPosition = CGPoint(
      x: (firstSprite.position.x + lastSprite.position.x)/2,
      y: (firstSprite.position.y + lastSprite.position.y)/2 - 8)
    let scoreLabel = SKLabelNode(fontNamed: "GillSans-BoldItalic")
    scoreLabel.fontSize = 16
    scoreLabel.text = String(format: "%ld", chain.score)
    scoreLabel.position = centerPosition
    scoreLabel.zPosition = 300
    cookiesLayer.addChild(scoreLabel)
    
    let moveAction = SKAction.moveBy(CGVector(dx: 0, dy: 3), duration: 0.7)
    moveAction.timingMode = .EaseOut
    scoreLabel.runAction(SKAction.sequence([moveAction, SKAction.removeFromParent()]))
  }
  
  func animateGameOver(isWin: Bool) {
    if isWin {
      gameOverSprite = SKSpriteNode(imageNamed: "LevelComplete")
    } else {
      gameOverSprite = SKSpriteNode(imageNamed: "GameOver")
    }
    gameOverSprite.position = CGPoint(x: 0, y: 0)
    gameOverSprite.size = CGSize(width: (self.view?.scene?.size.width)!, height: (self.view?.scene?.size.height)!/4)
    gameOverSprite.zPosition = 200
    gameOverSprite.alpha = 0
    gameLayer.addChild(gameOverSprite)
    let fadeInAlphaAction = SKAction.fadeInWithDuration(3.0)
    let fadeOutAlphaAction = SKAction.fadeOutWithDuration(3.0)
    gameOverSprite.runAction(SKAction.sequence([
      fadeInAlphaAction,
      SKAction.waitForDuration(4.0),
      fadeOutAlphaAction]))
    runAction(SKAction.waitForDuration(10.0))
  }
  
  func animateBeginGame(completion: () -> ()) {
    gameLayer.hidden = false
    gameLayer.position = CGPoint(x: 0, y: size.height)
    let action = SKAction.moveBy(CGVector(dx: 0, dy: -size.height), duration: 0.3)
    action.timingMode = .EaseOut
    gameLayer.runAction(action, completion: completion)
  }
  
  func showSelectionIndicatorForCookie(cookie: Cookie) {
    if selectionSprite.parent != nil {
      selectionSprite.removeFromParent()
    }
    
    if let sprite = cookie.sprite {
      let texture = SKTexture(imageNamed: cookie.cookieType.highlightedSpriteName)
      selectionSprite.size = sprite.size
      selectionSprite.runAction(SKAction.setTexture(texture))
      
      sprite.addChild(selectionSprite)
      selectionSprite.alpha = 1.0
    }
  }
  
  func hideSelcetionIndicator() {
    selectionSprite.runAction(SKAction.sequence([
      SKAction.fadeOutWithDuration(0.3),
      SKAction.removeFromParent()]))
  }
}
