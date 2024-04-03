//
//  GameOverScene.swift
//  PewPyu
//
//  Created by Kasia Rivers on 3/19/24.
//

import Foundation
import SpriteKit

class GameOverScene: SKScene {
  init(size: CGSize, won:Bool) {
    super.init(size: size)

    let message = won ? ("You Won!", backgroundColor = SKColor.green) : ("You Lose :[", backgroundColor = SKColor.red)
    
    let label = SKLabelNode(fontNamed: "Chalkduster")
    label.text = message.0
    label.fontSize = 40
    label.fontColor = SKColor.white
    label.position = CGPoint(x: size.width/2, y: size.height/2)
    addChild(label)
    
   
    run(SKAction.sequence([
      SKAction.wait(forDuration: 3.0),
      SKAction.run() { [weak self] in
        guard let `self` = self else { return }
        let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
        let scene = GameScene(size: size)
        self.view?.presentScene(scene, transition:reveal)
      }
      ]))
   }

  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

