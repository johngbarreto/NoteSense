import ComposableArchitecture
import XCTest

@testable import NoteSense

@MainActor
final class LibraryFeatureTests: XCTestCase {
  func testLoadNotesWhenViewLoads() async {
    let note = VoiceNoteSummary(
      id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
      createdAt: Date(timeIntervalSince1970: 0),
      transcript: "Hello",
      summary: "Greeting",
      category: "Personal",
      audioFilePath: ""
    )

    let store = TestStore(initialState: LibraryFeature.State()) {
      LibraryFeature()
    } withDependencies: {
      $0.persistenceClient.fetchAll = { [note] }
      $0.persistenceClient.save = { _ in }
      $0.persistenceClient.delete = { _ in }
    }

    await store.send(.viewLoaded) {
      $0.isLoading = true
      $0.errorMessage = nil
    }

    await store.receive(\.notesLoadCompleted.success) {
      $0.isLoading = false
      $0.notes = [note]
      $0.filteredNotes = [note]
    }
  }

  func testSearchFiltersNotes() async {
    let work = VoiceNoteSummary(
      id: UUID(),
      createdAt: .now,
      transcript: "Sprint planning",
      summary: "Work meeting",
      category: "Work",
      audioFilePath: ""
    )
    let personal = VoiceNoteSummary(
      id: UUID(),
      createdAt: .now,
      transcript: "Buy groceries",
      summary: "Errands",
      category: "Personal",
      audioFilePath: ""
    )

    let store = TestStore(
      initialState: LibraryFeature.State(
        notes: [work, personal],
        filteredNotes: [work, personal]
      )
    ) {
      LibraryFeature()
    }

    await store.send(.searchQueryUpdated("groceries")) {
      $0.searchQuery = "groceries"
      $0.filteredNotes = [personal]
    }
  }
}
