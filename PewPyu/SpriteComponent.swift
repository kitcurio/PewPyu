//
//  BossComponent.swift
//  PewPyu
//
//  Created by Kasia Rivers on 4/2/24.
//

import Foundation
import GameplayKit
import SpriteKit

class SpriteComponent: GKComponent {
    let node: SKSpriteNode

      // 4
      init(texture: SKTexture) {
        node = SKSpriteNode(texture: texture, color: .white, size: texture.size())
        super.init()
      }
      
      // 5
      required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
      }
}
