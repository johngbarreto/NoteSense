import ComposableArchitecture
import Foundation
import SwiftData

@DependencyClient
struct PersistenceClient: Sendable {
  var fetchAll: @Sendable () async throws -> [VoiceNoteSummary] = { [] }
  var save: @Sendable (VoiceNoteSummary) async throws -> Void
  var delete: @Sendable (UUID) async throws -> Void
}

extension PersistenceClient: DependencyKey {
  static let liveValue = PersistenceClient()
  static let testValue = PersistenceClient()
  static let previewValue = PersistenceClient(
    fetchAll: {
      [
        VoiceNoteSummary(
          id: UUID(),
          createdAt: .now,
          transcript: "Remember to follow up with the design team about WaveNote.",
          summary: "Design team follow-up",
          category: "Work",
          audioFilePath: ""
        ),
        VoiceNoteSummary(
          id: UUID(),
          createdAt: .now.addingTimeInterval(-3600),
          transcript: "Buy oat milk and coffee beans.",
          summary: "Grocery list",
          category: "Personal",
          audioFilePath: ""
        ),
      ]
    },
    save: { _ in },
    delete: { _ in }
  )
}

extension PersistenceClient {
  static func live(container: ModelContainer) -> Self {
    PersistenceClient(
      fetchAll: {
        try await MainActor.run {
          let context = ModelContext(container)
          let descriptor = FetchDescriptor<VoiceNote>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
          )
          return try context.fetch(descriptor).map(VoiceNoteSummary.init)
        }
      },
      save: { summary in
        try await MainActor.run {
          let context = ModelContext(container)
          let note = VoiceNote(
            id: summary.id,
            createdAt: summary.createdAt,
            transcript: summary.transcript,
            summary: summary.summary,
            category: summary.category,
            audioFilePath: summary.audioFilePath
          )
          context.insert(note)
          try context.save()
        }
      },
      delete: { id in
        try await MainActor.run {
          let context = ModelContext(container)
          var descriptor = FetchDescriptor<VoiceNote>(
            predicate: #Predicate { $0.id == id }
          )
          descriptor.fetchLimit = 1
          guard let note = try context.fetch(descriptor).first else { return }
          context.delete(note)
          try context.save()
        }
      }
    )
  }
}

extension DependencyValues {
  var persistenceClient: PersistenceClient {
    get { self[PersistenceClient.self] }
    set { self[PersistenceClient.self] = newValue }
  }
}
