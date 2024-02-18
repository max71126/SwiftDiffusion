//
//  ContentView+Generate.swift
//  SwiftDiffusion
//
//  Created by Justin Bush on 2/8/24.
//

import SwiftUI
import Combine

extension Constants {
  enum API {
    static let timeoutInterval: TimeInterval = 1000
    static let compositeImageCompressionFactor: Double = 0.5
    
    enum Endpoint: String {
      case txt2img = "sdapi/v1/txt2img"
      
      var outputDirName: String {
        switch self {
        case .txt2img: return "txt2img"
        }
      }
      
      func url(relativeTo base: URL) -> URL? {
        return URL(string: self.rawValue, relativeTo: base)
      }
    }
  }
}

enum PayloadKey: String {
  case prompt
  case negativePrompt = "negative_prompt"
  case width
  case height
  case cfgScale = "cfg_scale"
  case steps
  case seed
  case batchCount = "batch_count"
  case batchSize = "batch_size"
  case overrideSettings = "override_settings"
  case doNotSaveGrid = "do_not_save_grid"
  case doNotSaveSamples = "do_not_save_samples"
}

// POSTing to sdapi/v1/options with sd_model_checkpoint
// https://github.com/AUTOMATIC1111/stable-diffusion-webui/pull/4301#issuecomment-1328249975

class APIService {
  static let shared = APIService()
  
  private init() {}
  
  func sendImageGenerationRequest(to endpoint: Constants.API.Endpoint, with payload: [String: Any], baseAPI: URL) async -> [String]? {
    guard let url = endpoint.url(relativeTo: baseAPI) else {
      Debug.log("Invalid URL for endpoint: \(endpoint)")
      return nil
    }
    
    do {
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
      
      let session = URLSession(configuration: self.customSessionConfiguration())
      let (data, _) = try await session.data(for: request)
      
      if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
         let images = json["images"] as? [String] {
        return images
      }
    } catch {
      Debug.log("API request failed with error: \(error)")
    }
    return nil
  }
  
  private func customSessionConfiguration() -> URLSessionConfiguration {
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = Constants.API.timeoutInterval
    configuration.timeoutIntervalForResource = Constants.API.timeoutInterval
    return configuration
  }
}

extension ContentView {
  func prepareImageGenerationPayloadFromPrompt() -> [String: Any] {
    var payload: [String: Any] = [
      PayloadKey.prompt.rawValue: currentPrompt.positivePrompt,
      PayloadKey.negativePrompt.rawValue: currentPrompt.negativePrompt,
      PayloadKey.width.rawValue: Int(currentPrompt.width),
      PayloadKey.height.rawValue: Int(currentPrompt.height),
      PayloadKey.cfgScale.rawValue: Int(currentPrompt.cfgScale),
      PayloadKey.steps.rawValue: Int(currentPrompt.samplingSteps),
      PayloadKey.seed.rawValue: Int(currentPrompt.seed) ?? -1,
      PayloadKey.batchCount.rawValue: Int(currentPrompt.batchCount),
      PayloadKey.batchSize.rawValue: Int(currentPrompt.batchSize),
      PayloadKey.doNotSaveGrid.rawValue: false,
      PayloadKey.doNotSaveSamples.rawValue : false
    ]
    
    let overrideSettings: [String: Any] = [
      "CLIP_stop_at_last_layers": Int(currentPrompt.clipSkip)
    ]
    
    payload[PayloadKey.overrideSettings.rawValue] = overrideSettings
    return payload
  }
}



extension ContentView {
  func saveGeneratedImages(base64EncodedImages: [String]) {
    guard let directoryURL = ImageSaver.getOutputDirectoryUrl(forEndpoint: .txt2img) else {
      Debug.log("[saveGeneratedImages] error outputUrl")
      return
    }
    
    Task {
      let result = await ImageSaver.saveImages(images: base64EncodedImages, to: directoryURL)
      await updateUIWithImageResult(result)
    }
  }
  
  private func updateUIWithImageResult(_ result: (Data?, String, [URL])) async {
    let (imageData, imagePath, savedImageUrls) = result
    // Convert Data? to NSImage?
    let image: NSImage? = imageData.flatMap { NSImage(data: $0) }
    
    await MainActor.run {
      self.selectedImage = image
      self.lastSelectedImagePath = imagePath
      self.lastSavedImageUrls = savedImageUrls
      scriptManager.genStatus = .done
      
      Delay.by(3) {
        scriptManager.genStatus = .idle
        scriptManager.genProgress = 0
      }
    }
  }
}

extension ContentView {
  func fetchAndSaveGeneratedImages() {
    scriptManager.genStatus = .preparingToGenerate
    scriptManager.genProgress = -1
    
    let payload = prepareImageGenerationPayloadFromPrompt() // Assuming this prepares your API request payload correctly
    
    guard let baseAPI = scriptManager.serviceUrl else {
      Debug.log("Invalid base API URL")
      return
    }
    
    Task {
      guard let images = await APIService.shared.sendImageGenerationRequest(to: .txt2img, with: payload, baseAPI: baseAPI) else {
        Debug.log("Failed to fetch images from API")
        return
      }
      
      // Assuming `images` are the base64 encoded strings you need to save
      saveGeneratedImages(base64EncodedImages: images)
    }
  }
}
