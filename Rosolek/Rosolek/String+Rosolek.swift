import Foundation

extension String {
    /// Parses an integer gram value from strings like "12.5 g", "300g", "1 000 g".
    /// Takes the first contiguous run of digits and optional decimal separator,
    /// converts to Double, then truncates — so "12.5 g" → 12, "300g" → 300.
    func extractGrams() -> Int {
        let cleaned = trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        // Find the first numeric token (digits + at most one dot)
        let allowedChars = CharacterSet.decimalDigits.union(CharacterSet(charactersIn: "."))
        let token = cleaned.unicodeScalars
            .prefix(while: { allowedChars.contains($0) })
        let numericStr = String(String.UnicodeScalarView(token))
        return Int(Double(numericStr) ?? 0)
    }

    /// Case-insensitive, diacritic-insensitive normalisation used for ingredient ID matching.
    func normalizedForMatching() -> String {
        folding(options: .diacriticInsensitive, locale: nil).lowercased()
    }
}
