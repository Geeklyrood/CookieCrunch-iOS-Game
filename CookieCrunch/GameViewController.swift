//
//  GameViewController.swift
//  CookieCrunch
//
//  Created by Rood, Keenan on 2/21/17.
//  Copyright © 2017 Rood, Keenan. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation

class GameViewController: UIViewController {
  
  var scene: GameScene!
  var level: Level!
  
  var movesLeft = 0
  var score = 0
  
  var currentLevelNum = 1
  
  @IBOutlet weak var targetLabel: UILabel!
  @IBOutlet weak var movesLabel: UILabel!
  @IBOutlet weak var scoresLabel: UILabel!
  
  @IBOutlet weak var gameOverPanel: UIImageView!
  
  @IBOutlet weak var shuffleButton: UIButton!
  
  var tapGestureRecognizer: UITapGestureRecognizer!
  
  lazy var backgroundMusic: AVAudioPlayer? = {
    guard let url = Bundle.main.url(forResource: "Mining by Moonlight", withExtension: "mp3")
      else {
        return nil
    }
    do {
      let player = try AVAudioPlayer(contentsOf: url)
      player.numberOfLoops = -1
      return player
    } catch {
      return nil
    }
  }()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Setup view for level 1
    setupLevel(levelNum: currentLevelNum)
    
    // Start the music
    backgroundMusic?.play()
  }
  
  func setupLevel(levelNum: Int) {
    
    // Configure the view.
    let skView = view as! SKView
    skView.isMultipleTouchEnabled = false
    
    // Create and configure the scene.
    scene = GameScene(size: skView.bounds.size)
    scene.scaleMode = .aspectFill
    
    
    
    // Set up the level
    level = Level(fileName: "Level_\(levelNum)")
    scene.level = level
    
    scene.swipeHandler = handleSwipe
    scene.addTiles()
    
    gameOverPanel.isHidden = true
    shuffleButton.isHidden = true
    
    // Present the scene.
    skView.presentScene(scene)
    
    beginGame()
  }
  
  func beginGame() {
    movesLeft = level.maximumMoves
    score = 0
    updateLabels()
    level.resetComboMultiplier()
    scene.animateBeginGame {
      self.shuffleButton.isHidden = false
    }
    shuffle()
  }
  
  func shuffle() {
    scene.removeAllCookieSprites()
    let newCookies = level.shuffle()
    scene.addSprites(for: newCookies)
  }
  
  override var shouldAutorotate: Bool {
    return true
  }
  
  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return .portrait
  }
  
  override var prefersStatusBarHidden: Bool {
    return true
  }
  
  func handleSwipe(swap: Swap) {
    
    view.isUserInteractionEnabled = false

    if level.isPossibleSwap(swap) {
      level.performSwap(swap: swap)
      
      scene.animate(swap, completion: handleMatches)
      
    } else {
      
      scene.animateInvalidSwap(swap) {
        self.view.isUserInteractionEnabled = true
      }
      
    }
    
  }
  
  func handleMatches() {
    
    let chains = level.removeMatches()
    
    if chains.count == 0 {
      beginNextTurn()
      return
    }
    
    scene.animateMatchedCookies(for: chains) {
      
      for chain in chains {
        self.score += chain.score
      }
      self.updateLabels()
      
      let columns = self.level.fillCookies()
      self.scene.animateFallingCookies(columns: columns) {
        let columns = self.level.topUpCookies()
        self.scene.animateNewCookies(columns) {
          self.handleMatches()
        }
        
      }
    }
    
  }
  
  func beginNextTurn() {
    level.detectPossibleSwaps()
    level.resetComboMultiplier()
    decrementMoves()
    view.isUserInteractionEnabled = true
  }
  
  func decrementMoves() {
    movesLeft -= 1
    updateLabels()
    
    if score >= level.targetScore {
      
      gameOverPanel.image = UIImage(named: "LevelComplete")
      currentLevelNum = currentLevelNum < NumLevels ? currentLevelNum + 1 : 1
      showGameOver()
      
    } else if movesLeft == 0 {
      
      gameOverPanel.image = UIImage(named: "GameOver")
      showGameOver()
      
    }
  }
  
  func updateLabels() {
    targetLabel.text = String(format: "%ld", level.targetScore)
    movesLabel.text = String(format: "%ld", movesLeft)
    scoresLabel.text = String(format: "%ld", score)
  }
  
  func showGameOver() {
    
    gameOverPanel.isHidden = false
    scene.isUserInteractionEnabled = false
    
    shuffleButton.isHidden = true
    
    scene.animateGameOver {
      self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector (self.hideGameOver))
      self.view.addGestureRecognizer(self.tapGestureRecognizer)
    }
    
  }
  
  func hideGameOver() {
    view.removeGestureRecognizer(tapGestureRecognizer)
    tapGestureRecognizer = nil
    
    gameOverPanel.isHidden = true
    scene.isUserInteractionEnabled = true

    setupLevel(levelNum: currentLevelNum)
  }
  
  @IBAction func shuffleButtonPressed(_ sender: Any) {
    
    shuffle()
    decrementMoves()
    
  }
  
}






