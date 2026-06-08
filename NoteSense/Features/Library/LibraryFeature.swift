import ComposableArchitecture
import Foundation

@Reducer
struct LibraryFeature {
    @ObservableState
    struct State: Equatable {
        var notes: [VoiceNoteSummary] = []
        var filteredNotes: [VoiceNoteSummary] = []
        var searchQuery = ""
        var isLoading = false
        var errorMessage: String?
        
        var viewMode: ViewMode {
            if isLoading && notes.isEmpty {
                return .loading
            } else if let errorMessage, notes.isEmpty {
                return .error(errorMessage)
            } else if filteredNotes.isEmpty {
                return .empty(isSearching: !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } else {
                return .list
            }
        }
    }

    enum ViewMode: Equatable {
        case loading
        case error(String)
        case empty(isSearching: Bool)
        case list
    }

    enum Action: Equatable {
        /// The Library screen became visible — load notes for the first time.
        case viewLoaded
        /// User pulled to refresh, tapped retry, or notes changed and the list should reload.
        case reloadNotesRequested
        /// User typed in the search field — filter the list locally.
        case searchQueryUpdated(String)
        /// User tapped the dev-only sample note button.
        case addSampleNoteTapped
        /// User swiped to delete a note.
        case deleteNoteRequested(UUID)
        /// Async fetch finished (success or failure).
        case notesLoadCompleted(NotesLoadResult)
        /// Async delete finished (success or failure).
        case noteDeleteCompleted(NoteDeleteResult)
    }

    enum NotesLoadResult: Equatable {
        case success([VoiceNoteSummary])
        case failure(String)
    }

    enum NoteDeleteResult: Equatable {
        case success
        case failure(String)
    }

    @Dependency(\.persistenceClient) var persistence

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .viewLoaded, .reloadNotesRequested:
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let notes = try await persistence.fetchAll()
                        await send(.notesLoadCompleted(.success(notes)))
                    } catch {
                        await send(
                            .notesLoadCompleted(
                                .failure(error.localizedDescription)
                            )
                        )
                    }
                }

            case .searchQueryUpdated(let query):
                state.searchQuery = query
                state.filteredNotes = filterNotes(state.notes, query: query)
                return .none

            case .addSampleNoteTapped:
                let sample = VoiceNoteSummary(
                    id: UUID(),
                    createdAt: .now,
                    transcript:
                        "This is a sample voice note saved locally with SwiftData.",
                    summary: "Sample note",
                    category: "Demo",
                    audioFilePath: ""
                )
                return .run { send in
                    do {
                        try await persistence.save(sample)
                        await send(.reloadNotesRequested)
                    } catch {
                        await send(
                            .notesLoadCompleted(
                                .failure(error.localizedDescription)
                            )
                        )
                    }
                }

            case .deleteNoteRequested(let id):
                return .run { send in
                    do {
                        try await persistence.delete(id)
                        await send(.noteDeleteCompleted(.success))
                        await send(.reloadNotesRequested)
                    } catch {
                        await send(
                            .noteDeleteCompleted(
                                .failure(error.localizedDescription)
                            )
                        )
                    }
                }

            case .notesLoadCompleted(.success(let notes)):
                state.isLoading = false
                state.notes = notes
                state.filteredNotes = filterNotes(
                    notes,
                    query: state.searchQuery
                )
                return .none

            case .notesLoadCompleted(.failure(let message)):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case .noteDeleteCompleted(.success):
                return .none

            case .noteDeleteCompleted(.failure(let message)):
                state.errorMessage = message
                return .none
            }
        }
    }

    private func filterNotes(_ notes: [VoiceNoteSummary], query: String)
        -> [VoiceNoteSummary]
    {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return notes }
        return notes.filter { note in
            note.displayTitle.localizedCaseInsensitiveContains(trimmed)
                || note.transcript.localizedCaseInsensitiveContains(trimmed)
                || note.category.localizedCaseInsensitiveContains(trimmed)
        }
    }
}
