# NoteSense

A local-first iOS app for capturing voice notes with live transcription and AI summaries. Record a thought, see it transcribed as you speak, and browse your notes later — all stored on device.

This is a personal learning project. The app is real and usable, but the main goal is to get hands-on with modern Swift and iOS patterns rather than ship a polished product.

## What it does

- **Record** — tap to start/stop recording with a live audio level meter
- **Library** — browse, search, and delete saved voice notes
- **Settings** — app info and status

Each note stores the audio file, transcript, and metadata (summary, category) locally via SwiftData. AI summaries and categorization are planned; the data model is already in place.

## What I'm learning

This project is my sandbox for building a non-trivial SwiftUI app with clear architecture and testability.

| Area | What I'm practicing |
|------|---------------------|
| **[The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture)** | Feature reducers, scoped state, side effects, and cancellation |
| **Dependency injection** | `@DependencyClient` wrappers around audio, speech, and persistence so features stay pure and testable |
| **Testing** | `TestStore` with mocked dependencies for reducer-level unit tests |
| **SwiftUI** | Tab-based navigation, bindings to TCA stores |
| **SwiftData** | Local persistence with a `PersistenceClient` abstraction over `ModelContext` |
| **AVFoundation** | Microphone permissions, recording, and meter levels |
| **Speech** | On-device transcription via `SpeechRecognizerClient` (in progress) |

The codebase is organized by feature (`Recording`, `Library`, `Settings`) with shared dependencies in `Dependencies/` and models in `Models/`.

## Project structure

```
NoteSense/
├── App/              # App entry point, root view, SwiftData container
├── Features/         # TCA reducers + SwiftUI views per screen
├── Dependencies/     # AudioRecorderClient, SpeechRecognizerClient, PersistenceClient
└── Models/           # VoiceNote (SwiftData) + VoiceNoteSummary (feature layer)
```

## Requirements

- Xcode with a recent iOS SDK (project targets iOS 26.4)
- A physical device or simulator with microphone access for recording

## Getting started

1. Clone the repo
2. Open `NoteSense.xcodeproj` in Xcode
3. Build and run on a simulator or device
4. Grant microphone permission when prompted

Dependencies are managed via Swift Package Manager (TCA and its transitive packages resolve automatically).

## Running tests

Unit tests live in `NoteSenseTests/` and cover the main reducers (`AppFeature`, `RecordingFeature`, `LibraryFeature`) using `TestStore` and dependency overrides.

```bash
xcodebuild test -scheme NoteSense -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Roadmap

- [ ] Wire up real-time speech transcription (replacing the current placeholder)
- [ ] Generate AI summaries and categories after recording
- [ ] Playback for saved audio notes
- [ ] Note detail screen

## License

Licensed under the [GNU General Public License v3.0](LICENSE).
