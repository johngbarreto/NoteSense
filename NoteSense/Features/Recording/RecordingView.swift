import ComposableArchitecture
import SwiftUI

struct RecordingView: View {
  let store: StoreOf<RecordingFeature>

  var body: some View {
    VStack(spacing: 24) {
      Image(systemName: "waveform.circle.fill")
        .font(.system(size: 72))
        .foregroundStyle(.tint)
        .symbolEffect(.pulse, options: .repeating)

      Text(store.statusMessage)
        .font(.title3)
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)
        .padding(.horizontal)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemGroupedBackground))
    .onAppear { store.send(.viewLoaded) }
    .navigationTitle("Record")
  }
}

#Preview {
  NavigationStack {
    RecordingView(
      store: Store(initialState: RecordingFeature.State()) {
        RecordingFeature()
      }
    )
  }
}
