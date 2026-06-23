import AVFoundation
import ComposableArchitecture
import Foundation

@DependencyClient
struct AudioRecorderClient: Sendable {
    var requestPermission: @Sendable () async -> Bool = { false }
    var startRecording: @Sendable () async throws -> Void
    var stopRecording: @Sendable () async throws -> String
    var currentMeterLevel: @Sendable () async -> Float = { 0 }
}

extension AudioRecorderClient: DependencyKey {
    static let liveValue = AudioRecorderClient()
    static let testValue = AudioRecorderClient(
        requestPermission: { true },
        startRecording: {},
        stopRecording: { "Recordings/test-recording.m4a" },
        currentMeterLevel: { 0.35 }
    )
}

extension AudioRecorderClient {
    static func live() -> Self {
        let storage = LiveAudioRecorderStorage.shared
        return AudioRecorderClient(
            requestPermission: { await storage.requestPermission() },
            startRecording: {
                try await MainActor.run {
                    try storage.startRecording()
                }
            },
            stopRecording: {
                try await MainActor.run {
                    try storage.stopRecording()
                }
            },
            currentMeterLevel: {
                await MainActor.run {
                    storage.currentMeterLevel()
                }
            }
        )
    }
}

extension DependencyValues {
    var audioRecorderClient: AudioRecorderClient {
        get { self[AudioRecorderClient.self] }
        set { self[AudioRecorderClient.self] = newValue }
    }
}

// MARK: - Live AVFoundation

private final class LiveAudioRecorderStorage: @unchecked Sendable {
    static let shared = LiveAudioRecorderStorage()

    private var recorder: AVAudioRecorder?
    private var relativePath: String?

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    @MainActor
    func startRecording() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.defaultToSpeaker]
        )
        try session.setActive(true)

        let directory = try recordingsDirectory()
        let filename = UUID().uuidString + ".m4a"
        let fileURL = directory.appendingPathComponent(filename)
        relativePath = "Recordings/\(filename)"

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        recorder.isMeteringEnabled = true
        recorder.prepareToRecord()

        guard recorder.record() else {
            throw AudioRecorderError.failedToStart
        }

        self.recorder = recorder
    }

    @MainActor
    func stopRecording() throws -> String {
        guard let recorder else {
            throw AudioRecorderError.nothingToStop
        }

        recorder.stop()
        self.recorder = nil

        try AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )

        guard let relativePath else {
            throw AudioRecorderError.missingFilePath
        }

        self.relativePath = nil
        return relativePath
    }

    @MainActor
    func currentMeterLevel() -> Float {
        guard let recorder, recorder.isRecording else { return 0 }
        recorder.updateMeters()
        let decibels = recorder.averagePower(forChannel: 0)
        let normalized = (decibels + 60) / 60
        return min(max(normalized, 0), 1)
    }

    private func recordingsDirectory() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base.appendingPathComponent(
            "Recordings",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        return directory
    }
}

private enum AudioRecorderError: LocalizedError {
    case failedToStart
    case nothingToStop
    case missingFilePath

    var errorDescription: String? {
        switch self {
        case .failedToStart:
            return "Could not start audio recording."
        case .nothingToStop:
            return "No active recording to stop."
        case .missingFilePath:
            return "Recording finished but the file path was missing."
        }
    }
}
