require "json"

class Ccbeacon < Formula
  desc "macOS menu bar monitor for Claude Code sessions"
  homepage "https://github.com/hosseintoussi/ccbeacon"
  url "https://github.com/hosseintoussi/ccbeacon/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "9ce7b7bb766edd87e867b45bc852e9d0e8f07cab21f8e4666769a76b956d8c92"
  license "MIT"

  depends_on :macos => :ventura

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/ccbeacon"
    libexec.install "ccbeacon.sh"
  end

  def post_install
    home       = Pathname.new(ENV["HOME"])
    hooks_dir  = home/".claude/hooks"
    hooks_dir.mkpath

    # Install/update the hook script
    hook_dst = hooks_dir/"ccbeacon.sh"
    FileUtils.cp libexec/"ccbeacon.sh", hook_dst
    hook_dst.chmod(0755)

    # Merge hooks into ~/.claude/settings.json without touching anything else
    settings_path = home/".claude/settings.json"
    settings = settings_path.exist? ? JSON.parse(settings_path.read) : {}
    settings["hooks"] ||= {}

    {
      "UserPromptSubmit" => "working",
      "Notification"     => "waiting",
      "Stop"             => "done",
    }.each do |event, state|
      settings["hooks"][event] ||= []
      cmd   = "#{hooks_dir}/ccbeacon.sh #{state}"
      entry = { "hooks" => [{ "type" => "command", "command" => cmd }] }
      # Idempotent — skip if a ccbeacon entry already exists for this event
      next if settings["hooks"][event].any? { |h| h.to_s.include?("ccbeacon") }
      settings["hooks"][event] << entry
    end

    settings_path.write(JSON.pretty_generate(settings))
  end

  def caveats
    <<~EOS
      Hook script installed and Claude Code hooks configured automatically.

      Launch ccbeacon:
        ccbeacon &

      To start at login: System Settings → General → Login Items → add ccbeacon.
    EOS
  end

  test do
    assert_predicate bin/"ccbeacon", :executable?
  end
end
