//
//  SidebarMockDataController.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/14/24.
//

import SwiftData
import SwiftUI

@MainActor
class MockDataController {
  static let shared = MockDataController()
  
  let container: ModelContainer
  
  var mockImageUrls: [URL] = [
    URL(string: "file:///Users/jb/Documents/SwiftDiffusion/txt2img/2024-02-14/1a.png")!,
    URL(string: "file:///Users/jb/Documents/SwiftDiffusion/txt2img/2024-02-14/1b.png")!,
    URL(string: "file:///Users/jb/Documents/SwiftDiffusion/txt2img/2024-02-14/1c.png")!,
    URL(string: "file:///Users/jb/Documents/SwiftDiffusion/txt2img/2024-02-14/1-grid.png")!
  ]
  
  var lastImage: NSImage? {
    guard let lastUrl = mockImageUrls.last else { return nil }
    return NSImage(contentsOf: lastUrl)
  }
  
  init() {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    do {
      container = try ModelContainer(for: SidebarItem.self, StoredPromptModel.self, StoredCheckpointModel.self, SidebarFolder.self, configurations: config)
      insertMockData()
    } catch {
      fatalError("Failed to initialize the mock ModelContainer: \(error)")
    }
  }
  
  func insertMockData() {
    let context = container.mainContext
    let storedCheckpointModel1 = StoredCheckpointModel(name: "DreamShaperXL_v2.0", type: .python, url: URL(string: "https://example.com/model")!, isDefaultModel: true, jsonModelCheckpointTitle: "JSON Model Title", jsonModelCheckpointName: "JSON Model Name", jsonModelCheckpointFilename: "JSON Model Filename")
    let storedPromptModel1 = StoredPromptModel(positivePrompt: "A sunny day", negativePrompt: "A rainy day", selectedModel: storedCheckpointModel1)
    
    let storedCheckpointModel2 = StoredCheckpointModel(name: "Animerge 1.6.2", type: .python, url: URL(string: "https://example.com/model")!, isDefaultModel: true, jsonModelCheckpointTitle: "JSON Model Title", jsonModelCheckpointName: "JSON Model Name", jsonModelCheckpointFilename: "JSON Model Filename")
    let storedPromptModel2 = StoredPromptModel(positivePrompt: "A sunny day", negativePrompt: "A rainy day", selectedModel: storedCheckpointModel2)
    
    let sidebarItem1 = SidebarItem(title: "Gloomy Days", imageUrls: mockImageUrls, isWorkspaceItem: true, prompt: storedPromptModel1)
    let sidebarItem2 = SidebarItem(title: "Sunshine Overlook", imageUrls: mockImageUrls, isWorkspaceItem: true, prompt: storedPromptModel2)
    
    let sidebarFolder1 = SidebarFolder(name: "Personal", contents: [sidebarItem1, sidebarItem2])
    let sidebarFolder2 = SidebarFolder(name: "Shared", contents: [sidebarItem1, sidebarItem2])
    
    context.insert(storedCheckpointModel1)
    context.insert(storedCheckpointModel2)
    context.insert(storedPromptModel1)
    context.insert(storedPromptModel2)
    context.insert(sidebarItem1)
    context.insert(sidebarItem2)
    context.insert(sidebarFolder1)
    context.insert(sidebarFolder2)
    
    do {
      try context.save()
    } catch {
      Debug.log("Failed to save mock data: \(error)")
    }
  }
}