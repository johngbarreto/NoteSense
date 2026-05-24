import ComposableArchitecture
import SwiftUI

struct LibraryView: View {
  @Bindable var store: StoreOf<LibraryFeature>

  var body: some View {
    Group {
      if store.isLoading && store.notes.isEmpty {
        ProgressView("Loading notes…")
      } else if let errorMessage = store.errorMessage, store.notes.isEmpty {
        ContentUnavailableView {
          Label("Could Not Load", systemImage: "exclamationmark.triangle")
        } description: {
          Text(errorMessage)
        } actions: {
          Button("Try Again") { store.send(.reloadNotesRequested) }
        }
      } else if store.filteredNotes.isEmpty {
        ContentUnavailableView {
          Label("Voice Notes", systemImage: "books.vertical")
        } description: {
          Text(store.searchQuery.isEmpty ? "Record a note or add a sample to get started." : "No notes match your search.")
        } actions: {
          if store.searchQuery.isEmpty {
            Button("Add Sample Note") { store.send(.addSampleNoteTapped) }
          }
        }
      } else {
        List {
          ForEach(store.filteredNotes) { note in
            VoiceNoteRow(note: note)
          }
          .onDelete { indexSet in
            for index in indexSet {
              store.send(.deleteNoteRequested(store.filteredNotes[index].id))
            }
          }
        }
        .listStyle(.insetGrouped)
      }
    }
    .searchable(text: $store.searchQuery.sending(\.searchQueryUpdated))
    .navigationTitle("Library")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          store.send(.addSampleNoteTapped)
        } label: {
          Label("Add Sample", systemImage: "plus")
        }
      }
    }
    .refreshable { store.send(.reloadNotesRequested) }
    .onAppear { store.send(.viewLoaded) }
  }
}

private struct VoiceNoteRow: View {
  let note: VoiceNoteSummary

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text(note.displayTitle)
          .font(.headline)
          .lineLimit(2)
        Spacer(minLength: 8)
        Text(note.category)
          .font(.caption)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(.quaternary, in: Capsule())
      }

      if !note.transcript.isEmpty, note.summary.isEmpty || note.transcript != note.summary {
        Text(note.transcript)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }

      Text(note.createdAt, format: .dateTime.month().day().hour().minute())
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  NavigationStack {
    LibraryView(
      store: Store(initialState: LibraryFeature.State()) {
        LibraryFeature()
      } withDependencies: {
        $0.persistenceClient = .previewValue
      }
    )
  }
}
