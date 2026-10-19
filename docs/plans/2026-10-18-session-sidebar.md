# Session sidebar implementation plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a collapsible, searchable sidebar that lists the tabs in the current Phantom window and focuses the one you pick.

**Architecture:** A pure Swift model builds one row per native macOS tab from the window's tab group, using the tab title and the foreground process name of that tab's focused surface. A SwiftUI sidebar filters those rows and focuses a tab through the existing present-terminal notification. A new `toggle_session_sidebar` key action, wired like `toggle_command_palette`, shows the sidebar and focuses its search field.

**Tech Stack:** SwiftUI and AppKit in `macos/`, Zig keybinding actions in `src/`, Swift Testing (`import Testing`) for `macos/Tests`.

---

### Task 1: Row model and filter

**Files:**
- Create: `macos/Sources/Features/Session Sidebar/SessionSidebarModel.swift`
- Test: `macos/Tests/Features/Session Sidebar/SessionSidebarModelTests.swift`

**Step 1: Write the failing test**

```swift
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
```

**Step 2: Run the test to verify it fails**

Run from `macos/`:

```bash
xcodebuild test -scheme Ghostty -only-testing:GhosttyTests/SessionSidebarModelTests -destination 'platform=macOS'
```

Expected: FAIL because `SessionTabRow` and `SessionSidebarFilter` do not exist. `DEVELOPER_DIR` must be `/Volumes/Xcode/Xcode.app/Contents/Developer` when the Seagate image is the selected Xcode.

**Step 3: Write the minimal implementation**

```swift
struct SessionTabRow: Identifiable, Equatable {
    var id: String
    var title: String
    var command: String?
    var isFocused: Bool

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
```

**Step 4: Run the test to verify it passes**

Same `xcodebuild test` command. Expected: PASS, 4 tests.

### Task 2: Process name from a PID

**Files:**
- Create: `macos/Sources/Features/Session Sidebar/ProcessName.swift`
- Test: `macos/Tests/Features/Session Sidebar/ProcessNameTests.swift`

**Step 1: Write the failing test**

```swift
import Testing
@testable import Ghostty

struct ProcessNameTests {
    @Test func basenameOfCurrentProcess() {
        let name = ProcessName.basename(pid: ProcessInfo.processInfo.processIdentifier)
        #expect(name?.isEmpty == false)
    }

    @Test func deadPidIsNil() {
        #expect(ProcessName.basename(pid: -1) == nil)
    }
}
```

**Step 2: Run it and confirm FAIL**

`xcodebuild test -scheme Ghostty -only-testing:GhosttyTests/ProcessNameTests -destination 'platform=macOS'`

**Step 3: Implement with `proc_pidpath`**

```swift
import Darwin

enum ProcessName {
    static func basename(pid: Int32) -> String? {
        guard pid > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        let length = proc_pidpath(pid, &buffer, UInt32(buffer.count))
        guard length > 0 else { return nil }
        let path = String(cString: buffer)
        let name = (path as NSString).lastPathComponent
        return name.isEmpty ? nil : name
    }
}
```

`Ghostty.Surface.foregroundPID` is an `Int`. Callers convert with `Int32(exactly:)`.

**Step 4: Re-run ProcessNameTests.** Expected: PASS.

### Task 3: Key action

**Files:**
- Modify: `src/input/Binding.zig` (next to `toggle_command_palette`, around the action enum and the surface-scoped set)
- Modify: `src/apprt/action.zig` (`toggle_command_palette` field and `Key` enum)
- Modify: `include/ghostty.h` (`GHOSTTY_ACTION_TOGGLE_COMMAND_PALETTE` and the following entries; the C enum order must match `action.zig`'s `Key`)
- Modify: `src/Surface.zig` (the `toggle_command_palette` perform branch)
- Modify: `src/config/Config.zig` (default binding next to Cmd+Shift+P)
- Modify: `src/input/command.zig` (same "no palette command" group as `toggle_command_palette`)
- Modify: `src/apprt/gtk/class/application.zig` (exhaustive switch: log and return, macOS only)
- Modify: `macos/Sources/Ghostty/Ghostty.App.swift` (handle the new C tag like `toggleCommandPalette`)
- Modify: `macos/Sources/Ghostty/GhosttyPackage.swift` (notification name)

Add `toggle_session_sidebar` everywhere `toggle_command_palette` is switched, so Zig still compiles. Default binding:

```zig
.{ .key = .{ .unicode = 's' }, .mods = inputpkg.ctrlOrSuper(.{ .shift = true }) }
```

On macOS that is Cmd+Shift+S. Confirm that chord is not already in `Config.zig` before adding it. GTK posts nothing. macOS posts `ghosttySessionSidebarDidToggle` with the surface view as the object, matching the command palette.

**Step: Build the core**

```bash
DEVELOPER_DIR=/Volumes/Xcode/Xcode.app/Contents/Developer \
  $(brew --prefix zig@0.16)/bin/zig build -Demit-xcframework=false
```

Expected: success. Do not run the full `zig build test` target; the unit tests for this feature are the Swift tests.

### Task 4: Sidebar view and window wiring

**Files:**
- Create: `macos/Sources/Features/Session Sidebar/SessionSidebarView.swift`
- Modify: `macos/Sources/Features/Terminal/TerminalView.swift` (`TerminalViewModel` gains `sessionSidebarIsShowing`)
- Modify: `macos/Sources/Features/Terminal/BaseTerminalController.swift` (published flag, notification handler, tab list, focus)
- Modify: `macos/Sources/App/AppDelegate.swift` and `macos/Sources/App/MainMenu.xib` (View menu item "Session Sidebar", outlet, `syncMenuShortcut` for `toggle_session_sidebar`)

Rows come from `window.tabGroup?.windows` in tab order. A window with no tab group is a single row. Each row's id is the window's stable identifier. Title is the tab title override, then the focused surface title, then "Untitled". Command is `ProcessName.basename` of `focusedSurface?.foregroundPID`, falling back to the leftmost leaf when nothing in that tab is focused.

Selecting a row posts `Ghostty.Notification.ghosttyPresentTerminal` with that tab's focused surface (or leftmost leaf). The sidebar stays open.

`SessionSidebarView` is an `HSplitView` item to the left of `TerminalSplitTreeView` when `sessionSidebarIsShowing` is true. Search field is focused when the flag becomes true. Escape in the field clears a non-empty query, then resigns first responder. Arrow keys move a selection index. Return focuses that row.

While the flag is true, a 1 second timer re-reads foreground PIDs. Title and tab-group changes refresh immediately from the controller's existing surface and window callbacks. No matches renders the text "No matching tabs".

Persist `sessionSidebarVisible` (Bool, default false) and `sessionSidebarWidth` (Double) in `UserDefaults.standard`. Apply them when the controller loads.

**Step: Build the app**

```bash
export DEVELOPER_DIR=/Volumes/Xcode/Xcode.app/Contents/Developer
export PATH="$(brew --prefix zig@0.16)/bin:$PATH"
zig build
```

Expected: `macos/build/Debug/Phantom.app` is produced.

**Step: Re-run the Swift unit tests from Tasks 1 and 2.** Expected: PASS.

### Task 5: Manual check

Launch `macos/build/Debug/Phantom.app`. Open three tabs, run `claude` in one and leave the others in the shell.

- Cmd+Shift+S opens the sidebar and focuses search. The same shortcut closes it.
- Rows follow tab order. The Claude tab's second line is `claude` unless the title is already that.
- Typing `claude` leaves only that row. Return focuses it. The sidebar stays open.
- Escape clears the query, then returns to the terminal.
- Quit and relaunch: the sidebar is in the state you left it.
