import AVFoundation
import Combine
import Foundation
import Speech

final class PronunciationRecognitionService: ObservableObject {
    @Published private(set) var isListening = false
    @Published private(set) var recognizedText: String?
    @Published private(set) var feedback: String?
    @Published private(set) var errorMessage: String?

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func start(expectedText: String, languageCode: String?) {
        guard !isListening else { return }
        guard let localeIdentifier = PronunciationVoiceOptions.recognitionLocale(for: languageCode),
              let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier)) else {
            errorMessage = "Для этого языка распознавание речи недоступно на устройстве."
            return
        }
        guard recognizer.isAvailable else {
            errorMessage = "Распознавание речи сейчас недоступно. Попробуй позже."
            return
        }
        guard recognizer.supportsOnDeviceRecognition else {
            errorMessage = "Для этого языка iOS не поддерживает локальное распознавание. Проверка не запущена, аудио не отправлялось."
            return
        }

        errorMessage = nil
        recognizedText = nil
        feedback = nil
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                guard let self else { return }
                guard status == .authorized else {
                    self.errorMessage = "Разреши распознавание речи для L.M.R. в настройках iPhone."
                    return
                }
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        guard granted else {
                            self.errorMessage = "Для проверки произношения нужен доступ к микрофону."
                            return
                        }
                        self.beginRecognition(recognizer: recognizer, expectedText: expectedText)
                    }
                }
            }
        }
    }

    func stop() {
        guard isListening else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        isListening = false
    }

    private func beginRecognition(recognizer: SFSpeechRecognizer, expectedText: String) {
        do {
            recognitionTask?.cancel()
            recognitionTask = nil
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = false
            request.requiresOnDeviceRecognition = true
            recognitionRequest = request

            let input = audioEngine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.installTap(onBus: 0, bufferSize: 1_024, format: format) { buffer, _ in
                request.append(buffer)
            }
            audioEngine.prepare()
            try audioEngine.start()
            isListening = true

            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                if let result, result.isFinal {
                    let text = result.bestTranscription.formattedString
                    DispatchQueue.main.async {
                        guard let self else { return }
                        self.recognizedText = text
                        self.feedback = PronunciationAssessment.feedback(recognized: text, expected: expectedText)
                        self.finish()
                    }
                } else if let error {
                    DispatchQueue.main.async {
                        guard let self else { return }
                        self.errorMessage = error.localizedDescription
                        self.finish()
                    }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            finish()
        }
    }

    private func finish() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
    }

    deinit {
        audioEngine.stop()
        recognitionTask?.cancel()
    }
}
