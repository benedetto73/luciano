import Foundation

extension String {
    /// Trims whitespace and newlines from both ends
    var trimmed: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Returns true if string contains only whitespace
    var isBlank: Bool {
        self.trimmed.isEmpty
    }
    
    /// Returns true if string is not blank
    var isNotBlank: Bool {
        !isBlank
    }
    
    /// Truncates string to specified length, adding ellipsis if needed
    func truncated(to length: Int, addEllipsis: Bool = true) -> String {
        guard self.count > length else { return self }
        let endIndex = self.index(self.startIndex, offsetBy: length)
        let truncated = String(self[..<endIndex])
        return addEllipsis ? truncated + "..." : truncated
    }
    
    /// Validates email format
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    /// Validates URL format
    var isValidURL: Bool {
        guard let url = URL(string: self) else { return false }
        return url.scheme != nil && url.host != nil
    }
    
    /// Removes all whitespace from string
    var withoutWhitespace: String {
        self.components(separatedBy: .whitespaces).joined()
    }
    
    /// Removes all newlines from string
    var withoutNewlines: String {
        self.components(separatedBy: .newlines).joined(separator: " ")
    }
    
    /// Capitalizes first letter only
    var capitalizedFirstLetter: String {
        guard let first = self.first else { return self }
        return first.uppercased() + self.dropFirst()
    }
    
    /// Returns word count
    var wordCount: Int {
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.count
    }
    
    /// Returns character count excluding whitespace
    var characterCountWithoutWhitespace: Int {
        self.withoutWhitespace.count
    }
    
    /// Safely subscript with range
    subscript(safe range: Range<Int>) -> String? {
        guard range.lowerBound >= 0,
              range.upperBound <= self.count else { return nil }
        let start = self.index(self.startIndex, offsetBy: range.lowerBound)
        let end = self.index(self.startIndex, offsetBy: range.upperBound)
        return String(self[start..<end])
    }
    
    /// Returns preview text (first n characters)
    func preview(length: Int = 100) -> String {
        truncated(to: length, addEllipsis: true)
    }
    
    /// Replaces multiple consecutive spaces with single space
    var condensedWhitespace: String {
        self.replacingOccurrences(of: "[ ]+", with: " ", options: .regularExpression)
    }
    
    /// Converts string to snake_case
    var snakeCase: String {
        let pattern = "([a-z0-9])([A-Z])"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: self.count)
        let result = regex?.stringByReplacingMatches(
            in: self,
            range: range,
            withTemplate: "$1_$2"
        )
        return result?.lowercased() ?? self.lowercased()
    }
    
    /// Converts string to camelCase
    var camelCase: String {
        let components = self.components(separatedBy: CharacterSet.alphanumerics.inverted)
        let first = components.first?.lowercased() ?? ""
        let rest = components.dropFirst().map { $0.capitalizedFirstLetter }
        return ([first] + rest).joined()
    }
    
    /// Returns true if string contains substring (case insensitive)
    func containsIgnoreCase(_ substring: String) -> Bool {
        self.lowercased().contains(substring.lowercased())
    }
    
    /// Removes HTML tags from string
    var withoutHTMLTags: String {
        self.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )
    }
    
    /// Escapes special characters for use in regex
    var regexEscaped: String {
        NSRegularExpression.escapedPattern(for: self)
    }
}
