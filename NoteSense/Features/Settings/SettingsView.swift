import ComposableArchitecture
import SwiftUI

struct SettingsView: View {
  let store: StoreOf<SettingsFeature>

  var body: some View {
    List {
      Section {
        Text(store.statusMessage)
          .foregroundStyle(.secondary)
      } header: {
        Text("WaveNote")
      } footer: {
        Text("Local-first voice notes with live transcription and AI summaries.")
      }
    }
    .onAppear { store.send(.viewLoaded) }
    .navigationTitle("Settings")
  }
}

#Preview {
  NavigationStack {
    SettingsView(
      store: Store(initialState: SettingsFeature.State()) {
        SettingsFeature()
      }
    )
  }
}
