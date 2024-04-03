//
//  GameScene.swift
//  PewPyu
//
//  Created by Kasia Rivers on 3/19/24.
//

#warning("TO DO: Make a high score tracker - ask Maria about this")

#warning("TO DO: Make a boss who takes longer to kill")

#warning("TO DO: Add player movement")

#warning("TO DO: Try not to store ALL of this in the GameScene")


import SpriteKit
import GameplayKit

//FIXME: Try using GameplayKit entities and components.

struct PhysicsCategory {
    static let none      : UInt32 = 0
    static let all       : UInt32 = UInt32.max
    static let monster   : UInt32 = 0b1       // 1
    static let projectile: UInt32 = 0b10      // 2
}

/* NOTE:
 
 The next four functions use operator overloading to adjust how the basic operators interact with CGPoints and CGFloats.
 
 This will improve the readability of the rest of the code.
 */

// (+) Addition
func +(left: CGPoint, right: CGPoint) -> CGPoint {
    // adds one point to another
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

// (-) Subtraction
func -(left: CGPoint, right: CGPoint) -> CGPoint {
    // subtracts one point from another, right point is subtracted from left
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

// (*) Multiplication
func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
    // multiplies both parts of a point by a scalar
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

// (/) Division
func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
    // divides both parts of a point by a scalar
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

//Some stuff I honestly don't fully understand yet that ensures compatibility across different architecture??
#if !(arch(x86_64) || arch(arm64))
func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
}
#endif

// Extending functionality of CGPoint struct
extension CGPoint {
    
    // Adds function to calculate the length of a vector using pythagorean theorem
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    /* NOTE:
     
     Normalizing is taking a vector of any length and, without changing its direction, changing its length to 1.
     
     The normalized() function divides each part of a CGPoint by its own length, scaling it down to a unit vector.
     
     */
    func normalized() -> CGPoint {
        return self / length()
    }
}

class GameScene: SKScene {
    
    private var hapticManager: HapticManager?
    
    var monstersDestroyed = 0

    let player = SKSpriteNode(imageNamed: "player") // setting up a sprite for the player
    
    /* NOTE:
     
     didMove(to view:) is a built-in method of SKScene that gets called when scene, GameScene, in this case, is presented in a view.
     
     */
    
    override func didMove(to view: SKView) { 
        
        hapticManager = HapticManager()
       
        backgroundColor = SKColor.white //set bg color to white
       
        // position "player" sprite 10% across horizontally, and 50% vertically (centered)
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        
        addChild(player) // add the sprite as a child of the scene to make it appear on screen
        
        /* PHYSICS:
         Scenes automatically create a physics world
         */
        physicsWorld.gravity = .zero // setting our physics world to have no gravity
        physicsWorld.contactDelegate = self // setting self (the GameScene) as responsible for handling contact between objects
        
    
        let delay = SKAction.wait(forDuration: 4.0)
        let addMonsters = SKAction.sequence([SKAction.run(addMonster),
                                             SKAction.wait(forDuration: 0.75)])
        
        // running a sequence of actions to repeat forever, with 1 second pauses in between
        run(SKAction.sequence([delay, SKAction.repeatForever(addMonsters)]))
        
        let backgroundMusic = SKAudioNode(fileNamed: "background-music-aac.caf")
        backgroundMusic.autoplayLooped = true
        addChild(backgroundMusic)
    }
    
    // Function to return a random CGFloat number between 0.0 and 1.0
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    /* NOTE (how this ^ is working):
        1. arc4random() generates a random unsigned 32 bit integer
        2. Float() turns that into a floating point number
        3. 0xFFFFFFFF represents the max value of 32 bit ints. dividing by it will "normalize" and ensure we get a value between 0.0 and 1.0
        4. CGFloat converts it into CGFloat for graphics reasons?
     */
    
    // Function to generate random numbers within a specified range
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    /* NOTES:
     Will be using the random functions for height calculations later, but these notes are just to explain the math to myself.
     
     random() will generate a random 0.0 to 1.0 number
     Subtract the minimum height from the maximum and multiply that by the random number
     */

    // MARK: - Monster
    
    func addMonster() {
        
        let monsterSprites: [String] = ["monster", "redMonster", "blueMonster", "greenMonster"]
        let mColors = Int.random(in: 0..<monsterSprites.count) // this is to change the color of the monster at random every time one is added to the scene
        
        // Create sprite
        let monster = SKSpriteNode(imageNamed: monsterSprites[mColors])
        
        // Determine where to spawn the monster along the Y axis
        let actualY = random(min: monster.size.height/2, max: size.height - monster.size.height/2)
        /* NOTES:
        
        So if the min height is half the size of the monster (ex: 5), and the max is the size of the screen minus the half the height of the monster (ex: 20-5 = 15).
        Then we'll get a random number like 0.3, do (15-5) = 10, multiply 0.3 by 10 to get 3 and then add 5 to that to choose the y position.
        */
        
        // Position the monster slightly off-screen along the right edge, and along a random position along the Y axis as calculated above
        monster.position = CGPoint(x: size.width + monster.size.width/2, y: actualY)
        
        addChild(monster)  // Add the monster to the scene
        
        //MONSTER PHYSICS
        monster.physicsBody = SKPhysicsBody(rectangleOf: monster.size) // make the physics body a rectangle the same size as the monster sprite
        monster.physicsBody?.isDynamic = true // this means the physics engine won't control the movement of the monster - i will with the move actions i wrote
        monster.physicsBody?.categoryBitMask = PhysicsCategory.monster //  setting the physics category of the monster
        monster.physicsBody?.contactTestBitMask = PhysicsCategory.projectile // says what categories of object the object should tell the contact listener about intersections with
        monster.physicsBody?.collisionBitMask = PhysicsCategory.none // essentially establishes that i dont want this object to be affected by collisions
        
        
        // Determine speed of the monster
        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
        
        // ACTIONS
    
        // make the monster move to a point off screen
        let actionMove = SKAction.move(to: CGPoint(x: -monster.size.width/2, y: actualY),
                                       duration: TimeInterval(actualDuration))
        
        // action to delete the instance
        let actionMoveDone = SKAction.removeFromParent()
        
        // sequence action to chain together a sequence of actions one at a time in order
        let loseAction = SKAction.run() { [weak self] in // weak reference to self for memory reasons
            guard let `self` = self else { return }
            // basically checking if the sequence even got to the point of executing the lose action
            // if the monster finishes its movement off screen, you lose
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOverScene = GameOverScene(size: self.size, won: false)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
        monster.run(SKAction.sequence([actionMove, loseAction, actionMoveDone]))
    }

    /* NOTE:
    toucheEnded() is a method from superclass
     
    It runs automatically when a user finishes touching the screen.
    Takes a set of touches, and an optional parameter that can describe if the touch had an associated UI event or additional info abt the touch
     */
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        //make sure there is a touch, otherwise dont do anything. if there is a touch, assign the first touch to the touch constant
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.location(in: self) // constant to store the location of touch within the current scene
        
        hapticManager?.playShoot() // play the shooting haptic pattern
        run(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false)) // play the shooting sound
        
        
        // Set up initial location of projectile
        let projectile = SKSpriteNode(imageNamed: "projectile")
        projectile.position = player.position
        
        // PROJECTILE PHYSICS
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2) // physics body = circle
        projectile.physicsBody?.isDynamic = true // same as before i control movement
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.projectile // set category bitmask
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.monster // notify me when u run into a monster
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.none // dont bounce off of other things!
        projectile.physicsBody?.usesPreciseCollisionDetection = true // need to set for fast moving bodies to make sure they get detected in collisions
        
        
        let offset = touchLocation - projectile.position // determine offset of location to projectile
        
        if offset.x < 0 { return } // if the x coordinate of the the offset is less than zero, that is an attempt to shoot down or backwards. do not.
        
        addChild(projectile)
        
        let direction = offset.normalized()  // get the direction of where to shoot
        
        let shootAmount = direction * 1000
        let realDest = shootAmount + projectile.position // add the shoot amount to the current position
        
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
        if monstersDestroyed > 15 {
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOverScene = GameOverScene(size: self.size, won: true)
            view?.presentScene(gameOverScene, transition: reveal)
        }
        
    }
    
}

extension GameScene: SKPhysicsContactDelegate {
    
    // This will get called when the GameScene is notified about a contact, according to what we said we wanted to be notified about before.
    func didBegin(_ contact: SKPhysicsContact) {
        // 1
        // categorizes contacts and makes sure they're ordered properly regardless of the order theyre reported in
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
            if let monster = firstBody.node as? SKSpriteNode, //tries to cast the node properties of each thing as SKSpriteBodes
               let projectile = secondBody.node as? SKSpriteNode {
                projectileDidCollideWithMonster(projectile: projectile, monster: monster) //calls our function
            }
        }
    }
}
