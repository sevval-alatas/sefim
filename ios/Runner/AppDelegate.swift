import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "sefim/ocr",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "recognizeText",
            let arguments = call.arguments as? [String: Any],
            let path = arguments["path"] as? String,
            let image = UIImage(contentsOfFile: path),
            let cgImage = image.cgImage else {
        result(FlutterError(code: "INVALID_IMAGE", message: "Görsel açılamadı.", details: nil))
        return
      }

      let request = VNRecognizeTextRequest { request, error in
        if let error {
          result(FlutterError(code: "OCR_FAILED", message: error.localizedDescription, details: nil))
          return
        }

        let observations = request.results as? [VNRecognizedTextObservation] ?? []
        let text = observations
          .compactMap { $0.topCandidates(1).first?.string }
          .joined(separator: "\n")
        result(text)
      }
      request.recognitionLevel = .accurate
      request.recognitionLanguages = ["tr-TR", "en-US"]
      request.usesLanguageCorrection = true

      DispatchQueue.global(qos: .userInitiated).async {
        do {
          try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
        } catch {
          result(FlutterError(code: "OCR_FAILED", message: error.localizedDescription, details: nil))
        }
      }
    }
  }
}
