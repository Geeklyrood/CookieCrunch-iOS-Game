//
//  GameScene.swift
//  CookieCrunch
//
//  Created by Andrews, George on 2/21/17.
//  Copyright © 2017 Andrews, George. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
  
  var level: Level!
  
  let tileWidth: CGFloat = 32.0
  let tileHeight: CGFloat = 36.0
  
  let gameLayer = SKNode()
  let cookiesLayer = SKNode()
  let tilesLayer = SKNode()
  
  private var swipeFromColumn: Int?
  private var swipeFromRow: Int?
  
  var swipeHandler: ((Swap) -> ())?
  
  var selectionSprite = SKSpriteNode()
  
  // Game Sounds
  let swapSound = SKAction.playSoundFileNamed("Chomp.wav", waitForCompletion: false)
  let invalidSwapSound = SKAction.playSoundFileNamed("Error.wav", waitForCompletion: false)
  let matchSound = SKAction.playSoundFileNamed("Ka-Ching.wav", waitForCompletion: false)
  let fallingCookieSound = SKAction.playSoundFileNamed("Scrape.wav", waitForCompletion: false)
  let addCookieSound = SKAction.playSoundFileNamed("Drip.wav", waitForCompletion: false)
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override init(size: CGSize) {
    super.init(size: size)
    
    anchorPoint = CGPoint(x: 0.5, y: 0.5)
    
    let background = SKSpriteNode(imageNamed: "Background")
    background.size = size
    addChild(background)
    
    // gameLayer and cookiesLayer are two transparent planes or layers
    addChild(gameLayer)
    
    let layerPosition = CGPoint(x: -tileWidth * CGFloat(NumColumns) / 2,
                                y: -tileHeight * CGFloat(NumRows) / 2)
    
    cookiesLayer.position = layerPosition
    tilesLayer.position = layerPosition
    
    gameLayer.addChild(tilesLayer)
    gameLayer.addChild(cookiesLayer)
    
    swipeFromColumn = nil
    swipeFromRow = nil
  }
  
  func addSprites(for cookies: Set<Cookie>) {
    for cookie in cookies {
      
      // create that cookie's sprite
      let sprite = SKSpriteNode(imageNamed: cookie.cookieType.spriteName)
      sprite.size = CGSize(width: tileWidth, height: tileHeight)
      sprite.position = pointFor(column: cookie.column, row: cookie.row)
      cookiesLayer.addChild(sprite)
      cookie.sprite = sprite
    }
  }
  
  func addTiles() {
    for row in 0..<NumRows {
      for column in 0..<NumColumns {
        if level.tileAt(column: column, row: row) != nil {
          
          // create sprite for the tile
          let tileNode = SKSpriteNode(imageNamed: "Tile")
          tileNode.size = CGSize(width: tileWidth, height: tileHeight)
          tileNode.position = pointFor(column: column, row: row)
          tilesLayer.addChild(tileNode)
          
        }
      }
    }
  }
  
  func pointFor(column: Int, row: Int) -> CGPoint {
    return CGPoint(
      x: CGFloat(column) * tileWidth + tileWidth / 2,
      y: CGFloat(row) * tileHeight + tileHeight / 2)
    
  }
  
  func convertPoint(point: CGPoint) -> (success: Bool, column: Int, row: Int) {
    if point.x >= 0 && point.x < CGFloat(NumColumns) * tileWidth
      && point.y >= 0 && point.y < CGFloat(NumRows) * tileHeight {
      return (true, Int(point.x / tileWidth), Int(point.y / tileHeight))
    } else {
      return (false, 0, 0) // invalid location
    }
  }
  
  // MARK: - Handling Gestures
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    
    guard let touch = touches.first else { return }
    let location = touch.location(in: cookiesLayer)
    
    // if we find a touch, check to see if it is inside the grid
    let (success, column, row) = convertPoint(point: location)
    
    if success {
      if let cookie = level.cookieAt(column: column, row: row) {
        swipeFromColumn = cookie.column
        swipeFromRow = cookie.row
        
        showSelectionIndicatorForCookie(cookie: cookie)
      }
    }
    
  }
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    
    guard swipeFromColumn != nil else { return }
    
    guard let touch = touches.first else { return }
    let location = touch.location(in: cookiesLayer)
    
    let (success, column, row) = convertPoint(point: location)
    if success {
      
      var horzDelta = 0, vertDelta = 0
      
      if column < swipeFromColumn! { // swiping left
        horzDelta = -1
      } else if column > swipeFromColumn! { // swiping right
        horzDelta = 1
      } else if row < swipeFromRow! { // swiping down
        vertDelta = -1
      } else if row > swipeFromRow! { // swiping up
        vertDelta = 1
      }
      
      if horzDelta != 0 || vertDelta != 0 {
        
        trySwap(horizontal: horzDelta, vertical: vertDelta)
        
        hideSelectionIndicator()
        
        swipeFromColumn = nil // GameScene will ignore the rest of this swipe motion
      }
      
    }
    
  }
  
  func trySwap(horizontal horzDelta: Int, vertical vertDelta: Int) {
    
    // Calculate column and row of cookie to swap with
    let toColumn = swipeFromColumn! + horzDelta
    let toRow = swipeFromRow! + vertDelta
    
    // Ignore any swipe that will occur outside our level
    guard toColumn >= 0 && toColumn < NumColumns else {
      return
    }
    guard toRow >= 0 && toRow < NumRows else { return }
    
    // Ignore any swipe that will be to a tile without a cookie
    if let toCookie = level.cookieAt(column: toColumn, row: toRow),
      let fromCookie = level.cookieAt(column: swipeFromColumn!, row: swipeFromRow!) {
      
      // try to swap the cookies
      print("Trying to swap from: \(fromCookie) to: \(toCookie)")
      if let handler = swipeHandler {
        let swap = Swap(cookieA: fromCookie, cookieB: toCookie)
        handler(swap)
      }

    }
    
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    
    if selectionSprite.parent != nil, swipeFromColumn != nil {
      hideSelectionIndicator()
    }
    
    swipeFromColumn = nil
    swipeFromRow = nil
  }
  
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    touchesEnded(touches, with: event)
  }
  
  // MARK: - Animating Swaps
  func animate(_ swap: Swap, completion: @escaping () -> ()) {
    let spriteA = swap.cookieA.sprite!
    let spriteB = swap.cookieB.sprite!
    
    spriteA.zPosition = 100
    spriteB.zPosition = 90
    
    let duration: TimeInterval = 0.3
    
    let moveA = SKAction.move(to: spriteB.position, duration: duration)
    moveA.timingMode = .easeOut
    spriteA.run(moveA, completion: completion)
    
    let moveB = SKAction.move(to: spriteA.position, duration: duration)
    moveB.timingMode = .easeOut
    spriteB.run(moveB)
    
    run(swapSound)
    
  }
  
  func showSelectionIndicatorForCookie(cookie: Cookie) {
    
    if selectionSprite.parent != nil {
      selectionSprite.removeFromParent()
    }
    
    if let sprite = cookie.sprite {
      
      let texture = SKTexture(imageNamed: cookie.cookieType.highlightedSpriteName)
      selectionSprite.size = CGSize(width: tileWidth, height: tileHeight)
      selectionSprite.run(SKAction.setTexture(texture))
      
      sprite.addChild(selectionSprite)
      selectionSprite.alpha = 1.0
      
    }
    
  }
  
  func hideSelectionIndicator() {
    selectionSprite.run(.sequence([.fadeOut(withDuration: 0.3), .removeFromParent()]))
  }
  
  // MARK: Animate Invalid Swaps
  func animateInvalidSwap(_ swap: Swap, completion: @escaping () -> ()) {
    
    let spriteA = swap.cookieA.sprite!
    let spriteB = swap.cookieB.sprite!
    
    spriteA.zPosition = 100
    spriteB.zPosition = 90
    
    let duration: TimeInterval = 0.2
    
    let moveA = SKAction.move(to: spriteB.position, duration: duration)
    moveA.timingMode = .easeOut
    
    let moveB = SKAction.move(to: spriteA.position, duration: duration)
    moveB.timingMode = .easeOut
    
    spriteA.run(SKAction.sequence([moveA, moveB]), completion: completion)
    spriteB.run(SKAction.sequence([moveB, moveA]))
    
    run(invalidSwapSound)
    
  }
  
  // MARK: Animate Matches
  
  func animateMatchedCookies(for chains: Set<Chain>, completion: @escaping () -> ()) {
    for chain in chains {
      for cookie in chain.cookies {
        if let sprite = cookie.sprite {
          
          if sprite.action(forKey: "removing") == nil {
            let scaleAction = SKAction.scale(by: 0.1, duration: 0.3)
            scaleAction.timingMode = .easeOut
            sprite.run(SKAction.sequence([scaleAction, SKAction.removeFromParent()]), withKey: "removing")
          }
          
        }
      }
    }
    run(matchSound)
    run(SKAction.wait(forDuration: 0.3), completion: completion)
  }
  
  // MARK: Animate Falling Cookies
  
  func animateFallingCookies(columns: [[Cookie]], completion: @escaping () -> ()) {
    
    var longestDuration: TimeInterval = 0
    
    for array in columns {
      
      for (idx, cookie) in array.enumerated() {
        
        let newPosition = pointFor(column: cookie.column, row: cookie.row)
        
        let delay = 0.05 + 0.15 * TimeInterval(idx)
        
        let sprite = cookie.sprite!
        let duration = TimeInterval(((sprite.position.y - newPosition.y) / tileHeight) * 0.1)
        
        longestDuration = max(longestDuration, duration + delay)
        
        let moveAction = SKAction.move(to: newPosition, duration: duration)
        moveAction.timingMode = .easeOut
        sprite.run(SKAction.sequence([
          SKAction.wait(forDuration: delay),
          SKAction.group([moveAction, fallingCookieSound])]))
        
      }
      
    }
    
    run(SKAction.wait(forDuration: longestDuration), completion: completion)
    
  }
  
}




