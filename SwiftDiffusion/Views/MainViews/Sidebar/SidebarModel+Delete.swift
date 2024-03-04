//
//  SidebarModel+Delete.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 3/4/24.
//

import SwiftData

class SwiftDataHelper {
  /// Saves the given model context.
  ///
  /// - Parameter modelContext: The model context to save.
  static func saveContext(_ modelContext: ModelContext) {
    do {
      try modelContext.save()
    } catch {
      Debug.log("Failed to save model context: \(error)")
    }
  }
}

extension SidebarModel {
  // TODO: refactor selectNextItem to be getNextItemToSelect() -> SidebarItem
  // then, for example: deleteWorkspaceItem() {
  //                      let nextItemToSelect = getNextItemToSelect()
  //                      delete(sidebarItem: item)
  //                      selectedSidebarItem = nextItemToSelect
  
  /// Delete a workspace item and save changes to the data model.
  ///
  /// - Parameter sidebarItem: The sidebar item to delete.
  func deleteWorkspaceItem(_ sidebarItem: SidebarItem) {
    delete(sidebarItem: sidebarItem, from: workspaceFolder)
    SwiftDataHelper.saveContext(modelContext)
  }
  /// Delete a stored item from a specified folder, save changes to the data model, and play a sound effect.
  ///
  /// - Parameters:
  ///   - sidebarItem: The sidebar item to delete.
  ///   - folder: The folder from which to delete the item.
  func deleteStoredItem(_ sidebarItem: SidebarItem, from folder: SidebarFolder) {
    delete(sidebarItem: sidebarItem, from: folder)
    SwiftDataHelper.saveContext(modelContext)
    SoundUtility.play(systemSound: .trash)
  }
  /// Delete a folder from its parent folder, save changes to the data model, and play a sound effect.
  ///
  /// - Parameters:
  ///   - folder: The folder to delete.
  ///   - parentFolder: The parent folder from which to delete the folder.
  func deleteFolder(_ folder: SidebarFolder, from parentFolder: SidebarFolder) {
    delete(folder: folder, from: parentFolder)
    SwiftDataHelper.saveContext(modelContext)
    SoundUtility.play(systemSound: .trash)
  }
  /// Delete logic for a sidebar item within a folder, and optionally perform additional cleanup actions.
  ///
  /// - Parameters:
  ///   - sidebarItem: The sidebar item to delete.
  ///   - folder: The folder containing the item.
  /// Delete SidebarItem logic for all workspace items and non-workspace items.
  private func delete(sidebarItem: SidebarItem, from folder: SidebarFolder) {
    if folder != workspaceFolder {
      PreviewImageProcessingManager.shared.trashPreviewAndThumbnailAssets(for: sidebarItem, in: modelContext)
    }
    folder.remove(item: sidebarItem)
  }
  /// Deletes a folder from its parent folder.
  ///
  /// - Parameters:
  ///   - currentFolder: The folder to delete.
  ///   - parentFolder: The parent folder from which to delete the current folder.
  private func delete(folder currentFolder: SidebarFolder, from parentFolder: SidebarFolder) {
    guard currentFolder.isDeletable() else { return }
    
    for childFolder in currentFolder.folders {
      delete(folder: childFolder, from: currentFolder)
    }
    
    if currentFolder.folders.isEmpty {
      removeAllChildItems(from: currentFolder)
    }
    
    if currentFolder.folders.isEmpty && currentFolder.items.isEmpty {
      parentFolder.remove(folder: currentFolder)
    }
    
  }
  /// Removes all child items from a folder.
  ///
  /// - Parameter folder: The folder from which to remove all child items.
  private func removeAllChildItems(from folder: SidebarFolder) {
    for item in folder.items {
      delete(sidebarItem: item, from: folder)
    }
  }
  
  
}
