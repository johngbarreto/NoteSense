import Foundation

struct VoiceNoteSummary: Equatable, Identifiable, Sendable {
  let id: UUID
  let createdAt: Date
  let transcript: String
  let summary: String
  let category: String
  let audioFilePath: String

  init(
    id: UUID,
    createdAt: Date,
    transcript: String,
    summary: String,
    category: String,
    audioFilePath: String
  ) {
    self.id = id
    self.createdAt = createdAt
    self.transcript = transcript
    self.summary = summary
    self.category = category
    self.audioFilePath = audioFilePath
  }

  init(note: VoiceNote) {
    self.init(
      id: note.id,
      createdAt: note.createdAt,
      transcript: note.transcript,
      summary: note.summary,
      category: note.category,
      audioFilePath: note.audioFilePath
    )
  }

  var displayTitle: String {
    if !summary.isEmpty { return summary }
    if !transcript.isEmpty { return String(transcript.prefix(80)) }
    return "Voice note"
  }
}
