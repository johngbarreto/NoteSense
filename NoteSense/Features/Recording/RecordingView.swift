import ComposableArchitecture
import SwiftUI

struct RecordingView: View {
  let store: StoreOf<RecordingFeature>

  var body: some View {
    VStack(spacing: 32) {
      Spacer()

      meterView

      Text(store.statusMessage)
        .font(.title3)
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)
        .padding(.horizontal)
        
        
        Text(store.transcript)
            .font(.footnote)
          .multilineTextAlignment(.center)
          .foregroundStyle(.secondary)
          .padding(.horizontal)

      Button(store.recordButtonTitle) {
        store.send(.recordButtonTapped)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .disabled(!store.isRecordButtonEnabled)

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemGroupedBackground))
    .onAppear { store.send(.viewLoaded) }
    .navigationTitle("Record")
  }

  private var meterView: some View {
    ZStack {
      Image(systemName: "waveform.circle.fill")
        .font(.system(size: 120))
        .foregroundStyle(.tint.opacity(0.2))

      RoundedRectangle(cornerRadius: 6)
        .fill(Color.accentColor)
        .frame(width: 12, height: 24 + CGFloat(store.meterLevel) * 80)
        .animation(.easeOut(duration: 0.1), value: store.meterLevel)
    }
    .frame(height: 140)
  }
}

#Preview {
  NavigationStack {
    RecordingView(
      store: Store(initialState: RecordingFeature.State()) {
        RecordingFeature()
      } withDependencies: {
        $0.audioRecorderClient = .previewValue
      }
    )
  }
}
