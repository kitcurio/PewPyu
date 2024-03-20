//
//  Haptics.swift
//  PewPyu
//
//  Created by Kasia Rivers on 3/19/24.
//

import CoreHaptics

// making a class to manage haptics
class HapticManager {
  // 1
  //holds a reference to CHHapticEngine
  let hapticEngine: CHHapticEngine
  
  // 2
  //failable initializer, so on initializing, this will check if haptics are available, and if theyre not it will return nil/not initialize?
  init?() {
    // 3
    let hapticCapability = CHHapticEngine.capabilitiesForHardware()
    guard hapticCapability.supportsHaptics else {
      return nil
    }
    
    // 4
    //do/catch blocks catch errors. so this is trying to run the haptic engine
    do {
      hapticEngine = try CHHapticEngine()
    } catch let error { // if there is an error, catch it and print the error & return nil
      print("Haptic engine Creation Error: \(error)")
      return nil
    }
  }
  
  
  func playShoot() {
    do {
      // 1
      let pattern = try shootPattern()
      // 2
      try hapticEngine.start()
      // 3
      let player = try hapticEngine.makePlayer(with: pattern)
      // 4
      try player.start(atTime: CHHapticTimeImmediate)
      // 5
      hapticEngine.notifyWhenPlayersFinished { _ in
        return .stopEngine
      }
    } catch {
      print("Failed to play slice: \(error)")
    }
  }
}

extension HapticManager {
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

