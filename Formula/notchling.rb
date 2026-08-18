class Notchling < Formula
  desc "Notch widget showing live status for every Claude Code session"
  homepage "https://github.com/CircleHP/notchling"
  url "https://github.com/CircleHP/notchling/releases/download/v1.0.0/notchling-1.0.0-universal.tar.gz"
  sha256 "2a68ad014cb96ba36cf05b2bedf8b1d7660179cd887a113e858f2b75c1aa1123"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
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
      prefix.install "Notchling.app"
    end

    # Both symlinks are version-independent, which is what hooks and the status line must record:
    # a path into the Cellar goes stale on the next upgrade and every hook silently stops firing.
    bin.install_symlink prefix/"Notchling.app/Contents/MacOS/notchling-hook"
    bin.install_symlink prefix/"Notchling.app/Contents/Resources/install-hooks.sh" => "notchling-hooks"
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
      Wire the Claude Code hooks. Preferred, and it edits nothing — inside Claude Code:

        /plugin marketplace add CircleHP/notchling
        /plugin install notchling@circlehp

      Or without the plugin, which writes to ~/.claude/settings.json (backed up first, and appended
      to rather than replaced, so other tools' hooks survive):

        notchling-hooks install

      Use one or the other, never both: plugin hooks merge with the ones in settings.json, so two
      copies mean every event is reported twice.

      Restart any Claude sessions that were already running — hooks are read at session start.

      Start it now, and at login:

        brew services start notchling

      Optional, for the plan-usage bars. Not available through the plugin, and it makes Claude Code
      drop some of its footer hints:

        notchling-hooks statusline
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
