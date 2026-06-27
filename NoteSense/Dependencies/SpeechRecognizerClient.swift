//
//  SpeechRecognizerClient.swift
//  NoteSense
//
//  Created by João on 25/06/26.
//

import ComposableArchitecture
import Foundation

@DependencyClient
struct SpeechRecognizerClient: Sendable {
    var requestAuthorization: @Sendable () async -> Bool = { false }
    var startTranscribing: @Sendable () async throws -> Void
    var stopTranscribing: @Sendable () async throws -> Void
    var transcriptStream: @Sendable () async -> String = { "Test" }
}

extension SpeechRecognizerClient: DependencyKey {
    static let liveValue = SpeechRecognizerClient()
    static let testValue = SpeechRecognizerClient(
        requestAuthorization: { true },
        startTranscribing: {},
        stopTranscribing: {},
        transcriptStream: { "Test value stream" })
}

extension DependencyValues {
    var speechRecognizeClient: SpeechRecognizerClient {
        get { self[SpeechRecognizerClient.self] }
        set { self[SpeechRecognizerClient.self] = newValue }
    }
}

//private final class SpeechRecognizerStorage: @unchecked Sendable {
//    static let shared = SpeechRecognizerStorage()
//    
//    private var transcriber:
//}

//extension SpeechRecognizerClient {
//    static func live() -> Self {
//    }
//}
