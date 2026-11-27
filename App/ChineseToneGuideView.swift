import SwiftUI

struct ChineseToneGuideView: View {
    let transcription: String
    let languageCode: String?

    private var tones: [PinyinTone] {
        PinyinToneGuide.tones(in: transcription)
    }

    var body: some View {
        if PinyinToneGuide.isChineseLanguage(languageCode), !tones.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label("Подсказка по тонам", systemImage: "waveform.path")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(tones) { tone in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(tone.number)")
                            .font(.caption.monospacedDigit().weight(.bold))
                            .frame(width: 22, height: 22)
                            .background(.quaternary, in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tone.title).font(.caption.weight(.medium))
                            Text(tone.contour).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
