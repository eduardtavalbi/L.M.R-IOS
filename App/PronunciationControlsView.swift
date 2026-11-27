import AVFoundation
import SwiftUI

struct PronunciationControlsView: View {
    let word: Word
    let languageCode: String?

    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var recorder: AVAudioRecorder?
    @State private var player: AVAudioPlayer?
    @State private var isRecording = false
    @State private var selectedVoiceCode = "en-US"
    @State private var message: String?
    @State private var error: String?

    private var recordingURL: URL? {
        guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let safeID = word.id.replacingOccurrences(of: "/", with: "_")
        return directory.appendingPathComponent("Pronunciation", isDirectory: true)
            .appendingPathComponent("\(safeID).m4a")
    }

    private var hasRecording: Bool {
        guard let recordingURL else { return false }
        return FileManager.default.fileExists(atPath: recordingURL.path)
    }

    private var voiceOptions: [String] {
        PronunciationVoiceOptions.availableVoices(for: languageCode)
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button(action: speakReference) {
                    Label("Эталон", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(.bordered)
                .disabled(languageCode == nil || languageCode?.isEmpty == true)

                Button(action: toggleRecording) {
                    Label(isRecording ? "Остановить" : "Записать", systemImage: isRecording ? "stop.circle.fill" : "mic.fill")
                }
                .buttonStyle(.bordered)
                .tint(isRecording ? .red : .accentColor)
            }

            if hasRecording {
                Button(action: playRecording) {
                    Label("Моя запись", systemImage: "play.circle")
                }
                .font(.subheadline)
                .buttonStyle(.borderless)
            }

            if voiceOptions.count > 1 {
                Picker("Вариант произношения", selection: $selectedVoiceCode) {
                    Text("US").tag("en-US")
                    Text("UK").tag("en-GB")
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 180)
            }

            if let message {
                Text(message).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.top, 4)
        .onAppear {
            selectedVoiceCode = PronunciationVoiceOptions.defaultVoice(for: languageCode) ?? "en-US"
        }
        .onDisappear {
            synthesizer.stopSpeaking(at: .immediate)
            if isRecording { recorder?.stop() }
            player?.stop()
        }
        .alert("Аудио", isPresented: Binding(
            get: { error != nil },
            set: { if !$0 { error = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(error ?? "")
        }
    }

    private func speakReference() {
        guard let languageCode, !languageCode.isEmpty else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
            synthesizer.stopSpeaking(at: .immediate)
            let utterance = AVSpeechUtterance(string: word.text)
            let voiceCode = voiceOptions.count > 1 ? selectedVoiceCode : languageCode
            utterance.voice = AVSpeechSynthesisVoice(language: voiceCode)
                ?? AVSpeechSynthesisVoice(language: languageCode)
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
            synthesizer.speak(utterance)
            message = "Системное произношение · \(voiceCode)"
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func toggleRecording() {
        if isRecording {
            recorder?.stop()
            recorder = nil
            isRecording = false
            message = "Запись сохранена"
            return
        }

        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                guard granted else {
                    self.error = "Нет разрешения на микрофон. Разреши доступ в настройках iPhone."
                    return
                }
                self.startRecording()
            }
        }
    }

    private func startRecording() {
        guard let recordingURL else {
            error = "Не удалось подготовить файл записи."
            return
        }
        do {
            let folder = recordingURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let newRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            newRecorder.prepareToRecord()
            guard newRecorder.record() else {
                throw NSError(domain: "LMR.Audio", code: 1, userInfo: [NSLocalizedDescriptionKey: "Не удалось начать запись."])
            }
            recorder = newRecorder
            isRecording = true
            message = "Идёт запись…"
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func playRecording() {
        guard let recordingURL, FileManager.default.fileExists(atPath: recordingURL.path) else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            player = try AVAudioPlayer(contentsOf: recordingURL)
            player?.prepareToPlay()
            player?.play()
            message = "Воспроизводится твоя запись"
        } catch {
            self.error = error.localizedDescription
        }
    }
}
