//
//  NoteSenseApp.swift
//  NoteSense
//
//  Created by João on 11/05/26.
//

import ComposableArchitecture
import SwiftData
import SwiftUI

@main
struct NoteSenseApp: App {
  private let modelContainer: ModelContainer
  @State private var store: StoreOf<AppFeature>

  init() {
    let container = Self.makeModelContainer()
    self.modelContainer = container
    _store = State(
      initialValue: Store(initialState: AppFeature.State()) {
        AppFeature()
      } withDependencies: {
        $0.persistenceClient = .live(container: container)
        $0.audioRecorderClient = .live()
      }
    )
  }

  var body: some Scene {
    WindowGroup {
      AppView(store: store)
    }
    .modelContainer(modelContainer)
  }

  private static func makeModelContainer() -> ModelContainer {
    let schema = Schema([VoiceNote.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
      return try ModelContainer(for: schema, configurations: [configuration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }
}
