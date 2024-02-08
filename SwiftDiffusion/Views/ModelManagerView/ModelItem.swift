//
//  ModelItem.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/8/24.
//

import Foundation
import Combine

@MainActor
class ModelItem: ObservableObject, Identifiable {
  let id = UUID()
  let name: String
  let type: ModelType
  let url: URL
  var isDefaultModel: Bool = false
  @Published var preferences: ModelPreferences
  
  init(name: String, type: ModelType, url: URL, isDefaultModel: Bool = false) {
    self.name = name
    self.type = type
    self.url = url
    self.isDefaultModel = isDefaultModel
    self.preferences = ModelPreferences.defaultForModelType(type: type)
  }
}

enum ModelType {
  case coreMl
  case python
}

class ModelPreferences: ObservableObject {
  @Published var samplingMethod: String
  @Published var positivePrompt: String = ""
  @Published var negativePrompt: String = ""
  @Published var width: Double = 512
  @Published var height: Double = 512
  @Published var cfgScale: Double = 7
  @Published var samplingSteps: Double = 20
  @Published var clipSkip: Double = 1
  @Published var batchCount: Double = 1
  @Published var batchSize: Double = 1
  @Published var seed: String = "-1"
  
  // Initialize with default values or specific values as needed
  init(samplingMethod: String = "DPM-Solver++") {
    self.samplingMethod = samplingMethod
  }
  
  static func defaultForModelType(type: ModelType) -> ModelPreferences {
    let samplingMethod: String
    switch type {
    case .coreMl:
      samplingMethod = "DPM-Solver++"
    case .python:
      samplingMethod = "DPM++ 2M Karras"
    }
    return ModelPreferences(samplingMethod: samplingMethod)
  }
}
