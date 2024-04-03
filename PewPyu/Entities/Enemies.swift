//
//  BossEntity.swift
//  PewPyu
//
//  Created by Kasia Rivers on 4/2/24.
//

import SpriteKit
import GameplayKit

// 1
class Enemy: GKEntity {

  init(imageName: String) {
    super.init()

    // 2
    let spriteComponent = SpriteComponent(texture: SKTexture(imageNamed: imageName))
    addComponent(spriteComponent)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

