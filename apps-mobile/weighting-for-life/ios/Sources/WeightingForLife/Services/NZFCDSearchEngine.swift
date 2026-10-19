import Foundation

/// Ranked NZFCD search match (ordered from most relevant to least relevant).
public struct RankedNZFCDMatch: Sendable, Equatable, Identifiable {
    public var id: String { item.id }
    public let item: NZFCDFoodItem
    public let score: Int
    public let rank: Int
}

/// Plain-English search engine backed by the bundled New Zealand Food Composition Database (`nzfcd_v1.json`).
public struct NZFCDSearchEngine: Sendable {
    public let catalog: [NZFCDFoodItem]

    private static let stopWords: Set<String> = [
        "a", "an", "the", "with", "and", "on", "of", "in", "plus", "to"
    ]

    public init(catalog: [NZFCDFoodItem]? = nil) {
        if let catalog {
            self.catalog = catalog
        } else {
            self.catalog = Self.loadBundledCatalog()
        }
    }

    public static func loadBundledCatalog() -> [NZFCDFoodItem] {
        guard let url = Bundle.module.url(forResource: "nzfcd_v1", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([NZFCDFoodItem].self, from: data) else {
            return []
        }
        return decoded
    }

    /// Ranks NZFCD items from most closely matched to least closely matched, returning up to `limit` (10 or 25) items.
    public func search(_ query: String, limit: Int = 10) -> [RankedNZFCDMatch] {
        let trimmed = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let separators = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ",+&"))
        let tokens = trimmed
            .components(separatedBy: separators)
            .filter { !$0.isEmpty && !Self.stopWords.contains($0) }

        let scored: [(item: NZFCDFoodItem, score: Int, index: Int)] = catalog.enumerated().map { idx, item in
            let nameLower = item.name.lowercased()
            let haystack = nameLower + " " + item.category.lowercased()
            var score = 0

            if nameLower.hasPrefix(trimmed) {
                score += 120
            } else if nameLower.contains(trimmed) {
                score += 85
            }

            let wordSeparators = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ",()"))
            let words = nameLower.components(separatedBy: wordSeparators).filter { !$0.isEmpty }

            for tok in tokens {
                let singular = tok.hasSuffix("s") ? String(tok.dropLast()) : tok
                if words.contains(tok) || words.contains(tok + "s") || words.contains(singular) {
                    score += 50
                } else if words.contains(where: { $0.hasPrefix(tok) }) {
                    score += 35
                } else if nameLower.contains(tok) {
                    score += 22
                } else if item.category.lowercased().contains(tok) {
                    score += 14
                } else {
                    var common = 0
                    for ch in tok where haystack.contains(ch) {
                        common += 1
                    }
                    let partial = Double(common) / Double(max(1, tok.count)) * 6.0
                    score += Int(partial.rounded())
                }
            }

            return (item, score, idx)
        }

        let sorted = scored.sorted { a, b in
            if a.score != b.score { return a.score > b.score }
            return a.index < b.index
        }

        let capped = sorted.prefix(max(1, limit))
        return capped.enumerated().map { offset, entry in
            RankedNZFCDMatch(item: entry.item, score: entry.score, rank: offset + 1)
        }
    }
}
