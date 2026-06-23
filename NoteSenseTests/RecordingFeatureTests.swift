import ComposableArchitecture
import XCTest

@testable import NoteSense

@MainActor
final class RecordingFeatureTests: XCTestCase {
  func testRecordAndSaveNote() async {
    final class SavedPathBox: @unchecked Sendable {
      var value: String?
    }
    let savedPath = SavedPathBox()

    let store = TestStore(initialState: RecordingFeature.State()) {
      RecordingFeature()
    } withDependencies: {
      $0.audioRecorderClient = AudioRecorderClient(
        requestPermission: { true },
        startRecording: {},
        stopRecording: { "Recordings/test-recording.m4a" },
        currentMeterLevel: { 0.2 }
      )
      $0.persistenceClient.save = { summary in
        savedPath.value = summary.audioFilePath
      }
    }

    await store.send(.recordButtonTapped)

    await store.receive(\.recordingStarted) {
      $0.phase = .recording
      $0.meterLevel = 0
    }

    store.exhaustivity = .off

    await store.send(.recordButtonTapped) {
      $0.phase = .saving
    }

    await store.receive(\.recordingSaved) {
      $0.phase = .idle
      $0.meterLevel = 0
      $0.errorMessage = nil
    }

    XCTAssertEqual(savedPath.value, "Recordings/test-recording.m4a")
  }

  func testPermissionDeniedShowsError() async {
    let store = TestStore(initialState: RecordingFeature.State()) {
      RecordingFeature()
    } withDependencies: {
      $0.audioRecorderClient.requestPermission = { false }
    }

    await store.send(.recordButtonTapped)

    await store.receive(\.recordingStartFailed) {
      $0.phase = .idle
      $0.meterLevel = 0
      $0.errorMessage = "Microphone access is required to record voice notes."
    }
  }
}
