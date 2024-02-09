//
//  ModelPreferencesView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/8/24.
//

import CompactSlider
import SwiftUI

extension Constants {
  static let coreMLSamplingMethods = ["DPM-Solver++", "PLMS"]
  static let pythonSamplingMethods = [
    "DPM++ 2M Karras", "DPM++ SDE Karras", "DPM++ 2M SDE Exponential", "DPM++ 2M SDE Karras", "Euler a", "Euler", "LMS", "Heun", "DPM2", "DPM2 a", "DPM++ 2S a", "DPM++ 2M", "DPM++ SDE", "DPM++ 2M SDE", "DPM++ 2M SDE Heun", "DPM++ 2M SDE Heun Karras", "DPM++ 2M SDE Heun Exponential", "DPM++ 3M SDE", "DPM++ 3M SDE Karras", "DPM++ 3M SDE Exponential", "DPM fast", "DPM adaptive", "LMS Karras", "DPM2 Karras", "DPM2 a Karras", "DPM++ 2S a Karras", "Restart", "DDIM", "PLMS", "UniPC", "LCM"
  ]
}

struct ModelPreferencesView: View {
  @Binding var modelItem: ModelItem
  @ObservedObject var modelPreferences: ModelPreferences
  @Environment(\.presentationMode) var presentationMode
  
  // Use an ObservableObject for temporary editing
  @StateObject private var temporaryPreferences: ModelPreferences
  
  init(modelItem: Binding<ModelItem>, modelPreferences: ModelPreferences) {
    self._modelItem = modelItem
    self._modelPreferences = ObservedObject(initialValue: modelPreferences)
    self._temporaryPreferences = StateObject(wrappedValue: ModelPreferences.copy(from: modelPreferences))
  }
  
  var body: some View {
    VStack {
      ScrollView {
        VStack(alignment: .leading) {
          Text(modelItem.name)
            .font(.system(.body, design: .monospaced))
            .truncationMode(.middle)
            .padding(.top, 8)
          
          samplingMenu
          
          DimensionSelectionRow(width: $temporaryPreferences.width, height: $temporaryPreferences.height)
          
          DetailSelectionRow(cfgScale: $temporaryPreferences.cfgScale, samplingSteps: $temporaryPreferences.samplingSteps)
          
          HStack {
            HalfMaxWidthView {}
            
            CompactSlider(value: $temporaryPreferences.clipSkip, in: 1...12, step: 1) {
              Text("Clip Skip")
              Spacer()
              Text("\(Int(temporaryPreferences.clipSkip))")
            }
          }
          
          //seedSection
        }
        .padding(14)
        .padding(.horizontal, 8)
      }
      
      saveCancelButtons
    }
    .navigationTitle("Model Preferences")
    .frame(minWidth: 300, idealWidth: 400, minHeight: 250, idealHeight: 430)
  }
  
  private var samplingMenu: some View {
    VStack(alignment: .leading) {
      PromptRowHeading(title: "Sampling")
      Menu {
        let samplingMethods = modelItem.type == .coreMl ? Constants.coreMLSamplingMethods : Constants.pythonSamplingMethods
        ForEach(samplingMethods, id: \.self) { method in
          Button(method) {
            temporaryPreferences.samplingMethod = method
          }
        }
      } label: {
        Label(temporaryPreferences.samplingMethod, systemImage: "square.stack.3d.forward.dottedline")
      }
    }
    .padding(.vertical, Constants.Layout.promptRowPadding)
  }
  
  private var seedSection: some View {
    VStack(alignment: .leading) {
      PromptRowHeading(title: "Seed")
        .padding(.leading, 8)
      HStack {
        TextField("", text: $temporaryPreferences.seed)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .font(.system(.body, design: .monospaced))
        Button(action: {
          temporaryPreferences.seed = "-1"
        }) {
          Image(systemName: "shuffle")
        }
        .buttonStyle(BorderlessButtonStyle())
      }
    }
    .padding(.bottom, Constants.Layout.promptRowPadding)
  }
  
  private var saveCancelButtons: some View {
    HStack {
      Button("Cancel") {
        presentationMode.wrappedValue.dismiss()
      }
      Spacer()
      Button("Save Model Preferences") {
        applyPreferences()
        presentationMode.wrappedValue.dismiss()
      }
    }
    .padding(.horizontal)
    .padding(.bottom, 12)
  }
  
  private func applyPreferences() {
    modelItem.preferences.update(from: temporaryPreferences)
  }
}


#Preview {
  let item = ModelItem(name: "some_model.safetensor", type: .python, url: URL(string: "file://path/to/package")!)
  item.preferences = ModelPreferences(samplingMethod: "DPM++ 2M Karras")
  
  return ModelPreferencesView(modelItem: .constant(item), modelPreferences: item.preferences)
    .frame(width: 400, height: 350)
}


extension ModelPreferences {
  static func copy(from preferences: ModelPreferences) -> ModelPreferences {
    let copy = ModelPreferences(samplingMethod: preferences.samplingMethod)
    copy.positivePrompt = preferences.positivePrompt
    copy.negativePrompt = preferences.negativePrompt
    copy.width = preferences.width
    copy.height = preferences.height
    copy.cfgScale = preferences.cfgScale
    copy.samplingSteps = preferences.samplingSteps
    copy.clipSkip = preferences.clipSkip
    copy.batchCount = preferences.batchCount
    copy.batchSize = preferences.batchSize
    copy.seed = preferences.seed
    return copy
  }
  
  // Ensure this method exists to apply changes from the temporary preferences
  func update(from preferences: ModelPreferences) {
    self.samplingMethod = preferences.samplingMethod
    self.positivePrompt = preferences.positivePrompt
    self.negativePrompt = preferences.negativePrompt
    self.width = preferences.width
    self.height = preferences.height
    self.cfgScale = preferences.cfgScale
    self.samplingSteps = preferences.samplingSteps
    self.clipSkip = preferences.clipSkip
    self.batchCount = preferences.batchCount
    self.batchSize = preferences.batchSize
    self.seed = preferences.seed
  }
}
