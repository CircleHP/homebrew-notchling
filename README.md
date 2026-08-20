# Notchling — Homebrew tap

A native macOS notch widget that shows what every Claude Code session is doing, and gets you back to
the one that needs you. Click a row, land in the terminal tab that owns it.

<p align="center">
  <img src="https://github.com/CircleHP/notchling/raw/main/media/notchling.gif" width="700" alt="Notchling in the notch: a compact strip showing session counts drops open by itself into a panel listing six Claude Code sessions — one blocked on a permission prompt, one whose turn failed, three working, one just finished — with a subagent beneath one of them, coloured bars marking the sessions the user has tagged, and plan-usage meters at the bottom, then closes again">
</p>

This repository is the tap. The app itself, its documentation and its issues live in
**[CircleHP/notchling](https://github.com/CircleHP/notchling)**.

## Install

```sh
brew install CircleHP/notchling/notchling
notchling-hooks setup
```

`setup` asks before it changes anything: it wires the Claude Code hooks, offers the plan-usage status
line, and starts the widget now and at login. Afterwards, restart any Claude sessions that were already
running — hooks are read at session start.

Name the formula in full rather than tapping first. Homebrew trusts a third-party tap when you name it
in full, so `brew install CircleHP/notchling/notchling` needs no separate `brew trust`, while a bare
`brew install notchling` after tapping will be refused.

### Why nothing compiles, and nothing warns

The formula pours a **bottle**: a prebuilt, universal (`arm64` + `x86_64`) bundle targeting macOS 14 and
later. No Xcode, no Command Line Tools, no build.

It is also not a cask, deliberately. Homebrew quarantines what a cask installs, and a quarantined app
that is not notarized meets Gatekeeper — which since macOS 15 means a trip through System Settings to
launch it at all. Nothing on the formula path is quarantined, so macOS never gates the app, and the
project needs no paid Apple Developer membership to stay out of your way.

The app is signed ad-hoc, which is free and involves no certificate. One consequence, and only if you
use the **iTerm2 or Terminal.app** jump: macOS asks permission to control them the first time, and asks
again after an upgrade, because an ad-hoc signature's identity changes with each build. Warp is
unaffected — that jump is a URL, not AppleScript.

## Hooks from a plugin instead

The widget learns what a session is doing from Claude Code hooks. `notchling-hooks setup` writes them
into `~/.claude/settings.json`, appending to the existing arrays so other tools' hooks survive, and
backing the file up first.

If you would rather nothing edited that file, a Claude Code plugin can provide the same hooks. Inside
Claude Code:

```
/plugin marketplace add CircleHP/notchling
/plugin install notchling@circlehp
```

Use one route or the other, never both: plugin hooks merge with the ones in `settings.json`, so two
copies report every event twice. Re-running `notchling-hooks setup` notices that and offers to undo it.

The plan-usage status line stays with `notchling-hooks` either way — plugins cannot register one.

## What gets installed

| | |
|---|---|
| `$(brew --prefix)/opt/notchling/Notchling.app` | the app; version-independent path, safe to reference |
| `$(brew --prefix)/bin/notchling-hook` | the hook helper, on `PATH`; this is what the hooks record |
| `$(brew --prefix)/bin/notchling-hooks` | wiring and setup: `setup`, `install`, `uninstall`, `statusline` |

Both `bin` entries keep pointing at the current version, which is why `brew upgrade` does not break
hooks already recorded in `settings.json`.

## Running it

```sh
brew services start notchling     # now, and at login
brew services stop notchling
```

The app has no Dock icon and no window — it is `LSUIElement`, and lives in the notch. On a Mac without
one it draws its own.

## Upgrading and uninstalling

```sh
brew upgrade notchling
```

To remove it, unwire the hooks first, while the command still exists:

```sh
notchling-hooks uninstall
brew services stop notchling
brew uninstall notchling
brew untap CircleHP/notchling
```

Session state lives in `~/.notchling`, and is not removed by Homebrew.

## Building from source instead

For contributors, and for anyone who would rather not run a binary they did not compile:

```sh
brew install --HEAD CircleHP/notchling/notchling
```

That path needs a Swift 6 toolchain — Xcode 16 or later, or its Command Line Tools.

## What is in this repository

- `Formula/notchling.rb` — the formula
- `.github/workflows/bottle.yml` — builds a bottle for a released version, publishes it, records it in
  the formula, and proves a fresh install pours rather than builds
- `.github/workflows/tests.yml` — `brew test-bot`, which checks the tap's syntax and style
- Releases tagged `bottle-<version>` — the bottles themselves

## Requirements

macOS 14 Sonoma or later, on Apple silicon or Intel. `jq` is installed as a dependency.

## License

The formula, like the app, is MIT. See [CircleHP/notchling](https://github.com/CircleHP/notchling).
