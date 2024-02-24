//
//  ModelLoadState.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/9/24.
//

import Foundation

enum ModelLoadState: Equatable {
  case launching
  case done
  case isLoading
  case failed
  case idle
}

extension ModelLoadState {
  var allowGeneration: Bool {
    switch self {
    case .idle:       return true
    case .done:       return true
    case .failed:     return false
    case .isLoading:  return false
    case .launching:  return true
    }
  }
}

extension ScriptManager {
  
  func updateModelLoadStateBasedOnOutput(output: String) {
    Task {
      await parseAndUpdateModelLoadState(output: output)
    }
  }
  
  @MainActor
  func updateModelLoadState(to state: ModelLoadState) {
    modelLoadStateShouldExpire = false
    
    if modelLoadState != state { modelLoadState = state }
    
    Debug.log("[ModelLoadState] updateModelLoadState from: \(modelLoadState.debugInfo) → to: \(state.debugInfo)")
    
    if state == .done || state == .failed {
      modelLoadStateShouldExpire = true
      
      Delay.by(5) {
        if self.modelLoadStateShouldExpire {
          self.updateModelLoadTime(with: 0)
          self.modelLoadState = .idle
        }
      }
    }
  }
  
  @MainActor
  private func updateModelLoadTime(with time: Double = 0) {
    if modelLoadTime == time {
      return
    }
    
    modelLoadTime = time
    
    if time > 0 {
      //updateModelLoadState(to: .done)
      Debug.log("[ModelLoadState] updateModelLoadTime - Parsed model load time: \(time)")
    } else {
      Debug.log("[ModelLoadState] updateModelLoadTime - Resetting model load time to 0")
    }
  }
  
  // TODO: catch "Stable diffusion model failed to load" and throw
  
  func parseAndUpdateModelLoadState(output: String) async {
    Debug.log(">> \(output)")
    // ie. >> Update successful for model: DreamShaperXL_v2_Turbo_DpmppSDE.safetensors [4726d3bab1].
    if output.contains("Update successful for model") {
      //updateModelLoadState(to: .done)
    }
    
    // Check for model loading time
    if let _ = output.range(of: #"Model loaded in ([\d\.]+)s"#, options: .regularExpression) {
      let regex = try! NSRegularExpression(pattern: #"Model loaded in ([\d\.]+)s"#, options: [])
      let nsRange = NSRange(output.startIndex..<output.endIndex, in: output)
      if let match = regex.firstMatch(in: output, options: [], range: nsRange),
         let timeRange = Range(match.range(at: 1), in: output) {
        let timeString = String(output[timeRange])
        if let time = Double(timeString) {
          updateModelLoadTime(with: time)
        }
      }
    }
    
    // Check for thrown TypeError messages
    // ie. TypeError: Cannot convert a MPS Tensor to float64 dtype as the MPS framework doesn't support float64. Please use float32 instead.
    let typeErrorThrownMessages = [
      "TypeError: Cannot convert a MPS Tensor to"
    ]
    
    if typeErrorThrownMessages.contains(where: output.contains) {
      //updateModelLoadState(to: .failed)
      modelLoadTypeErrorThrown = true
    }
    // Check for update successful message
    let successRegex = try! NSRegularExpression(pattern: #"Update successful for model:(.*)"#, options: [])
    let successNsRange = NSRange(output.startIndex..<output.endIndex, in: output)
    if let _ = successRegex.firstMatch(in: output, options: [], range: successNsRange) {
      //updateModelLoadState(to: .done)
    }
    
    // ie. Weights loaded in 3.5s (send model to cpu: 1.1s, load weights from disk: 0.5s, apply weights to model: 0.7s, move model to device: 1.2s).
    let newPattern = #"Weights loaded in ([\d\.]+)s"#
    do {
      let regex = try NSRegularExpression(pattern: newPattern, options: [])
      let nsRange = NSRange(output.startIndex..<output.endIndex, in: output)
      
      if let match = regex.firstMatch(in: output, options: [], range: nsRange),
         let timeRange = Range(match.range(at: 1), in: output) {
        let timeString = String(output[timeRange])
        if let time = Double(timeString) {
          updateModelLoadTime(with: time)
        }
      }
    } catch {
      Debug.log("Regex error: \(error.localizedDescription)")
    }
  }
  
}

// .done:
// Model loaded in 4.6s (load weights from disk: 0.4s, create model: 0.7s, apply weights to model: 2.8s, move model to device: 0.2s, calculate empty prompt: 0.4s).
//
// .isLoading:
// Reusing loaded model DreamShaperXL_v2_Turbo_DpmppSDE.safetensors [4726d3bab1] to load v1-5-pruned-emaonly.safetensors [6ce0161689]
//
// Loading weights [6ce0161689] from /Users/jb/Dev/GitHub/stable-diffusion-webui/models/Stable-diffusion/v1-5-pruned-emaonly.safetensors
//
// .failed:
//
// .failedOnLaunch: // can go to other models, but cant go back to model that failed to load
//
// Startup time: 3.3s (import torch: 0.9s, import gradio: 0.4s, setup paths: 0.3s, other imports: 0.4s, load scripts: 0.3s, initialize extra networks: 0.4s, create ui: 0.2s).
//
// Applying attention optimization: sub-quadratic... done.
// ...
// Stable diffusion model failed to load
//
// Applying attention optimization: sub-quadratic... done.

// BIG TELL:
// TypeError: Cannot convert a MPS Tensor to float64 dtype as the MPS framework doesn't support float64. Please use float32 instead.
