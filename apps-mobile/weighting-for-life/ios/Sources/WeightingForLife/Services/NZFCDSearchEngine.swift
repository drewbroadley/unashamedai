import Foundation

/// Ranked NZFCD search match (ordered from most relevant to least relevant).
public struct RankedNZFCDMatch: Sendable, Equatable, Identifiable {
    public var id: String { item.id }
    public let item: NZFCDFoodItem
    public let score: Int
    public let rank: Int
}

/// Pre-indexed entry for fast (<1ms) full-catalog autocomplete across all 2,904 NZFCD foods.
private struct IndexedNZFCDItem: Sendable {
    let item: NZFCDFoodItem
    let index: Int
    let nameNormalized: String
    let categoryNormalized: String
    let words: [String]
}

/// Plain-English autocomplete & search engine backed by the bundled New Zealand Food Composition Database (`nzfcd_v1.json` — 2,904 items from NZ FOODfiles 2024 v1).
public struct NZFCDSearchEngine: Sendable {
    public let catalog: [NZFCDFoodItem]
    private let indexedCatalog: [IndexedNZFCDItem]

    private static let stopWords: Set<String> = [
        "a", "an", "the", "with", "and", "on", "of", "in", "plus", "to", "from"
    ]

    private static let sharedIndexed: [IndexedNZFCDItem] = {
        let items = loadBundledCatalog()
        return buildIndex(for: items)
    }()

    public init(catalog: [NZFCDFoodItem]? = nil) {
        if let catalog {
            self.catalog = catalog
            self.indexedCatalog = Self.buildIndex(for: catalog)
        } else {
            let shared = Self.sharedIndexed
            self.indexedCatalog = shared
            self.catalog = shared.map(\.item)
        }
    }

    public static func loadBundledCatalog() -> [NZFCDFoodItem] {
        let candidateURLs: [URL?] = [
            Bundle.module.url(forResource: "nzfcd_v1", withExtension: "json"),
            Bundle.main.url(forResource: "nzfcd_v1", withExtension: "json"),
            Bundle.main.url(
                forResource: "nzfcd_v1",
                withExtension: "json",
                subdirectory: "WeightingForLife_WeightingForLifeCore.bundle"
            )
        ]
        for case let url? in candidateURLs {
            if let data = try? Data(contentsOf: url),
               let decoded = try? JSONDecoder().decode([NZFCDFoodItem].self, from: data),
               !decoded.isEmpty {
                return decoded
            }
        }
        return []
    }

    private static func normalize(_ text: String) -> String {
        let folded = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        var scalars = String.UnicodeScalarView()
        scalars.reserveCapacity(folded.unicodeScalars.count)
        for s in folded.unicodeScalars {
            if s == "'" || s == "’" || s == "‘" || s == "™" || s == "®" {
                continue
            } else if CharacterSet.alphanumerics.contains(s) {
                scalars.append(s)
            } else {
                scalars.append(" ")
            }
        }
        return String(scalars)
    }

    private static func buildIndex(for items: [NZFCDFoodItem]) -> [IndexedNZFCDItem] {
        items.enumerated().map { idx, item in
            let nameNorm = normalize(item.name)
            let catNorm = normalize(item.category)
            let words = nameNorm.split(separator: " ").map(String.init)
            return IndexedNZFCDItem(
                item: item,
                index: idx,
                nameNormalized: nameNorm,
                categoryNormalized: catNorm,
                words: words
            )
        }
    }

    /// Returns default popular NZ starter suggestions when the search field is focused before typing.
    public func defaultSuggestions(limit: Int = 10) -> [RankedNZFCDMatch] {
        let capped = indexedCatalog.prefix(max(1, limit))
        return capped.enumerated().map { offset, entry in
            RankedNZFCDMatch(item: entry.item, score: 100 - offset, rank: offset + 1)
        }
    }

    /// Real-time keystroke-by-keystroke autocomplete across all 2,904 NZFCD items (starting from the 1st character typed).
    public func search(_ query: String, limit: Int = 10) -> [RankedNZFCDMatch] {
        let normQuery = Self.normalize(query).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normQuery.isEmpty else { return [] }

        let rawTokens = normQuery
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }
        let filteredTokens = rawTokens.filter { !Self.stopWords.contains($0) }
        // Keep the last token even if it's a 1-letter stopword prefix (e.g., typing "a" for apple/avocado or "t" for toast)
        let activeTokens: [String] = {
            if filteredTokens.isEmpty { return rawTokens }
            if let last = rawTokens.last, filteredTokens.last != last {
                return filteredTokens + [last]
            }
            return filteredTokens
        }()
        guard !activeTokens.isEmpty else { return [] }

        let compactQuery = activeTokens.joined(separator: " ")

        var matches: [(item: NZFCDFoodItem, score: Int, index: Int)] = []
        matches.reserveCapacity(128)

        for entry in indexedCatalog {
            var score = 0
            var matchedTokens = 0

            if entry.nameNormalized == compactQuery {
                score += 500
            } else if entry.nameNormalized.hasPrefix(compactQuery) {
                score += 260
            } else if compactQuery.count >= 2 && entry.nameNormalized.contains(compactQuery) {
                score += 120
            }

            let firstWord = entry.words.first ?? ""

            for tok in activeTokens {
                let singular = (tok.count > 3 && tok.hasSuffix("s")) ? String(tok.dropLast()) : tok
                let plural = tok + "s"

                var tokScore = 0
                if firstWord == tok || firstWord == singular || firstWord == plural {
                    tokScore = 200
                } else if firstWord.hasPrefix(tok) || (singular.count >= 2 && firstWord.hasPrefix(singular)) {
                    // Works from the very 1st character typed ("a" -> Apple, Avocado; "p" -> Pie, Pizza, Poached)
                    tokScore = 145
                } else if entry.words.contains(tok) || entry.words.contains(singular) || entry.words.contains(plural) {
                    tokScore = 105
                } else if entry.words.contains(where: { $0.hasPrefix(tok) || (singular.count >= 2 && $0.hasPrefix(singular)) }) {
                    // Matches any word prefix from the 1st character (e.g. "f" -> "Coffee, flat white", "v" -> "Bread, Vogels")
                    tokScore = tok.count == 1 ? 65 : 80
                } else if tok.count >= 3 && entry.nameNormalized.contains(tok) {
                    tokScore = 25
                } else if tok.count >= 2 && (entry.categoryNormalized.contains(tok) || entry.categoryNormalized.contains(singular)) {
                    tokScore = 30
                }

                if tokScore > 0 {
                    matchedTokens += 1
                    score += tokScore
                }
            }

            guard matchedTokens > 0 else { continue }

            if matchedTokens == activeTokens.count {
                score += matchedTokens * 160
            } else {
                score -= (activeTokens.count - matchedTokens) * 75
            }

            // Boost everyday curated NZ foods so 1-2 letter prefixes surface the most common foods first
            if entry.index < 47 {
                score += 45
            }

            if score > 0 {
                matches.append((entry.item, score, entry.index))
            }
        }

        matches.sort { a, b in
            if a.score != b.score { return a.score > b.score }
            if a.item.name.count != b.item.name.count { return a.item.name.count < b.item.name.count }
            return a.index < b.index
        }

        let capped = matches.prefix(max(1, limit))
        return capped.enumerated().map { offset, entry in
            RankedNZFCDMatch(item: entry.item, score: entry.score, rank: offset + 1)
        }
    }
}
