//
//  SmartSearchEngine.swift
//  SmartFinance
//

import Foundation
import NaturalLanguage
import UIKit

enum SmartSearchEngine {

    static let categoryKeywords: [String: [String]] = [
        "transport": ["mashina", "avto", "benzin", "metan", "zapravka", "moy", "jarima",
                      "taksi", "avtobus", "metro", "poezd", "yo'l", "motor", "kir"],
        "oziq-ovqat": ["osh", "non", "tushlik", "kechki", "nonushta", "restoran", "kafe",
                       "bozor", "supermarket", "mahsulot", "ovqat", "go'sht", "sabzavot"],
        "kiyim-kechak": ["kiyim", "shim", "ko'ylak", "kurka", "poyabzal",
                         "do'kon", "magazin", "moda", "belbog", "futbolka"],
        "salomatlik": ["dorixona", "dori", "doktor", "shifoxona", "klinika", "muolaja",
                       "sport", "fitnes", "vitamin", "kasallik", "shifo"],
        "ijara": ["ijara", "uy", "kvartira", "xona", "kommunal", "gaz", "suv",
                  "elektr", "internet", "oylik"],
        "o'yin-kulgi": ["kino", "teatr", "konsert", "o'yin", "sayohat", "dam", "bayram",
                        "futbol", "club", "kafe"]
    ]

    static func lemmatize(_ word: String) -> String {
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = word
        var result = word
        tagger.enumerateTags(in: word.startIndex..<word.endIndex,
                             unit: .word, scheme: .lemma, options: []) { tag, _ in
            if let l = tag?.rawValue, !l.isEmpty { result = l.lowercased() }
            return true
        }
        return result
    }

    static func context(for query: String) -> (category: String?, keywords: Set<String>) {
        let q = query.lowercased()
        let lemma = lemmatize(q)
        for (cat, kws) in categoryKeywords {
            let hit = cat.contains(q) || q.contains(cat) ||
                kws.contains(where: { $0.contains(q) || q.contains($0) || $0.contains(lemma) || lemma.contains($0) })
            if hit { return (cat, Set(kws)) }
        }
        return (nil, [])
    }

    static func matches(transaction: Transaction, query: String) -> Bool {
        let q = query.lowercased()
        let title = transaction.title?.lowercased() ?? ""
        let category = transaction.category?.lowercased() ?? ""

        if title.contains(q) || category.contains(q) { return true }

        let (relCat, relKWs) = context(for: q)
        if let rc = relCat, category.contains(rc) { return true }
        if relKWs.contains(where: { title.contains($0) || category.contains($0) }) { return true }
        return false
    }

    static func highlight(text: String, query: String,
                          font: UIFont,
                          color: UIColor = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)) -> NSAttributedString {
        let attr = NSMutableAttributedString(string: text,
                                             attributes: [.font: font, .foregroundColor: UIColor.label])
        let lower = text.lowercased()
        let q = query.lowercased()

        func apply(nsRange: NSRange, boldFont: UIFont, highlightColor: UIColor) {
            attr.addAttributes([
                .foregroundColor: highlightColor,
                .font: boldFont
            ], range: nsRange)
        }

        let boldFont = UIFont.systemFont(ofSize: font.pointSize, weight: .medium)
        let semiboldFont = UIFont.systemFont(ofSize: font.pointSize, weight: .semibold)
        let dimColor = color.withAlphaComponent(0.75)

        var searchStart = lower.startIndex
        while searchStart < lower.endIndex,
              let found = lower.range(of: q, range: searchStart..<lower.endIndex) {
            let nsRange = NSRange(found, in: text)
            apply(nsRange: nsRange, boldFont: boldFont, highlightColor: color)
            searchStart = found.upperBound
        }

        let (_, kws) = context(for: q)
        for kw in kws {
            var kwStart = lower.startIndex
            while kwStart < lower.endIndex,
                  let found = lower.range(of: kw, range: kwStart..<lower.endIndex) {
                let nsRange = NSRange(found, in: text)
                apply(nsRange: nsRange, boldFont: semiboldFont, highlightColor: dimColor)
                kwStart = found.upperBound
            }
        }
        return attr
    }
}
