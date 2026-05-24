import ComposableArchitecture

@Reducer
struct RecordingFeature {
  @ObservableState
  struct State: Equatable {
    var statusMessage = "Ready to record"
  }

  enum Action: Equatable {
    /// The Record screen became visible — run one-time setup.
    case viewLoaded
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .viewLoaded:
        state.statusMessage = "Recording screen — Slice C adds the mic"
        return .none
      }
    }
  }
}
