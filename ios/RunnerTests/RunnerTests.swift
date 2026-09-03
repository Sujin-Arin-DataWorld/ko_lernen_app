import Flutter
import UIKit
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {

  func testRegisteredPrivatePlayerFinishesWhenItsEngineIsDeallocated() {
    var completion: Bool?
    var completionCount = 0
    weak var releasedEngine: FlutterEngine?
    weak var releasedPlugin: PrivateTtsPlayerPlugin?
    autoreleasepool {
      // Use the real engine registry/publication/deallocation lifecycle. Only
      // binary transport is replaced, so no application Dart isolate is started.
      let engine = PrivateTtsRegistrationTestEngine(name: "private-tts-teardown-test")
      releasedEngine = engine
      let registrar = engine.registrar(forPlugin: "PrivateTtsPlayerPlugin")!
      PrivateTtsPlayerPlugin.register(with: registrar)
      let plugin = engine.valuePublished(byPlugin: "PrivateTtsPlayerPlugin") as? PrivateTtsPlayerPlugin
      XCTAssertNotNil(plugin, "The method delegate must also be published for engine teardown")
      releasedPlugin = plugin
      let codec = FlutterStandardMethodCodec.sharedInstance()
      let call = FlutterMethodCall(methodName: "play", arguments: [
        "id": 42, "bytes": FlutterStandardTypedData(bytes: silentWav()),
        "rate": 1.0, "volume": 0.0,
      ])
      XCTAssertNotNil(engine.testMessenger.handler)
      engine.testMessenger.handler?(codec.encode(call)) { envelope in
        completionCount += 1
        completion = envelope.flatMap { codec.decodeEnvelope($0) as? Bool }
      }
      XCTAssertNil(completion, "Registration must dispatch to a pending in-memory player")
    }
    XCTAssertNil(releasedEngine, "The test must exercise actual engine deallocation")
    XCTAssertEqual(completion, false, "Engine teardown must stop the registered request")
    XCTAssertEqual(completionCount, 1)
    XCTAssertNil(releasedPlugin, "The registered player must not outlive its engine")
  }

  func testPrivatePlayerStopsOnlyItsCurrentInMemoryRequest() {
    let plugin = PrivateTtsPlayerPlugin()
    var completion: Bool?
    plugin.handle(FlutterMethodCall(methodName: "play", arguments: [
      "id": 1, "bytes": FlutterStandardTypedData(bytes: silentWav()),
      "rate": 1.0, "volume": 0.0,
    ])) { completion = $0 as? Bool }
    XCTAssertNil(completion, "Playback should remain pending until completion or stop")
    plugin.handle(FlutterMethodCall(methodName: "stop", arguments: ["id": 999])) { _ in }
    XCTAssertNil(completion, "A stale stop cannot stop a newer request")
    plugin.handle(FlutterMethodCall(methodName: "stop", arguments: ["id": 1])) { _ in }
    XCTAssertEqual(completion, false)
  }

  func testPrivatePlayerRejectsInvalidAudioWithoutRetainingARequest() {
    let plugin = PrivateTtsPlayerPlugin()
    var completion: Bool?
    plugin.handle(FlutterMethodCall(methodName: "play", arguments: [
      "id": 1, "bytes": FlutterStandardTypedData(bytes: Data()),
      "rate": 1.0, "volume": 0.0,
    ])) { completion = $0 as? Bool }
    XCTAssertEqual(completion, false)
  }

  private func silentWav() -> Data {
    // Synthetic one-second PCM fixture constructed in memory, never a file.
    var data = Data("RIFF".utf8)
    func append(_ number: UInt32, bytes: Int) {
      for shift in 0..<bytes {
        data.append(UInt8((number >> (shift * 8)) & 255))
      }
    }
    append(16036, bytes: 4)
    data.append(Data("WAVEfmt ".utf8))
    append(16, bytes: 4)
    append(1, bytes: 2)
    append(1, bytes: 2)
    append(8000, bytes: 4)
    append(16000, bytes: 4)
    append(2, bytes: 2)
    append(16, bytes: 2)
    data.append(Data("data".utf8))
    append(16000, bytes: 4)
    data.append(Data(repeating: 0, count: 16000))
    return data
  }

}

private final class PrivateTtsRegistrationTestEngine: FlutterEngine {
  let testMessenger = PrivateTtsRegistrationMessenger()

  override var binaryMessenger: FlutterBinaryMessenger { testMessenger }
}

private final class PrivateTtsRegistrationMessenger: NSObject, FlutterBinaryMessenger {
  var handler: FlutterBinaryMessageHandler?

  func send(onChannel channel: String, message: Data?) {}

  func send(onChannel channel: String, message: Data?, binaryReply callback: FlutterBinaryReply?) {
    callback?(nil)
  }

  func setMessageHandlerOnChannel(
    _ channel: String, binaryMessageHandler handler: FlutterBinaryMessageHandler?
  ) -> FlutterBinaryMessengerConnection {
    self.handler = handler
    return 1
  }

  func cleanUpConnection(_ connection: FlutterBinaryMessengerConnection) {
    handler = nil
  }
}
