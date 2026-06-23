import ComposableArchitecture
import Foundation

@Reducer
struct RecordingFeature {
  @ObservableState
  struct State: Equatable {
    var phase: Phase = .idle
    var meterLevel: Float = 0
    var errorMessage: String?

    var statusMessage: String {
      if let errorMessage {
        return errorMessage
      }
      switch phase {
      case .idle:
        return "Tap Record to capture a voice note."
      case .recording:
        return "Recording… tap Stop when finished."
      case .saving:
        return "Saving note…"
      }
    }

    var recordButtonTitle: String {
      switch phase {
      case .idle:
        return "Record"
      case .recording:
        return "Stop"
      case .saving:
        return "Saving…"
      }
    }

    var isRecordButtonEnabled: Bool {
      phase != .saving
    }
  }

  enum Phase: Equatable {
    case idle
    case recording
    case saving
  }

  enum Action: Equatable {
    case viewLoaded
    case recordButtonTapped
    case recordingStarted
    case recordingStartFailed(String)
    case meterLevelUpdated(Float)
    case recordingSaved
    case recordingSaveFailed(String)
  }

  enum CancelID {
    case meter
  }

  @Dependency(\.audioRecorderClient) var audioRecorder
  @Dependency(\.persistenceClient) var persistence

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .viewLoaded:
        state.errorMessage = nil
        return .none

      case .recordButtonTapped:
        switch state.phase {
        case .saving:
          return .none

        case .idle:
          state.errorMessage = nil
          return .run { send in
            let granted = await audioRecorder.requestPermission()
            guard granted else {
              await send(
                .recordingStartFailed(
                  "Microphone access is required to record voice notes."
                )
              )
              return
            }

            do {
              try await audioRecorder.startRecording()
              await send(.recordingStarted)
            } catch {
              await send(.recordingStartFailed(error.localizedDescription))
            }
          }

        case .recording:
          state.phase = .saving
          return .merge(
            .cancel(id: CancelID.meter),
            .run { send in
              do {
                let path = try await audioRecorder.stopRecording()
                let note = VoiceNoteSummary(
                  id: UUID(),
                  createdAt: .now,
                  transcript: "",
                  summary: "",
                  category: "General",
                  audioFilePath: path
                )
                try await persistence.save(note)
                await send(.recordingSaved)
              } catch {
                await send(.recordingSaveFailed(error.localizedDescription))
              }
            }
          )
        }

      case .recordingStarted:
        state.phase = .recording
        state.meterLevel = 0
        return .run { send in
          while !Task.isCancelled {
            try await Task.sleep(for: .milliseconds(100))
            let level = await audioRecorder.currentMeterLevel()
            await send(.meterLevelUpdated(level))
          }
        }
        .cancellable(id: CancelID.meter, cancelInFlight: true)

      case let .recordingStartFailed(message):
        state.phase = .idle
        state.meterLevel = 0
        state.errorMessage = message
        return .none

      case let .meterLevelUpdated(level):
        state.meterLevel = level
        return .none

      case .recordingSaved:
        state.phase = .idle
        state.meterLevel = 0
        state.errorMessage = nil
        return .none

      case let .recordingSaveFailed(message):
        state.phase = .idle
        state.meterLevel = 0
        state.errorMessage = message
        return .none
      }
    }
  }
}
