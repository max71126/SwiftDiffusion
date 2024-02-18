//
//  SwiftDiffusionApp.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/3/24.
//

import SwiftUI
import SwiftData

@main
struct SwiftDiffusionApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  var modelContainer: ModelContainer
  
  @StateObject var scriptManager = ScriptManager.shared
  
  let sidebarViewModel = SidebarViewModel()
  
  let currentPrompt = PromptModel()
  let checkpointModelsManager = CheckpointModelsManager()
  let loraModelsManager = ModelManager<LoraModel>()
  
  init() {
    let fileManager = FileManager.default
    guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
      fatalError("Application Support directory not found.")
    }
    let storeURL = appSupportURL
      .appendingPathComponent("test1") // Constants.FileStructure.AppSupportFolderName
      .appendingPathComponent("UserData").appendingPathComponent("LocalDatabase")
      .appendingPathComponent(Constants.FileStructure.AppSwiftDataFileName)
    
    let subfolderURL = storeURL.deletingLastPathComponent()
    if !fileManager.fileExists(atPath: subfolderURL.path) {
      try! fileManager.createDirectory(at: subfolderURL, withIntermediateDirectories: true)
    }
    
    do {
      modelContainer = try ModelContainer(for: SidebarItem.self, SidebarFolder.self, configurations: ModelConfiguration(url: storeURL))
    } catch {
      fatalError("Failed to configure SwiftData container: \(error)")
    }
    
    setupAppFileStructure()
  }
  
  
  var body: some Scene {
    WindowGroup {
      ContentView(scriptManager: scriptManager)
        .frame(minWidth: 720, idealWidth: 900, maxWidth: .infinity,
               minHeight: 500, idealHeight: 800, maxHeight: .infinity)
        .environmentObject(sidebarViewModel)
        .environmentObject(currentPrompt)
        .environmentObject(checkpointModelsManager)
        .environmentObject(loraModelsManager)
    }
    .modelContainer(modelContainer)
    .windowToolbarStyle(.unified(showsTitle: false))
    .commands {
      CommandGroup(after: .appInfo) {
        Divider()
        
        Button("Check for Updates...") {
          WindowManager.shared.showUpdatesWindow()
        }
        .keyboardShortcut("U", modifiers: [.command])
        
        Divider()
        
        Button("Settings...") {
          WindowManager.shared.showSettingsWindow()
        }
        .keyboardShortcut(",", modifiers: [.command])
      }
    }
    .commands {
      CommandMenu("Prompt") {
        Button("Copy Generation Data") {
          currentPrompt.copyMetadataToClipboard()
        }
      }
    }
  }
}
