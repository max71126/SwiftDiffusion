//
//  SettingsView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/6/24.
//

import SwiftUI

struct SettingsView: View {
  @ObservedObject var userSettings: UserSettingsModel
  @Binding var scriptPathInput: String
  @Binding var fileOutputDir: String
  @Environment(\.presentationMode) var presentationMode
  
  var body: some View {
    VStack {
      ScrollView {
        VStack(alignment: .leading) {
          HStack {
            Text("Settings")
              .font(.largeTitle)
              .padding(.vertical, 20)
              .padding(.horizontal, 14)
            Spacer()
            Button(action: {
              userSettings.showAllDescriptions.toggle() // Toggle setting
            }) {
              Text(userSettings.showAllDescriptions ? "Hide All" : "Show All") // Dynamic label
              Image(systemName: "questionmark.circle")
            }
          }
          
          BrowseFileRow(labelText: "webui.sh path",
                        placeholderText: "path/to/webui.sh",
                        textValue: $scriptPathInput) {
            await FilePickerService.browseForShellFile()
          }
          
          BrowseFileRow(labelText: "image output directory",
                        placeholderText: "path/to/outputs",
                        textValue: $fileOutputDir) {
            await FilePickerService.browseForDirectory()
          }
        }
        
        VStack(alignment: .leading) {
          Text("Prompt")
            .font(.title)
            .padding(.vertical, 20)
            .padding(.horizontal, 14)
          VStack(alignment: .leading) {
            ToggleWithHeader(isToggled: $userSettings.disablePasteboardParsingForGenerationData, header: "Disable automatic generation data parsing", description: "When you copy generation data from sites like Civit.ai, this will automatically format it and show a button to paste it.")
            
            ToggleWithHeader(isToggled: $userSettings.alwaysShowPasteboardGenerationDataButton, header: "Always show Paste Generation Data button", description: "This will cause the 'Paste Generation Data' button to always show, even if copied data is incompatible and cannot be pasted.")
          }
          .padding(.leading, 8)
          
          Text("Developer")
            .font(.title)
            .padding(.vertical, 20)
            .padding(.horizontal, 14)
          
          ToggleWithHeader(isToggled: $userSettings.showDebugMenu, header: "Show Debug menu", description: "This will show the Debug menu in the top menu bar.")
          
          Toggle("[Advanced] Show Debug Menu", isOn: $userSettings.showDebugMenu)
            .font(.system(.body, design: .monospaced))
            .padding()
        }
        
        HStack {
          Toggle("[Advanced] Show Debug Menu", isOn: $userSettings.showDebugMenu)
            .font(.system(.body, design: .monospaced))
            .padding()
        }
        
      }
      HStack {
        Spacer()
        Button("Done") {
          presentationMode.wrappedValue.dismiss()
        }
      }
    }
    .padding(14)
    .navigationTitle("Settings")
    .frame(minWidth: 500, idealWidth: 670, minHeight: 350, idealHeight: 500)
  }
}

#Preview {
  SettingsView(userSettings: UserSettingsModel.preview(), scriptPathInput: .constant("path/to/webui.sh"), fileOutputDir: .constant("path/to/outputs/"))
    .frame(width: 500, height: 700)
}

extension UserSettingsModel {
  static func preview() -> UserSettingsModel {
    let previewManager = UserSettingsModel()
    return previewManager
  }
}

struct ToggleWithHeader: View {
  @Binding var isToggled: Bool
  var header: String
  var description: String = ""
  @State private var isHovering = false
  @EnvironmentObject var userSettings: UserSettingsModel
  
  var body: some View {
    HStack(alignment: .top) {
      Toggle("", isOn: $isToggled)
        .padding(.trailing, 6)
        .padding(.top, 2)
      
      VStack(alignment: .leading) {
        HStack {
          Text(header)
            .font(.system(size: 14, weight: .semibold, design: .default))
            .underline()
            .padding(.vertical, 2)
          Image(systemName: "questionmark.circle")
            .onHover { isHovering in
              self.isHovering = isHovering
            }
        }
        Text(description)
          .font(.system(size: 12))
          .foregroundStyle(Color.secondary)
          .opacity(userSettings.showAllDescriptions || isHovering ? 1 : 0)
      }
      
    }
    .padding(.bottom, 8)
  }
}



struct BrowseFileRow: View {
  var labelText: String?
  var placeholderText: String
  @Binding var textValue: String
  var browseAction: () async -> String?
  
  var body: some View {
    VStack(alignment: .leading) {
      if let label = labelText {
        Text(label)
          .padding(.horizontal, 14)
          .font(.system(.body, design: .monospaced))
      }
      HStack {
        TextField(placeholderText, text: $textValue)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .font(.system(.body, design: .monospaced))
        Button("Browse...") {
          Task {
            if let path = await browseAction() {
              textValue = path
            }
          }
        }
      }
      .padding(.bottom, 14)
    }
  }
}
