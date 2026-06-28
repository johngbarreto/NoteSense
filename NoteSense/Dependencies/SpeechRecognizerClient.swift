//
//  SpeechRecognizerClient.swift
//  NoteSense
//
//  Reference implementation — read alongside AudioRecorderClient.swift.
//  Same pattern: storage class holds Apple objects, live() wires closures.
//

import AVFoundation
import ComposableArchitecture
import Foundation
import Speech

@DependencyClient
struct SpeechRecognizerClient: Sendable {
    var requestAuthorization: @Sendable () async -> Bool = { false }
    var startTranscribing: @Sendable () async throws -> Void
    var stopTranscribing: @Sendable () async throws -> Void
    var transcriptStream: @Sendable () -> AsyncStream<String> = { .finished }
}

extension SpeechRecognizerClient: DependencyKey {
    static let liveValue = SpeechRecognizerClient()
    static let testValue = SpeechRecognizerClient(
        requestAuthorization: { true },
        startTranscribing: {},
        stopTranscribing: {},
        transcriptStream: { .finished }
    )
}

extension DependencyValues {
    var speechRecognizerClient: SpeechRecognizerClient {
        get { self[SpeechRecognizerClient.self] }
        set { self[SpeechRecognizerClient.self] = newValue }
    }
}

// MARK: - Live Speech

private final class SpeechRecognizerStorage: @unchecked Sendable {
    static let shared = SpeechRecognizerStorage()

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?

    /// Recognition callbacks call `yield` on this; the reducer reads via `for await`.
    private var transcriptContinuation: AsyncStream<String>.Continuation?

    private init() {
        speechRecognizer = SFSpeechRecognizer(locale: .current)
    }

    // MARK: Permissions
    //
    // Same idea as LiveAudioRecorderStorage.requestPermission:
    // Apple uses a callback → we bridge it to async/await with a continuation.

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    // MARK: Stream
    //
    // Called by the reducer BEFORE startTranscribing so the continuation exists
    // when Apple's recognition handler fires.

    func makeTranscriptStream() -> AsyncStream<String> {
        finishTranscriptStream()

        return AsyncStream { continuation in
            transcriptContinuation = continuation
        }
    }

    private func yieldTranscript(_ text: String) {
        guard !text.isEmpty else { return }
        transcriptContinuation?.yield(text)
    }

    private func finishTranscriptStream() {
        transcriptContinuation?.finish()
        transcriptContinuation = nil
    }

    // MARK: Lifecycle
    //
    // Apple's live flow (see Speech framework docs):
    // 1. SFSpeechAudioBufferRecognitionRequest — "send me audio chunks"
    // 2. recognitionTask — "I'll call you back with text"
    // 3. AVAudioEngine input tap — captures mic, appends buffers to the request

    @MainActor
    func startTranscribing() throws {
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechRecognizerError.recognizerUnavailable
        }
        guard recognitionTask == nil else {
            throw SpeechRecognizerError.alreadyTranscribing
        }

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(
            .playAndRecord,
            mode: .spokenAudio,
            options: [.defaultToSpeaker, .duckOthers]
        )
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        recognitionTask = speechRecognizer.recognitionTask(with: request) {
            [weak self] result, error in
            guard let self else { return }

            if let result {
                let text = result.bestTranscription.formattedString
                Task { @MainActor in
                    self.yieldTranscript(text)
                }
            }

            if error != nil {
                Task { @MainActor in
                    self.finishTranscriptStream()
                }
            }
        }

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) {
            buffer,
            _ in
            request.append(buffer)
        }

        engine.prepare()
        try engine.start()
        audioEngine = engine
    }

    @MainActor
    func stopTranscribing() throws {
        guard audioEngine != nil || recognitionTask != nil else {
            throw SpeechRecognizerError.nothingToStop
        }

        if let engine = audioEngine {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil

        finishTranscriptStream()

        try AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }
}

extension SpeechRecognizerClient {
    static func live() -> Self {
        let storage = SpeechRecognizerStorage.shared
        return SpeechRecognizerClient(
            requestAuthorization: {
                await storage.requestAuthorization()
            },
            startTranscribing: {
                try await MainActor.run {
                    try storage.startTranscribing()
                }
            },
            stopTranscribing: {
                try await MainActor.run {
                    try storage.stopTranscribing()
                }
            },
            transcriptStream: {
                storage.makeTranscriptStream()
            }
        )
    }
}

private enum SpeechRecognizerError: LocalizedError {
    case recognizerUnavailable
    case alreadyTranscribing
    case nothingToStop

    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            return "Speech recognition is not available on this device."
        case .alreadyTranscribing:
            return "Transcription is already in progress."
        case .nothingToStop:
            return "No active transcription to stop."
        }
    }
}
