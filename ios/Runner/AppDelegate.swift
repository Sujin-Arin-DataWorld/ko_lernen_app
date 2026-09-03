import Flutter
import UIKit
import AVFoundation

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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PrivateTtsPlayerPlugin") {
      PrivateTtsPlayerPlugin.register(with: registrar)
    }
  }
}

/// Personal speech never goes through audioplayers' file-backed BytesSource.
/// The pending result completes only when this in-memory player finishes/stops.
final class PrivateTtsPlayerPlugin: NSObject, FlutterPlugin, AVAudioPlayerDelegate {
  private var player: AVAudioPlayer?
  private var pending: FlutterResult?
  private var activeId: Int?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "hangul_sori/private_tts", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(PrivateTtsPlayerPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any], let id = args["id"] as? Int else {
      result(false)
      return
    }
    switch call.method {
    case "play":
      finish(false)
      guard let bytes = args["bytes"] as? FlutterStandardTypedData,
            !bytes.data.isEmpty, bytes.data.count <= 4 * 1024 * 1024,
            let rate = args["rate"] as? Double, rate.isFinite,
            let volume = args["volume"] as? Double, volume.isFinite else {
        result(false)
        return
      }
      do {
        let audio = try AVAudioPlayer(data: bytes.data)
        audio.delegate = self
        audio.enableRate = true
        audio.rate = Float(max(0.5, min(2.0, rate)))
        audio.volume = Float(max(0.0, min(1.0, volume)))
        player = audio
        activeId = id
        pending = result
        if !audio.prepareToPlay() || !audio.play() {
          finish(false)
        }
      } catch {
        result(false)
      }
    case "stop":
      if activeId == id {
        finish(false)
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func finish(_ success: Bool) {
    let completion = pending
    pending = nil
    activeId = nil
    player?.stop()
    player?.delegate = nil
    player = nil
    completion?(success)
  }

  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    if self.player === player {
      finish(flag)
    }
  }

  func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
    if self.player === player {
      finish(false)
    }
  }

  func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    finish(false)
  }
}
