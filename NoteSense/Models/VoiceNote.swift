import Foundation
import SwiftData

@Model
final class VoiceNote {
  @Attribute(.unique) var id: UUID
  var createdAt: Date
  var transcript: String
  var summary: String
  var category: String
  var audioFilePath: String
  var actionItemsJSON: String?

  init(
    id: UUID = UUID(),
    createdAt: Date = .now,
    transcript: String = "",
    summary: String = "",
    category: String = "General",
    audioFilePath: String = "",
    actionItemsJSON: String? = nil
  ) {
    self.id = id
    self.createdAt = createdAt
    self.transcript = transcript
    self.summary = summary
    self.category = category
    self.audioFilePath = audioFilePath
    self.actionItemsJSON = actionItemsJSON
  }
}

extension VoiceNote {
  var actionItems: [String] {
    guard
      let actionItemsJSON,
      let data = actionItemsJSON.data(using: .utf8),
      let items = try? JSONDecoder().decode([String].self, from: data)
    else {
      return []
    }
    return items
  }

  func setActionItems(_ items: [String]) {
    guard !items.isEmpty else {
      actionItemsJSON = nil
      return
    }
    actionItemsJSON = try? String(data: JSONEncoder().encode(items), encoding: .utf8)
  }
}
