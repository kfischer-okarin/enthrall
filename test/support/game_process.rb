require "fileutils"
require "net/http"
require "timeout"

class GameProcess
  def initialize(binary_path:, game_dir:)
    @binary_path = binary_path
    @game_dir = game_dir
    @mygame_path = File.join(File.dirname(@binary_path), "mygame")
    @pid = nil
    setup_game_folder
    setup_log_files
    start
  end

  def kill
    return unless @pid

    signal = windows? ? "KILL" : "TERM"
    Process.kill(signal, @pid)
    Process.wait(@pid)
  rescue Errno::ESRCH, Errno::ECHILD, Errno::EINVAL
    # Process already dead or invalid on Windows
  ensure
    @pid = nil
  end

  def stdout
    File.read(@stdout_log) if File.exist?(@stdout_log)
  end

  def stderr
    File.read(@stderr_log) if File.exist?(@stderr_log)
  end

  private

  def setup_game_folder
    # Delete existing mygame folder if it exists
    FileUtils.rm_rf(@mygame_path) if File.exist?(@mygame_path)

    # Copy game folder to mygame
    FileUtils.cp_r(@game_dir, @mygame_path)
  end

  def setup_log_files
    log_dir = File.join(Dir.pwd, "tmp", "logs")
    FileUtils.mkdir_p(log_dir)

    timestamp = Time.now.strftime("%Y%m%d_%H%M%S_%L")
    @stdout_log = File.join(log_dir, "dragonruby_#{timestamp}.out")
    @stderr_log = File.join(log_dir, "dragonruby_#{timestamp}.err")
  end

  def start
    # Ensure to run headless on CI
    env = ci_environment? ? {"SDL_VIDEODRIVER" => "dummy", "SDL_AUDIODRIVER" => "dummy"} : {}

    # Run from the DragonRuby directory so it finds mygame
    Dir.chdir(File.dirname(@binary_path)) do
      command = [@binary_path, 'mygame', '--set', 'webserver.enabled', 'true']
      @pid = Process.spawn(env, *command, out: @stdout_log, err: @stderr_log)
    end

    wait_for_endpoint
  end

  def wait_for_endpoint(host: "localhost", port: 9001, timeout: 10)
    Timeout.timeout(timeout) do
      loop do
        Net::HTTP.get_response(URI("http://#{host}:#{port}/dragon/eval/"))
        break
      rescue Errno::ECONNREFUSED, Errno::EADDRNOTAVAIL, SocketError
        sleep 0.1
      end
    end
  rescue Timeout::Error
    raise "DragonRuby eval endpoint did not become available within #{timeout} seconds"
  end

  def ci_environment?
    ENV["CI"] == "true"
  end

  def windows?
    RUBY_PLATFORM.match?(/mingw|mswin/)
  end
end
