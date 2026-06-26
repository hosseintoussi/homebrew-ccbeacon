class Ccbeacon < Formula
  desc "macOS menu bar monitor for Claude Code sessions"
  homepage "https://github.com/hosseintoussi/ccbeacon"
  url "https://github.com/hosseintoussi/ccbeacon/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "d720d8906917fd3989b19ee4d89ec1e34463cf4856955b13c44840b34e3c855a"
  license "MIT"

  depends_on :macos => :ventura

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/ccbeacon"
    libexec.install "ccbeacon.sh"
  end

  def caveats
    <<~EOS
      To finish setup, install the Claude Code hook script and configure hooks:

      1. Copy the hook script:
           mkdir -p ~/.claude/hooks
           cp #{libexec}/ccbeacon.sh ~/.claude/hooks/
           chmod +x ~/.claude/hooks/ccbeacon.sh

      2. Add to ~/.claude/settings.json:
           {
             "hooks": {
               "UserPromptSubmit": [{ "hooks": [{ "type": "command", "command": "~/.claude/hooks/ccbeacon.sh working" }] }],
               "Notification":     [{ "hooks": [{ "type": "command", "command": "~/.claude/hooks/ccbeacon.sh waiting" }] }],
               "Stop":             [{ "hooks": [{ "type": "command", "command": "~/.claude/hooks/ccbeacon.sh done"    }] }]
             }
           }

      3. Launch:
           ccbeacon &

      To start at login: System Settings → General → Login Items → add ccbeacon.
    EOS
  end

  test do
    assert_predicate bin/"ccbeacon", :executable?
  end
end
