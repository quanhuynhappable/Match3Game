//
//  GameViewController.swift
//  Match3Game
//
//  Created by Appable on 6/14/16.
//  Copyright (c) 2016 Appable. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation

class GameViewController: UIViewController {
  //MARK: Properties
  var scene: GameScene!
  var level: Level!
  var movesLeft = 0
  var score = 0
  var currentLevelNum = 0
  var isEndGame = false
  @IBOutlet weak var targetLabel: UILabel!
  @IBOutlet weak var movesLabel: UILabel!
  @IBOutlet weak var scoreLabel: UILabel!
  @IBOutlet weak var gameOverPanel: UIImageView!
  @IBOutlet weak var shuffleButton: UIButton!
  @IBOutlet weak var levelLabel: UILabel!
  var newCookies = Set<Cookie>()
  var tapGestureRecognizer: UITapGestureRecognizer!
  var check = false
  var rainbowSwap = false
  var rainbowSwapType = CookieType?()
  lazy var backgroundMusic: AVAudioPlayer? = {
    guard let url = NSBundle.mainBundle().URLForResource("Mining by Moonlight", withExtension: "mp3") else {
      return nil
    }
    do {
      let player = try AVAudioPlayer(contentsOfURL: url)
      player.numberOfLoops = -1
      return player
    } catch {
      return nil
    }
  }()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupLevel(currentLevelNum)
    backgroundMusic?.play()
  }
  
  override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
    return [UIInterfaceOrientationMask.Portrait, UIInterfaceOrientationMask.PortraitUpsideDown]
  }
  
  override func shouldAutorotate() -> Bool {
    return true
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  //MARK: Setting Features
  func setupLevel(levelNum: Int) {
    let skView = view as! SKView
    skView.multipleTouchEnabled = false
    scene = GameScene(size: skView.bounds.size)
    scene.scaleMode = .AspectFill
    level = Level(filename: "Level_\(levelNum)")
    levelLabel.text = "Level \(levelNum)"
    scene.level = level
    scene.addTiles()
    scene.swipeHandler = handleSwipe
    gameOverPanel.hidden = true
    shuffleButton.hidden = true
    skView.presentScene(scene)
    beginGame()
  }
  
  func startNewGame() {
    scene.userInteractionEnabled = true
    setupLevel(currentLevelNum)
  }
  
  func beginGame() {
    movesLeft = level.maximumMoves
    score = 0
    isEndGame = false
    updateLabels()
    level.resetComboMultiplier()
    scene.animateBeginGame() {
      self.shuffleButton.hidden = false
    }
    shuffle()
  }
  
  func shuffle() {
    scene.removeAllCookieSprites()
    newCookies = level.shuffle()
    scene.addSpritesForCookies(newCookies)
  }
  
  func beginNextTurn() {
    view.userInteractionEnabled = true
    decrementMoves()
  }
  
  func decrementMoves() {
    movesLeft -= 1
    updateLabels()
  }
  
  func updateLabels() {
    targetLabel.text = String(format: "%ld", level.targetScore)
    movesLabel.text = String(format: "%ld", movesLeft)
    scoreLabel.text = String(format: "%ld", score)
    if score >= level.targetScore && isEndGame == false {
      isEndGame = true
      gameOverPanel.image = UIImage(named: "LevelComplete")
      currentLevelNum = currentLevelNum < NumLevels ? currentLevelNum+1 : 1
      showGameOverSprite(true)
    } else if movesLeft == 0 {
      gameOverPanel.image = UIImage(named: "GameOver")
      showGameOverSprite(false)
    }
  }
  
  func showGameOverSprite(isWin: Bool) {
    shuffleButton.hidden = true
    scene.userInteractionEnabled = false
    scene.animateGameOver(isWin)
    scene.runAction(SKAction.waitForDuration(10.0), completion: startNewGame)
  }
  
  @IBAction func shuffleButtonPressed() {
    shuffle()
    decrementMoves()
  }
  
  //MARK: Handle Methods
  func handleMatches() {
    var newChains = Set<Chain>()
    var rainbowChains = Set<Chain>()
    if rainbowSwap == true {
      rainbowChains = level.getRainbowChains(rainbowSwapType!)
      newChains = newChains.union(rainbowChains)
      rainbowSwap = false
    }
    let (chains, specialCookies, rainbowCookies) = level.removeMatches(rainbowChains)
    newChains = newChains.union(chains)
    if newChains.count == 0 {
      level.detectPossibleSwaps()
      if check == true {
        beginNextTurn()
        check = false
      }
      level.resetComboMultiplier()
      return
    }
    scene.animateMatchedCookies(newChains) {
      self.scene.addSpritesForSpecialCookies(specialCookies)
      self.scene.addSpritesForSpecialCookies(rainbowCookies)
      for chain in newChains {
        self.score += chain.score
      }
      self.updateLabels()
      let columns = self.level.fillHoles()
      self.scene.animateFallingCookies(columns) {
        let columns = self.level.topUpCookies()
        self.scene.animateNewCookies(columns) {
          self.handleMatches()
        }
      }
    }
  }
  
  func handleSwipe(swap: Swap) {
    view.userInteractionEnabled = false
    if level.isPossibleSwap(swap) {
      check = true
      if swap.cookieA.cookieType == CookieType.Rainbow {
        rainbowSwap = true
        rainbowSwapType = swap.cookieB.cookieType
      } else if swap.cookieB.cookieType == CookieType.Rainbow {
        rainbowSwap = true
        rainbowSwapType = swap.cookieA.cookieType
      }
      level.performSwap(swap, completion: scene.animateSwap(swap, completion: handleMatches))
    } else {
      scene.animateInvalidSwap(swap) {
        self.view.userInteractionEnabled = true
      }
    }
  }
}
