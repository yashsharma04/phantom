# Session sidebar

A collapsible sidebar on the current Phantom window lists every tab in that window and filters them as you type, so switching between shells and AI-agent tabs does not depend on the tab bar.

## Behavior

The sidebar sits on the left. A search field is at the top. Under it, one row per tab, in tab-bar order.

Each row shows the tab title. A second line shows the foreground command in that tab's focused pane (`claude`, `zsh`) when the command name is different from the title. A split tab is still one row. The focused tab is highlighted.

Typing filters immediately. The match is case-insensitive against the title and the command. No match shows "No matching tabs".

Clicking a row, or moving with the arrow keys and pressing Return, focuses that tab and leaves the sidebar open. The pane that already had focus inside the tab stays focused. Escape clears the query. A second Escape returns focus to the terminal.

A menu item and the `toggle_session_sidebar` key action show and hide the sidebar. Opening it focuses the search field. The default binding is Cmd+Shift+S. It starts hidden. Whether it was left open, and its width, are remembered.

Tabs that open, close, or change title update the list immediately. While the sidebar is visible it re-reads the foreground command, so a program started after the tab opened appears without a reload. If the process name cannot be read, the row is title-only and still matches on the title.

## Structure

The sidebar is SwiftUI in the macOS app, beside the existing terminal view. It reads the native tab group of the current window. The command name comes from the foreground PID Phantom already exposes for a surface. Filtering is a pure function of the row list and the query.

The Zig core is unchanged except for a new key action, added the same way as `toggle_command_palette`, so the shortcut can be rebound. Linux handles the action as a no-op so the shared action enum still compiles.

## Tests

Unit tests cover the filter (title match, command match, case, no match) and the rule that hides a command line when it duplicates the title.
