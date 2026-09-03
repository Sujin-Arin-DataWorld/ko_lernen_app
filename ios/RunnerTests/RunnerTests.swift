import Flutter
import UIKit
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {

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
