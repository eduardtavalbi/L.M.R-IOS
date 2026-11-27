import Foundation

struct PinyinTone: Equatable, Identifiable {
    let index: Int
    let number: Int

    var id: Int { index }

    var title: String {
        switch number {
        case 1: return "1-й тон · ровный и высокий"
        case 2: return "2-й тон · восходящий"
        case 3: return "3-й тон · низкий, с понижением и подъёмом"
        case 4: return "4-й тон · резкий нисходящий"
        default: return "Нейтральный тон · короткий и лёгкий"
        }
    }

    var contour: String {
        switch number {
        case 1: return "высоко → высоко"
        case 2: return "середина → вверх"
        case 3: return "вниз → вверх"
        case 4: return "высоко → резко вниз"
        default: return "коротко и без выраженного контура"
        }
    }
}

enum PinyinToneGuide {
    static func tones(in transcription: String) -> [PinyinTone] {
        let decomposed = transcription.decomposedStringWithCanonicalMapping
        var detected: [Int] = []
        for scalar in decomposed.unicodeScalars {
            switch scalar.value {
            case 0x0304: detected.append(1) // macron
            case 0x0301: detected.append(2) // acute
            case 0x030C: detected.append(3) // caron
            case 0x0300: detected.append(4) // grave
            case 49...53:
                if let value = scalar.wholeNumberValue { detected.append(value) }
            default:
                continue
            }
        }
        return detected.enumerated().map { PinyinTone(index: $0.offset + 1, number: $0.element) }
    }

    static func isChineseLanguage(_ languageCode: String?) -> Bool {
        languageCode?.lowercased().hasPrefix("zh") == true
    }
}
