//
//  SidebarFolderView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/28/24.
//

import SwiftUI
import SwiftData

extension SidebarModel {
  var sortedCurrentFolderItems: [SidebarItem] {
    currentFolder?.items.sorted(by: { $0.timestamp > $1.timestamp }) ?? []
  }
}

extension SidebarModel {
  var sortedFoldersAlphabetically: [SidebarFolder] {
    guard let folders = currentFolder?.folders else { return [] }
    return folders.sorted {
      $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
    }
  }
}

struct SidebarFolderView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject var sidebarModel: SidebarModel
  
  var body: some View {
    newFolderButtonView
    
    Section(header: Text("Folders")) {
      if let parentFolder = sidebarModel.currentFolder?.parent {
        ListBackButtonItem(parentFolder: parentFolder)
          .onTapGesture {
            sidebarModel.setCurrentFolder(to: parentFolder)
          }
      }
      
      ForEach(sidebarModel.sortedFoldersAlphabetically) { folder in
        SidebarFolderItem(folder: folder)
          .onTapGesture {
            sidebarModel.setCurrentFolder(to: folder)
          }
      }
    }
    
    Section(header: Text(sidebarModel.currentFolder?.name ?? "Files")) {
      ForEach(sidebarModel.sortedCurrentFolderItems) { sidebarItem in
        SidebarStoredItemView(item: sidebarItem)
          .padding(.vertical, 2)
          .contentShape(Rectangle())
          .onTapGesture {
            sidebarModel.setSelectedSidebarItem(to: sidebarItem)
          }
          .onDrag {
            Debug.log("[DD] Dragging item with ID: \(sidebarItem.id.uuidString)")
            return NSItemProvider(object: String(sidebarItem.id.uuidString) as NSString)
          }
      }
    }
  }
  
  
  private var newFolderButtonView: some View {
    HStack {
      Spacer()
      Button(action: {
        var newFolderName = "Untitled Folder"
        let existingFolderNames = sidebarModel.currentFolder?.folders.map { $0.name } ?? []
        if existingFolderNames.contains(newFolderName) {
          var suffix = 2
          while existingFolderNames.contains("\(newFolderName) \(suffix)") {
            suffix += 1
          }
          newFolderName = "\(newFolderName) \(suffix)"
        }
        
        let newFolderItem = SidebarFolder(name: newFolderName)
        sidebarModel.currentFolder?.add(folder: newFolderItem)
        sidebarModel.saveData(in: modelContext)
      }) {
        Text("New Folder")
        Image(systemName: "folder.badge.plus")
      }
      .buttonStyle(.accessoryBar)
    }
  }
  
  private struct ListBackButtonItem: View {
    var parentFolder: SidebarFolder
    
    var body: some View {
      HStack {
        Image(systemName: "arrow.turn.left.up")
          .foregroundStyle(.secondary)
          .frame(width: 26)
        Text(parentFolder.name)
        Spacer()
      }
      .padding(.vertical, 8)
      .contentShape(Rectangle())
    }
  }
  
}
