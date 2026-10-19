import Testing
@testable import Ghostty

struct SessionSidebarModelTests {
    @Test func commandMatchIsCaseInsensitive() {
        let rows = [
            SessionTabRow(id: "1", title: "src", command: "claude", isFocused: false),
            SessionTabRow(id: "2", title: "notes", command: "zsh", isFocused: true),
        ]
        let shown = SessionSidebarFilter.rows(rows, matching: "CLAUDE")
        #expect(shown.map(\.id) == ["1"])
    }

    @Test func titleMatchAndNoMatch() {
        let rows = [
            SessionTabRow(id: "1", title: "Phantom", command: "zsh", isFocused: false),
        ]
        #expect(SessionSidebarFilter.rows(rows, matching: "phan").map(\.id) == ["1"])
        #expect(SessionSidebarFilter.rows(rows, matching: "codex").isEmpty)
    }

    @Test func emptyQueryKeepsTabOrder() {
        let rows = [
            SessionTabRow(id: "a", title: "A", command: nil, isFocused: false),
            SessionTabRow(id: "b", title: "B", command: nil, isFocused: false),
        ]
        #expect(SessionSidebarFilter.rows(rows, matching: "  ").map(\.id) == ["a", "b"])
    }

    @Test func duplicateCommandIsHidden() {
        let row = SessionTabRow(id: "1", title: "claude", command: "Claude", isFocused: false)
        #expect(row.showsCommand == false)
        let other = SessionTabRow(id: "2", title: "src", command: "claude", isFocused: false)
        #expect(other.showsCommand == true)
    }
}
