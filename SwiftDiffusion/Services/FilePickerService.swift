//
//  FilePickerService.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import Foundation
import AppKit
import UniformTypeIdentifiers

struct FilePickerService {
  /// Presents an open panel dialog allowing the user to select a shell script file.
  ///
  /// This function asynchronously displays a file picker dialog configured to allow the selection of files with the `.sh` extension only. It ensures that the user cannot choose directories or multiple files. If the user selects a file and confirms, the function returns the path to the selected file. If the user cancels the dialog or selects a file of an incorrect type, the function returns `nil`.
  ///
  /// - Returns: A `String` representing the path to the selected `.sh` file, or `nil` if no file is selected or the operation is cancelled.
  @MainActor
  static func browseForShellFile() async -> String? {
    return await withCheckedContinuation { continuation in
      let panel = NSOpenPanel()
      panel.allowsMultipleSelection = false
      panel.canChooseDirectories = false
      
      if let shellScriptType = UTType(filenameExtension: "sh") {
        panel.allowedContentTypes = [shellScriptType]
      } else {
        print("Failed to find UTType for .sh files")
        continuation.resume(returning: nil)
        return
      }
      
      panel.begin { response in
        if response == .OK, let url = panel.urls.first, url.pathExtension == "sh" {
          continuation.resume(returning: url.path)
        } else {
          print("Error: Selected file is not a .sh script.")
          continuation.resume(returning: nil)
        }
      }
    }
  }
}
