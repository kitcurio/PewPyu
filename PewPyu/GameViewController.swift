//
//  GameViewController.swift
//  PewPyu
//
//  Created by Kasia Rivers on 3/19/24.
//

import UIKit
import SpriteKit

// creating class named GameViewController that inherits from the UIViewController class
class GameViewController: UIViewController {
  
  
  // Override function to override the same method/function being used in the superclass (UIViewController)
  override func viewDidLoad() {
    
    super.viewDidLoad() // calls the viewDidLoad() method of UIViewController (the superclass)
    
    let scene = GameScene(size: view.bounds.size) // Creating instance of GameScene class passing in the size of the view as a parameter.
    
    let skView = view as! SKView // force casting view of the view controller to an SKView for displaying SpriteKit content
    
    skView.showsFPS = true // show the frames per second on screen
    
    skView.showsNodeCount = true // show the number of nodes in the scene (nodes represent objects in the game world)
    
    skView.ignoresSiblingOrder = true // ignore parent-child/sibling relationships when drawing nodes in the scene. draws them arbitrarily instead, relying exclusively on the z-position. improves performance.
    
    scene.scaleMode = .resizeFill //scale mode is resizing the scene to match (fill) the dimensions of the view
    
    skView.presentScene(scene) //displays the scene in the skView / displays game scene on screen
  }
  
  //overrides default behvaior of the status bar, so the status bar should be hidden
  override var prefersStatusBarHidden: Bool {
    return true
  }
  
}
