class Notchling < Formula
  desc "Notch widget showing live status for every Claude Code session"
  homepage "https://github.com/CircleHP/notchling"
  url "https://github.com/CircleHP/notchling/releases/download/v1.1.1/notchling-1.1.1-universal.tar.gz"
  sha256 "f25740ea6a2155fa526cf79971dd175cd50b4b61a4243eed80eef7b9abcb5958"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/CircleHP/homebrew-notchling/releases/download/bottle-1.1.1"
    sha256 cellar: :any_skip_relocation, all: "5b4a43dfc96d99e7777cc2dd1e7d8dbb3342985ca1193075a2f8c3e025b9a3a9"
  end

  # Builds on the user's machine instead, for contributors and for anyone who would rather not run a
  # binary they did not compile. Only this path needs a toolchain, which is why the dependency is here.
  head do
    url "https://github.com/CircleHP/notchling.git", branch: "main"
    depends_on xcode: ["16.0", :build]
  end

  # Used by the hook installer and the status line script, not by the app itself.
  depends_on "jq"
  # Package.swift declares platforms: [.macOS(.v14)].
  depends_on macos: :sonoma

  def install
    if build.head?
      # `make bundle`, never `make install`: the latter writes to $HOME/Applications and edits
      # ~/.claude/settings.json, neither of which a package manager may touch. SIGN_ID= forces ad-hoc
      # signing, because reading a login keychain either fails in the build sandbox or prompts for
      # authorization in the middle of an install.
      system "make", "bundle", "SIGN_ID="
      prefix.install ".build/bundle/Notchling.app"
    else
      # Homebrew strips the single top-level directory as it unpacks, so what this is standing in is
      # the bundle itself rather than its parent. Rebuild the wrapper rather than reshaping the
      # archive, which would invalidate every checksum already published.
      (prefix/"Notchling.app").install Dir["*"]
    end

    # Both symlinks are version-independent, which is what hooks and the status line must record:
    # a path into the Cellar goes stale on the next upgrade and every hook silently stops firing.
    bin.install_symlink prefix/"Notchling.app/Contents/MacOS/notchling-hook"
    bin.install_symlink prefix/"Notchling.app/Contents/Resources/install-hooks.sh" => "notchling-hooks"
    bin.install_symlink prefix/"Notchling.app/Contents/Resources/list-sessions.sh" => "notchling-sessions"
  end

  # This app draws windows, so it has to run in the logged-in GUI session rather than as a daemon.
  # `brew services start notchling` writes a user LaunchAgent, which is exactly that.
  service do
    run [opt_prefix/"Notchling.app/Contents/MacOS/Notchling"]
    keep_alive true
    process_type :interactive
  end

  def caveats
    <<~EOS
      One command finishes the setup, asking before it changes anything:

        notchling-hooks setup

      It wires the Claude Code hooks, offers the plan-usage status line, and starts the widget
      now and at login — so the `brew services` command below is already covered. Then restart
      any Claude sessions that were already running — hooks are read at session start.

      To have the hooks come from a plugin instead, so nothing edits ~/.claude/settings.json,
      run this inside Claude Code rather than the command above:

        /plugin marketplace add CircleHP/notchling
        /plugin install notchling@circlehp
    EOS
  end

  test do
    # The hook helper must never write to stdout and never exit non-zero: Claude Code acts on hook
    # stdout, and a broken widget must not be able to break a session.
    output = pipe_output("#{bin}/notchling-hook",
                         '{"hook_event_name":"Stop","session_id":"brew-test"}', 0)
    assert_empty output

    assert_path_exists prefix/"Notchling.app/Contents/MacOS/Notchling"
  end
end
