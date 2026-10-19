import Foundation

struct SessionTabRow: Identifiable, Equatable {
    var id: String
    var title: String
    var command: String?
    var isFocused: Bool
    /// User-chosen tab color. `.none` draws no strip.
    var tabColor: TerminalTabColor = .none

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled" : trimmed
    }

    var showsCommand: Bool {
        guard let command else { return false }
        return command.caseInsensitiveCompare(displayTitle) != .orderedSame
    }
}

enum SessionSidebarFilter {
    static func rows(_ rows: [SessionTabRow], matching query: String) -> [SessionTabRow] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return rows }
        return rows.filter { row in
            row.displayTitle.localizedStandardContains(needle)
                || (row.command?.localizedStandardContains(needle) ?? false)
        }
    }
}
