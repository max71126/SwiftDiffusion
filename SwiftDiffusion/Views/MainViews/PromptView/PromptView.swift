//
//  PromptView.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/5/24.
//

import SwiftUI
import Combine
import CompactSlider

extension Constants.Layout {
  static let promptRowPadding: CGFloat = 16
}

struct PromptView: View {
  @Environment(\.modelContext) var modelContext
  @EnvironmentObject var sidebarModel: SidebarModel
  @EnvironmentObject var currentPrompt: PromptModel
  @EnvironmentObject var checkpointsManager: CheckpointsManager
  @EnvironmentObject var loraModelsManager: ModelManager<LoraModel>
  @EnvironmentObject var vaeModelsManager: ModelManager<VaeModel>
  
  @ObservedObject var scriptManager = ScriptManager.shared
  @ObservedObject var userSettings = UserSettings.shared
  
  @State var isRightPaneVisible: Bool = false
  @State var generationDataInPasteboard: Bool = false
  @State var disablePromptView: Bool = false
  
  private var leftPane: some View {
    VStack(spacing: 0) {
      
      DebugPromptStatusView()
      
      PromptControlBarView()
      
      ScrollView {
        Form {
          if generationDataInPasteboard, let pasteboard = getPasteboardString() {
            HStack {
              Spacer()
              BlueSymbolButton(title: "Paste Generation Data", symbol: "arrow.up.doc.on.clipboard") {
                parseAndSetPromptData(from: pasteboard)
                withAnimation {
                  generationDataInPasteboard = false
                }
              }
            }
            .padding(.top, 14)
          }
          
          HStack {
            CheckpointMenu()
            SamplingMethodMenu()
          }
          .padding(.vertical, 12)
          
          VStack {
            PromptEditorView(label: "Positive Prompt", text: $currentPrompt.positivePrompt, isDisabled: $disablePromptView)
            PromptEditorView(label: "Negative Prompt", text: $currentPrompt.negativePrompt, isDisabled: $disablePromptView)
          }
          .padding(.bottom, 6)
          
          DimensionSelectionRow(width: $currentPrompt.width, height: $currentPrompt.height)
          
          DetailSelectionRow(cfgScale: $currentPrompt.cfgScale, samplingSteps: $currentPrompt.samplingSteps)
          
          HalfSkipClipRow(clipSkip: $currentPrompt.clipSkip)
          
          SeedRow(seed: $currentPrompt.seed, controlButtonLayout: .beside)
          
          ExportSelectionRow(batchCount: $currentPrompt.batchCount, batchSize: $currentPrompt.batchSize)
          
          VaeModelMenu()
        }
        .padding(.leading, 8).padding(.trailing, 16)
        
        .onAppear {
          checkPasteboardAndUpdateFlag()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
          Task {
            await checkPasteboardAndUpdateFlag()
          }
        }
        .disabled(sidebarModel.disablePromptView)
      }
      
      DebugPromptActionView(scriptManager: scriptManager)
      
    }
    .background(Color(NSColor.windowBackgroundColor))
  }
  
  private var rightPane: some View {
    ConsoleView(scriptManager: scriptManager)
      .background(Color(NSColor.windowBackgroundColor))
    
  }
  
  var body: some View {
    HSplitView {
      leftPane
        .frame(minWidth: 370)
      if isRightPaneVisible {
        rightPane
          .frame(minWidth: 370)
      }
    }
  }
}

#Preview {
  CommonPreviews.promptView
}
