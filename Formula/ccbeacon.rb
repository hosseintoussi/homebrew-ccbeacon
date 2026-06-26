require "json"

class Ccbeacon < Formula
  desc "macOS menu bar monitor for Claude Code sessions"
  homepage "https://github.com/hosseintoussi/ccbeacon"
  url "https://github.com/hosseintoussi/ccbeacon/archive/refs/tags/v2.0.2.tar.gz"
  sha256 "23d4aca2988bbf3de53bab4305b233b124871b69ade0c487a49ee10e651216a8"
  license "MIT"

  depends_on :macos => :ventura

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/ccbeacon"
    libexec.install "ccbeacon.sh"
  end

  def post_install
    home      = Pathname.new(ENV["HOME"])
    hooks_dir = home/".claude/hooks"
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
      next if settings["hooks"][event].any? { |h| h.to_s.include?("ccbeacon") }
      settings["hooks"][event] << entry
    end

    settings_path.write(JSON.pretty_generate(settings))

    # Install LaunchAgent so ccbeacon starts at login automatically
    launch_agents = home/"Library/LaunchAgents"
    launch_agents.mkpath
    plist = launch_agents/"com.hosseintoussi.ccbeacon.plist"
    plist.write <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>com.hosseintoussi.ccbeacon</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{bin}/ccbeacon</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <false/>
      </dict>
      </plist>
    XML

    # Reload if already running (handles upgrades), otherwise start fresh
    quiet_system "launchctl", "bootout", "gui/#{Process.uid}/com.hosseintoussi.ccbeacon"
    system "launchctl", "bootstrap", "gui/#{Process.uid}", plist.to_s
  end

  def caveats
    <<~EOS
      ccbeacon is running and will start automatically at login.
    EOS
  end

  test do
    assert_predicate bin/"ccbeacon", :executable?
  end
end
