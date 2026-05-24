import ComposableArchitecture

@Reducer
struct AppFeature {
  @ObservableState
  struct State: Equatable {
    var selectedTab: Tab = .record
    var recording = RecordingFeature.State()
    var library = LibraryFeature.State()
    var settings = SettingsFeature.State()
  }

  enum Action: Equatable {
    case tabSelected(Tab)
    case recording(RecordingFeature.Action)
    case library(LibraryFeature.Action)
    case settings(SettingsFeature.Action)
  }

  var body: some ReducerOf<Self> {
    Scope(state: \.recording, action: \.recording) {
      RecordingFeature()
    }
    Scope(state: \.library, action: \.library) {
      LibraryFeature()
    }
    Scope(state: \.settings, action: \.settings) {
      SettingsFeature()
    }
    Reduce { state, action in
      guard case let .tabSelected(tab) = action else { return .none }
      state.selectedTab = tab
      return .none
    }
  }
}

enum Tab: String, CaseIterable, Hashable {
  case record
  case library
  case settings
}
