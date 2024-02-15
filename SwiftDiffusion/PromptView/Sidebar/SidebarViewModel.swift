//
//  SidebarViewModel.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/14/24.
//

import SwiftUI
import SwiftData

class SidebarViewModel: ObservableObject {
  
  @Published var selectedSidebarItem: SidebarItem? = nil
  @Published var recentlyGeneratedAndArchivablePrompts: [SidebarItem] = []
  
  @Published var itemToDelete: SidebarItem? = nil
  
  @Published var allSidebarItems: [SidebarItem] = []
  @Published var savedItems: [SidebarItem] = []
  @Published var workspaceItems: [SidebarItem] = []
  
  @Published var savableSidebarItems: [SidebarItem] = []
  @Published var itemToSave: SidebarItem? = nil
  
  
  @Published var blankNewPromptItem: SidebarItem? = nil
  
  @Published var sidebarItemCurrentlyGeneratingOut: SidebarItem? = nil
  
  var blankNewPromptExists: Bool {
    workspaceItems.contains { $0.title == "New Prompt" }
  }
  
  private func addToRecentlyGeneratedPromptArchivables(_ item: SidebarItem) {
    recentlyGeneratedAndArchivablePrompts.append(item)
  }
  
  func queueSelectedSidebarItemForDeletion() {
    itemToDelete = selectedSidebarItem
  }
  
  func queueSelectedSidebarItemForSaving() {
    if let queuedItem = selectedSidebarItem {
      itemToSave = queuedItem
      removeSidebarItemFromSavableQueue(sidebarItem: queuedItem)
    }
  }
  
  private func removeSidebarItemFromSavableQueue(sidebarItem: SidebarItem) {
    if savableSidebarItems.contains(where: { $0.id == sidebarItem.id }) {
      savableSidebarItems.removeAll { $0.id == sidebarItem.id }
    }
  }
  
  func prepareGeneratedPromptForSaving(sideBarItem: SidebarItem, imageUrls: [URL]) {
    sideBarItem.imageUrls = imageUrls
    savableSidebarItems.append(sideBarItem)
  }
  
  /*
  func queueGeneratedPromptForSaving(sideBarItem: SidebarItem, imageUrls: [URL]) {
    sideBarItem.imageUrls = imageUrls
    savableSidebarItems.append(sideBarItem)
  }*/
  
  /// Save most recently generated prompt archivable to the sidebar
  func saveMostRecentArchivablePromptToSidebar(in model: ModelContext) {
    if let latestGenerated = recentlyGeneratedAndArchivablePrompts.last {
      model.insert(latestGenerated)
      saveData(in: model)
      // Directly remove the last item assuming saveData was successful
      recentlyGeneratedAndArchivablePrompts.removeLast()
    }
  }
  
  /// After every new image generation, add potential new prompt archivable to the list
  @MainActor
  func addPromptArchivable(currentPrompt: PromptModel, imageUrls: [URL]) {
    var promptTitle = "My Prompt"
    if !currentPrompt.positivePrompt.isEmpty {
      promptTitle = currentPrompt.positivePrompt.prefix(35).appending("…")
    } else if let selectedModel = currentPrompt.selectedModel {
      promptTitle = selectedModel.name
    }
    
    let modelDataMapping = ModelDataMapping()
    let newPromptArchive = modelDataMapping.toArchive(promptModel: currentPrompt)
    
    let newSidebarItem = SidebarItem(title: promptTitle, timestamp: Date(), imageUrls: imageUrls, prompt: newPromptArchive)
    addToRecentlyGeneratedPromptArchivables(newSidebarItem)
  }
  
  
  
  func moveGeneratedItemFromWorkspace(sidebarItem: SidebarItem) {
    sidebarItem.prompt?.isWorkspaceItem = false
    removeSidebarItemFromSavableQueue(sidebarItem: sidebarItem)
  }
  
  func saveSidebarItem(_ sidebarItem: SidebarItem, in model: ModelContext) -> SidebarItem {
    model.insert(sidebarItem)
    saveData(in: model)
    return sidebarItem
  }
  
  @MainActor
  func createSidebarItemAndSaveToData(title: String = "New Prompt", appPrompt: AppPromptModel, imageUrls: [URL], in model: ModelContext) -> SidebarItem {
    let newSidebarItem = SidebarItem(title: title, timestamp: Date(), imageUrls: imageUrls, prompt: appPrompt)
    return saveSidebarItem(newSidebarItem, in: model)
  }
  
  func saveData(in model: ModelContext) {
    do {
      try model.save()
    } catch {
      Debug.log("Error saving context: \(error)")
    }
  }
  
  /// DEPRECATED
  func deleteItem(_ item: SidebarItem, in model: ModelContext) {
    model.delete(item)
    // Handle save and error
    do {
      try model.save()
    } catch {
      Debug.log("Error saving context after deletion: \(error)")
    }
  }
  
  @MainActor
  func savePromptToData(title: String, prompt: PromptModel, imageUrls: [URL], in model: ModelContext) {
    let mapping = ModelDataMapping()
    let promptData = mapping.toArchive(promptModel: prompt)
    let newItem = SidebarItem(title: title, timestamp: Date(), imageUrls: imageUrls, prompt: promptData)
    Debug.log("savePromptToData prompt.SdModel: \(String(describing: prompt.selectedModel?.sdModel?.title))")
    model.insert(newItem)
    saveData(in: model)
  }
  
 
  
}
