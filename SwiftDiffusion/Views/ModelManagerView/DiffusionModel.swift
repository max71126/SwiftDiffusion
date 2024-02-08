//
//  DiffusionModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/6/24.
//

import Combine
import SwiftUI

struct ModelItem: Identifiable {
  let id = UUID()
  let name: String
  let type: ModelType
  var isDefaultModel: Bool = false
}

enum ModelType {
  case coreMl
  case python
}

@MainActor
class ModelManagerViewModel: ObservableObject {
  @Published var items: [ModelItem] = []
  
  private var coreMlObserver: DirectoryObserver?
  private var pythonObserver: DirectoryObserver?
  
  private let defaultCoreMLModelNames: [String] = ["defaultCoreMLModel1", "defaultCoreMLModel2"]
  private let defaultPythonModelNames: [String] = ["v1-5-pruned-emaonly.safetensors", "defaultPythonModel2"]
  
  func loadModels() async {
    do {
      let fileManager = FileManager.default
      var newItems: [ModelItem] = []
      
      guard let coreMlModelsDir = DirectoryPath.coreMl.url,
            let pythonModelsDir = DirectoryPath.python.url else {
        Debug.log("One or more model directories URL is nil")
        return
      }
      
      let coreMLModels = try fileManager.contentsOfDirectory(at: coreMlModelsDir, includingPropertiesForKeys: nil)
      newItems += coreMLModels.filter { $0.hasDirectoryPath }.map {
        ModelItem(name: $0.lastPathComponent, type: .coreMl, isDefaultModel: defaultCoreMLModelNames.contains($0.lastPathComponent))
      }
      
      let pythonModels = try fileManager.contentsOfDirectory(at: pythonModelsDir, includingPropertiesForKeys: nil)
      newItems += pythonModels.filter { $0.pathExtension == "safetensors" }.map {
        ModelItem(name: $0.lastPathComponent, type: .python, isDefaultModel: defaultPythonModelNames.contains($0.lastPathComponent))
      }
      
      self.items = newItems
    } catch {
      Debug.log("Failed to scan directories: \(error)")
    }
  }
  
  private var scriptManagerObservation: AnyCancellable?
  
  func observeScriptManagerState(scriptManager: ScriptManager) {
    scriptManagerObservation = scriptManager.$scriptState
      .sink { [weak self] state in
        if state == .readyToStart {
          self?.startObservingModelDirectories()
        } else {
          self?.stopObservingModelDirectories()
        }
      }
  }
  
  func stopObservingModelDirectories() {
    coreMlObserver?.stopObserving()
    pythonObserver?.stopObserving()
    // reset observers to nil
    coreMlObserver = nil
    pythonObserver = nil
  }
  
  func startObservingModelDirectories() {
    coreMlObserver = DirectoryObserver()
    pythonObserver = DirectoryObserver()
    
    if let coreMlModelsDir = DirectoryPath.coreMl.url {
      coreMlObserver?.startObserving(url: coreMlModelsDir) { [weak self] in
        Debug.log("Detected changes in CoreML models directory")
        await self?.loadModels()
      }
    }
    
    if let pythonModelsDir = DirectoryPath.python.url {
      pythonObserver?.startObserving(url: pythonModelsDir) { [weak self] in
        Debug.log("Detected changes in Python models directory")
        await self?.loadModels()
      }
    }
  }
}

extension ModelManagerViewModel {
  func moveToTrash(item: ModelItem) async {
    let fileManager = FileManager.default
    do {
      let fileURL: URL // Declare the variable outside the switch
      
      // Safely unwrap URLs
      switch item.type {
      case .coreMl:
        guard let coreMlModelsDirUrl = DirectoryPath.coreMl.url else {
          Debug.log("CoreML models URL is nil")
          return
        }
        fileURL = coreMlModelsDirUrl.appendingPathComponent(item.name)
      case .python:
        guard let pythonModelsDirUrl = DirectoryPath.python.url else {
          Debug.log("Python models URL is nil")
          return
        }
        fileURL = pythonModelsDirUrl.appendingPathComponent(item.name)
      }
      
      // Move the file to trash
      var trashedItemURL: NSURL? = nil
      try fileManager.trashItem(at: fileURL, resultingItemURL: &trashedItemURL)
      Debug.log("Moved to trash: \(item.name)")
      
      // Reload or update the items list to reflect the change
      await loadModels()
    } catch {
      Debug.log("Failed to move to trash: \(item.name), error: \(error)")
    }
  }
}
