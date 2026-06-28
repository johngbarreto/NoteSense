import ComposableArchitecture
import XCTest

@testable import NoteSense

@MainActor
final class RecordingFeatureTests: XCTestCase {
  func testRecordAndSaveNote() async {
    final class SavedNoteBox: @unchecked Sendable {
      var audioFilePath: String?
      var transcript: String?
    }
    let saved = SavedNoteBox()

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
        saved.audioFilePath = summary.audioFilePath
        saved.transcript = summary.transcript
      }
    }

    await store.send(.recordButtonTapped)

    // Meter + transcript effects start after recordingStarted — ignore background actions.
    store.exhaustivity = .off

    await store.receive(\.recordingStarted) {
      $0.phase = .recording
      $0.meterLevel = 0
      $0.transcript = ""
    }

    await store.send(.recordButtonTapped) {
      $0.phase = .saving
    }

    await store.receive(\.recordingSaved) {
      $0.phase = .idle
      $0.meterLevel = 0
      $0.errorMessage = nil
      $0.transcript = ""
    }

    XCTAssertEqual(saved.audioFilePath, "Recordings/test-recording.m4a")
    XCTAssertEqual(saved.transcript, "")
  }

  func testStopSavesTranscript() async {
    final class SavedNoteBox: @unchecked Sendable {
      var transcript: String?
    }
    let saved = SavedNoteBox()

    let store = TestStore(initialState: RecordingFeature.State()) {
      RecordingFeature()
    } withDependencies: {
      $0.audioRecorderClient = AudioRecorderClient(
        requestPermission: { true },
        startRecording: {},
        stopRecording: { "Recordings/test-recording.m4a" },
        currentMeterLevel: { 0 }
      )
      $0.persistenceClient.save = { summary in
        saved.transcript = summary.transcript
      }
    }

    await store.send(.recordButtonTapped)
    store.exhaustivity = .off

    await store.receive(\.recordingStarted) {
      $0.phase = .recording
      $0.transcript = ""
    }

    // Simulate transcript arriving while recording (avoids waiting on fake 800ms timers).
    await store.send(.transcriptUpdate("Life")) {
      $0.transcript = "Life"
    }

    await store.send(.recordButtonTapped) {
      $0.phase = .saving
      $0.transcript = "Life"
    }

    await store.receive(\.recordingSaved) {
      $0.phase = .idle
      $0.transcript = ""
    }

    XCTAssertEqual(saved.transcript, "Life")
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
