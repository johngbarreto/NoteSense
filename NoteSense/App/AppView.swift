import ComposableArchitecture
import SwiftUI

struct AppView: View {
  @Bindable var store: StoreOf<AppFeature>

  var body: some View {
    TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
      NavigationStack {
        RecordingView(store: store.scope(state: \.recording, action: \.recording))
      }
      .tabItem {
        Label("Record", systemImage: "mic.fill")
      }
      .tag(Tab.record)

      NavigationStack {
        LibraryView(store: store.scope(state: \.library, action: \.library))
      }
      .tabItem {
        Label("Library", systemImage: "books.vertical.fill")
      }
      .tag(Tab.library)

      NavigationStack {
        SettingsView(store: store.scope(state: \.settings, action: \.settings))
      }
      .tabItem {
        Label("Settings", systemImage: "gearshape.fill")
      }
      .tag(Tab.settings)
    }
  }
}

#Preview {
  AppView(
    store: Store(initialState: AppFeature.State()) {
      AppFeature()
    }
  )
}
