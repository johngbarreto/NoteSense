import ComposableArchitecture

@Reducer
struct SettingsFeature {
  @ObservableState
  struct State: Equatable {
    var statusMessage = "Settings"
  }

  enum Action: Equatable {
    /// The Settings screen became visible — run one-time setup.
    case viewLoaded
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .viewLoaded:
        state.statusMessage = "API key and preferences — Slice G"
        return .none
      }
    }
  }
}
