//
//  GameViewController.swift
//  CookieCrunch
//
//  Created by Andrews, George on 2/21/17.
//  Copyright © 2017 Andrews, George. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
  
  var scene: GameScene!
  var level: Level!
  
  var movesLeft = 0
  var score = 0
  
  @IBOutlet weak var targetLabel: UILabel!
  @IBOutlet weak var movesLabel: UILabel!
  @IBOutlet weak var scoresLabel: UILabel!
  
  @IBOutlet weak var gameOverPanel: UIImageView!
  
  @IBOutlet weak var shuffleButton: UIButton!
  
  var tapGestureRecognizer: UITapGestureRecognizer!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Hide gameOverPanel
    gameOverPanel.isHidden = true
    
    
    // Configure the view.
    let skView = view as! SKView
    skView.isMultipleTouchEnabled = false
  
    // Create and configure the scene.
    scene = GameScene(size: skView.bounds.size)
    scene.scaleMode = .aspectFill
    
    scene.swipeHandler = handleSwipe
    
    // Present the scene.
    skView.presentScene(scene)
    
    level = Level(fileName: "Level_1")
    scene.level = level
    scene.addTiles()
    
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
    
    beginGame()
  }
  
  @IBAction func shuffleButtonPressed(_ sender: Any) {
    
    shuffle()
    decrementMoves()
    
  }
  
}






