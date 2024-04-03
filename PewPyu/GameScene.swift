//
//  GameScene.swift
//  PewPyu
//
//  Created by Kasia Rivers on 3/19/24.
//

#warning("High score tracker thing - maria")

#warning("Different monster and/or every guy has a different skin")

#warning("BOMB SOMETIMES")

#warning("Make a boss who takes longer to kill")

#warning("Player movement")

import SpriteKit

struct PhysicsCategory {
  static let none      : UInt32 = 0
  static let all       : UInt32 = UInt32.max
  static let monster   : UInt32 = 0b1       // 1
  static let projectile: UInt32 = 0b10      // 2
  static let boss      : UInt32 = 0b100     // 3
  #warning ("try adding new category")
}


// operator overloading. making it add CG Points by adding their respective x values together, and then also adding their respective y values and returning a new cgPoint
func +(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

// same as above but with subtraction
func -(left: CGPoint, right: CGPoint) -> CGPoint {
  return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

// operator overloading so * multiplies both parts of a point by a scalar
func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

// same as above but with division
func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
  return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

//some stuff i don't understand that ensures compatibility across different architecture??
#if !(arch(x86_64) || arch(arm64))
  func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
  }
#endif

// extending functionality of CGPoint struct
extension CGPoint {
  
  //adds function to calculate the length of a vector  using pythagorean theorem
  func length() -> CGFloat {
    return sqrt(x*x + y*y)
  }
  
  //normalizing is a vector with the same direction as normal but with a length of 1, so this function divides each part of a CGPoint by its length, scaling it down to a unit vector.
  func normalized() -> CGPoint {
    return self / length()
  }
}
var entityManager: EntityManager!


class GameScene: SKScene {
    
    private var hapticManager: HapticManager?
    // 1 SETTING UP PLAYER SPRITE
    // private constant for player. pass in the name of an image to use for a sprite
    let player = SKSpriteNode(imageNamed: "player")
    
    var monstersDestroyed = 0
    var bossHits = 0
    
    var spawnBoss: Bool = false
    
    // MARK: - Random functions
    
    // random function to return a random CGFloat number between 0.0 and 1.0
    //lots of confusing stuff here
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    // arc4random() generates a random unsigned 32 bit integer.
    // Float() turns that into a floating point number
    // 0xFFFFFFFF represents the max value of 32 bit ints. dividing by it will "normalize" and ensure we get a vlue between 0.0 and 1.0
    //CGFloat converts it into CGFloat for graphics reasons?
    
    //function to generate random numbers within a specified range
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    // using this for height calculations below, we're putting a minimum and maximum spawn height
    // i need dumb notes about the math so
    // random() will generate a random 0.0 to 1.0 number. subtracting min height from max height and multiplying that by the random number
    
    //didMove is a built-in method of SKScene that gets called when the scene, GameScene, in this case, is presented in a view
    override func didMove(to view: SKView) { //didMove has one parameter to say which view the scene was moved to. here, the scene was moved to SKView
        hapticManager = HapticManager()
        // 2
        backgroundColor = SKColor.white //set bg color to white
        
        // 3
        // position "player" sprite 10% across horizontally, and 50% vertically (centered)
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        
        // 4
        addChild(player) // add the sprite as a child of the scene to make it appear on screen
        
        //PHYSICS
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        
        let delay = SKAction.wait(forDuration: 4.0)
        let addMonsters = SKAction.sequence([SKAction.run(addMonster),
                                             SKAction.wait(forDuration: 0.75)])
        
        let enterTy = SKAction.run(addBoss)
        
        let bossGo: (Bool) -> SKAction = { (check: Bool) -> SKAction in
            if check == true {
                return enterTy
            } else {
                return SKAction.wait(forDuration: 0.01)
            }
        }
        
        // running a sequence of actions to repeat forever, with 1 second pauses in between
        run(SKAction.sequence([delay, bossGo(spawnBoss), SKAction.repeatForever(addMonsters)]))
        
        
        let backgroundMusic = SKAudioNode(fileNamed: "background-music-aac.caf")
        backgroundMusic.autoplayLooped = true
        addChild(backgroundMusic)
        
        // GameplayKit stuff
        entityManager = EntityManager(scene: self)
        
        let monsterSprites: [String] = ["monster", "redMonster", "blueMonster", "greenMonster"]
        let mColors = Int.random(in: 0..<monsterSprites.count)
        
        let normalEnemy = Enemy(imageName: monsterSprites[mColors])
        
        let bossEnemy = Enemy(imageName: "boss")
        if let spriteComponent = bossEnemy.component(ofType: SpriteComponent.self) {
            spriteComponent.node.position = CGPoint(x: size.width - spriteComponent.node.size.width/2, y: size.height/2)
        }
        entityManager.add(bossEnemy)
        
    }
    
    // MARK: - monster function
    
    func addMonster() {
        
        let monsterSprites: [String] = ["monster", "redMonster", "blueMonster", "greenMonster"]
        let mColors = Int.random(in: 0..<monsterSprites.count)
        
        // Create sprite
        let monster = SKSpriteNode(imageNamed: monsterSprites[mColors])
        
        // Determine where to spawn the monster along the Y axis
        let actualY = random(min: monster.size.height/2, max: size.height - monster.size.height/2) //INVESTIGATE WHY THESE CALCULATIONS AT SOME POINT!!!!!!!
        // so if the min height is half the size of the monster (ex: 5), and the max is the size of the screen minus the half the height of the monster (ex: 20-5 = 15)
        // then we'll get a random number like 0.3, do (15-5) = 10, multiply 0.3 by 10 to get 3 and then add 5 to that to choose the y position
        
        
        // Position the monster slightly off-screen along the right edge,
        // and along a random position along the Y axis as calculated above
        monster.position = CGPoint(x: size.width + monster.size.width/2, y: actualY)
        
        // Add the monster to the scene
        addChild(monster)
        
        //MONSTER PHYSICS
        monster.physicsBody = SKPhysicsBody(rectangleOf: monster.size) // 1 make the physics body a rectangle the same size as the monster sprite
        monster.physicsBody?.isDynamic = true // 2 this means the physics engine won't control the movement of the monster - i will with the move actions i wrote
        monster.physicsBody?.categoryBitMask = PhysicsCategory.monster // 3  setting the category bitmask
        monster.physicsBody?.contactTestBitMask = PhysicsCategory.projectile // 4 says what categories of object the object should tell the contact listener about intersections with
        monster.physicsBody?.collisionBitMask = PhysicsCategory.none // 5 lets them move through each other
        
        
        
        // Determine speed of the monster
        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
        
        // Create the actions
        
        // SKAction.move is an action we are using to make the monster move off-screen to the left.
        // specifying how long the movement should take with puttin the actualDuration/speed in as a time interval for the duration parameter
        let actionMove = SKAction.move(to: CGPoint(x: -monster.size.width/2, y: actualY),
                                       duration: TimeInterval(actualDuration))
        
        // basically a delete instance action
        let actionMoveDone = SKAction.removeFromParent()
        
        //if any monsters finish their movement off screen, you lose.
        // sequence action to chain together a sequence of actions one at a time in order
        let loseAction = SKAction.run() { [weak self] in
            guard let `self` = self else { return }
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOverScene = GameOverScene(size: self.size, won: false)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
        monster.run(SKAction.sequence([actionMove, loseAction, actionMoveDone]))
        
    }
    
 // MARK: - BOSS STUFF
      func addBoss() {
        let boss = SKSpriteNode(imageNamed: "boss")
//        let actualY = random(min: boss.size.height/2, max: size.height - boss.size.height/2)
    
        boss.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
    
        addChild(boss)
    
        boss.physicsBody = SKPhysicsBody(rectangleOf: boss.size)
        boss.physicsBody?.isDynamic = true
        boss.physicsBody?.categoryBitMask = PhysicsCategory.boss
        boss.physicsBody?.contactTestBitMask = PhysicsCategory.projectile
        boss.physicsBody?.collisionBitMask = PhysicsCategory.none
    
        let actionMove = SKAction.move(to: CGPoint(x: size.width * 0.6, y: size.height * 0.5),
                                       duration: TimeInterval(2))
    
//        let actionMoveDone = SKAction.removeFromParent()
    
//        boss.run(SKAction.sequence([actionMove, actionMoveDone])
        boss.run(actionMove)
    
      }
    
    
    
    // method from superclass
    // touchesEnded runs automatically when a user finishes touching the screen. it takes a set of touches, and an optional parameter that can describe if the touch had an associated UI event or additional info abt the touch
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // 1 - Choose one of the touches to work with
        //make sure there is a touch, otherwise dont do anything. if there is a touch, assign the first touch to the touch constant
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.location(in: self) // constant to store the location of touch within the current scene
        
        hapticManager?.playShoot()
        run(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))
        
        
        
        // 2 - Set up initial location of projectile
        let projectile = SKSpriteNode(imageNamed: "projectile")
        projectile.position = player.position
        
        // PROJECTILE PHYSICS
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2) // physics body = circle
        projectile.physicsBody?.isDynamic = true // same as before i control movement
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.projectile // set category bitmask
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.monster // notify me when u run into a monster
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.boss
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.none // dont bounce off each other
        projectile.physicsBody?.usesPreciseCollisionDetection = true // need to set for fast moving bodies to make sure they get detected in collisions
        
        
        // 3 - Determine offset of location to projectile
        let offset = touchLocation - projectile.position
        
        // 4 - Bail out if you are shooting down or backwards
        if offset.x < 0 { return }
        
        // 5 - OK to add now - you've double checked position
        addChild(projectile)
        
        // 6 - Get the direction of where to shoot
        let direction = offset.normalized()
        
        // 7 - Make it shoot far enough to be guaranteed off screen
        let shootAmount = direction * 1000
        
        // 8 - Add the shoot amount to the current position
        let realDest = shootAmount + projectile.position
        
        // 9 - Create the actions
        let actionMove = SKAction.move(to: realDest, duration: 2.0)
        let actionMoveDone = SKAction.removeFromParent()
        projectile.run(SKAction.sequence([actionMove, actionMoveDone]))
    }
    
    // collision function to print hit and remove both the projectile and monster when called
    func projectileDidCollideWithMonster(projectile: SKSpriteNode, monster: SKSpriteNode) {
        print("Hit")
        projectile.removeFromParent()
        monster.removeFromParent()
        
        monstersDestroyed += 1
        if monstersDestroyed == 5 {
//            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
//            let gameOverScene = GameOverScene(size: self.size, won: true)
//            view?.presentScene(gameOverScene, transition: reveal)
            spawnBoss = true
        }
    }
    
    
        func projectileDidCollideWithBoss(projectile: SKSpriteNode, boss: SKSpriteNode) {
          print("Hit")
          projectile.removeFromParent()
    
          bossHits += 1
          if bossHits > 3 {
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOverScene = GameOverScene(size: self.size, won: true)
            view?.presentScene(gameOverScene, transition: reveal)
          }
    
        }
    
    }


extension GameScene: SKPhysicsContactDelegate {
  
  func didBegin(_ contact: SKPhysicsContact) {
    // 1
    // basically categorizes contacts and makes sure they're ordered properly regardless of the order theyre reported in
    var firstBody: SKPhysicsBody
    var secondBody: SKPhysicsBody
    if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
      firstBody = contact.bodyA
      secondBody = contact.bodyB
    } else {
      firstBody = contact.bodyB
      secondBody = contact.bodyA
    }
    
   
    // 2
    // checks if firstBody and secondBody match the desired categories
    if ((firstBody.categoryBitMask & PhysicsCategory.monster != 0) &&
        (secondBody.categoryBitMask & PhysicsCategory.projectile != 0)) {
      if let monster = firstBody.node as? SKSpriteNode, //tries to cast the node properties of each thing as SKSpriteNodes
        let projectile = secondBody.node as? SKSpriteNode {
        projectileDidCollideWithMonster(projectile: projectile, monster: monster) //calls our function
      }
    } else if ((firstBody.categoryBitMask & PhysicsCategory.boss != 0) &&
               (secondBody.categoryBitMask & PhysicsCategory.projectile != 0)) {
        if let boss = firstBody.node as? SKSpriteNode,
           let projectile = secondBody.node as? SKSpriteNode {
            projectileDidCollideWithBoss(projectile: projectile, boss: boss)
        }
    }
  }
}
