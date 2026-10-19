# Phantom

Phantom is the macOS terminal for our team. It is [Ghostty](https://ghostty.org/) with our app name and a sidebar that lists every tab in the current window, so you can jump between a shell and the AI agents you run in other tabs.

Install Phantom from this repository. The app on [ghostty.org](https://ghostty.org/download) is upstream Ghostty, and it will not include our sidebar.

## Install

You need macOS 26, Xcode 26 from the App Store, and Zig 0.16.0.

```bash
brew install zig@0.16
sudo xcode-select --switch /Applications/Xcode.app
xcodebuild -downloadComponent MetalToolchain

git clone https://github.com/yashsharma04/phantom.git
cd phantom

export PATH="$(brew --prefix zig@0.16)/bin:$PATH"
zig build -Doptimize=ReleaseFast
open macos/build/ReleaseLocal/Phantom.app
```

Use that `ReleaseFast` build day to day. A plain `zig build` is a debug build, and Phantom warns you that it is slow.

Homebrew does not put Zig 0.16 on your `PATH`. Keep the `export` line in the terminal where you build, or add it to your shell config.

Drag `Phantom.app` to the Applications folder if you want it in the Dock and in Spotlight.

## Using it

**Cmd+Shift+S**, or **View → Session Sidebar**, opens the tab list. Type to filter by the tab title or by the program running in that tab, such as `claude` or `zsh`. Click a row, or press Return, to focus that tab. A color you set on a tab shows up as a vertical strip on its row.

Right-click a tab to give it a color.

Your existing Ghostty config still applies. Phantom reads `~/.config/ghostty`. The command-line tool is still named `ghostty`, and programs still see `TERM=xterm-ghostty`, so Neovim, tmux, and remote machines keep working.

Check for Updates does nothing. Phantom does not install upstream Ghostty over itself. To get a newer Phantom, pull this repo and build again.

## What we changed

Phantom is Ghostty plus three changes:

- The app name, menus, and bundle ID are Phantom (`com.yashsharma.phantom`).
- The session sidebar lists and searches the tabs in the current window.
- The updater is disconnected from ghostty.org.

The terminal itself — rendering, tabs, splits, keybindings, shell integration — is Ghostty's.

## Credit and license

Ghostty is MIT licensed. Copyright (c) 2024 Mitchell Hashimoto and the Ghostty contributors. The license text is in [LICENSE](LICENSE).

Upstream source: [ghostty-org/ghostty](https://github.com/ghostty-org/ghostty).

Ghostty's own development guide is [HACKING.md](HACKING.md). Issues and pull requests in this repository are for Phantom.
