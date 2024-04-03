//
//  Haptics.swift
//  PewPyu
//
//  Created by Kasia Rivers on 3/19/24.
//

import CoreHaptics


class HapticManager {
  
  let hapticEngine: CHHapticEngine //holds a reference to CHHapticEngine
  
  /* NOTE:
    This is a failable initializer.
    
    On initializing, this will check if haptics are available, and if theyre not it will return nil & not initialize
   */
  init?() {
    let hapticCapability = CHHapticEngine.capabilitiesForHardware() //check if haptics are available
    guard hapticCapability.supportsHaptics else {
      return nil
    }
    

    // NOTE: do/catch blocks catch errors. This block will attempt to run the haptic engine.
    do {
      hapticEngine = try CHHapticEngine()
    } catch let error { // if there is an error, catch it, print the error & return nil
      print("Haptic engine Creation Error: \(error)")
      return nil
    }
  }
  
  
  func playShoot() {
    do {
      
      let pattern = try shootPattern()
      
      try hapticEngine.start() 
      
      let player = try hapticEngine.makePlayer(with: pattern) // creates a haptic pattern player with my pattern
      
      try player.start(atTime: CHHapticTimeImmediate)
      
      hapticEngine.notifyWhenPlayersFinished { _ in
        return .stopEngine // stop the haptic engine when the player finishes playing the pattern
      }
    } catch {
      print("Failed to play shoot: \(error)") // return the error if anything in the do block fails
    }
  }
}

extension HapticManager {
    // Defining a custom haptic pattern
  private func shootPattern() throws -> CHHapticPattern {
    let load = CHHapticEvent(
      eventType: .hapticContinuous,
      parameters: [
        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.05)
      ],
      relativeTime: 0,
      duration: 0.1)
    
    let shoot = CHHapticEvent(
      eventType: .hapticTransient,
      parameters: [
        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5 )
      ],
      relativeTime: 0)
    
    return try CHHapticPattern(events: [load, shoot], parameters: [])
  }
}

