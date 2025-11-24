require "fileutils"
require "json"
require "net/http"
require "uri"

require "zip"

class DragonRubyBinary
  BINARY_REPOSITORY = "kfischer-okarin/dragonruby-for-ci"

  def initialize(ruby_platform: RUBY_PLATFORM)
    @ruby_platform = ruby_platform
  end

  def path
    executable = platform.include?("windows") ? "dragonruby.exe" : "dragonruby"
    File.join(Dir.pwd, "tmp", "dragonruby", executable)
  end

  def ensure_exists!(version: nil, license: "standard")
    return if File.exist?(path)

    version ||= fetch_latest_version
    download_and_extract(version: version, license: license)
  end

  private

  def fetch_latest_version
    response = http_get("https://api.github.com/repos/#{BINARY_REPOSITORY}/releases/latest")

    data = JSON.parse(response.body)
    data["tag_name"]
  end

  def download_and_extract(version:, license:)
    url = download_url(version: version, license: license)
    uri = URI(url)

    puts "Downloading DragonRuby #{version} for #{platform}..."
    response = http_get(uri)

    temp_zip = File.join(Dir.pwd, "tmp", "dragonruby.zip")
    FileUtils.mkdir_p(File.dirname(temp_zip))
    File.binwrite(temp_zip, response.body)

    extract_binary(temp_zip)

    FileUtils.rm_f(temp_zip)

    puts "DragonRuby binary ready at #{path}"
  end

  def download_url(version:, license: "standard")
    "https://github.com/#{BINARY_REPOSITORY}/releases/download/#{version}/dragonruby-for-ci-#{version}-#{license}-#{platform}.zip"
  end

  def platform
    case @ruby_platform
    when /darwin/
      "macos"
    when /linux/
      "linux-amd64"
    when /mingw|mswin/
      "windows-amd64"
    else
      raise "Unsupported platform: #{@ruby_platform}"
    end
  end

  def extract_binary(zip_path)
    target_dir = File.dirname(path)
    FileUtils.mkdir_p(target_dir)

    Zip::File.open(zip_path) do |zip_file|
      zip_file.each do |entry|
        # Only extract dragonruby executable and font.ttf
        next unless entry.name.end_with?("dragonruby", "dragonruby.exe", "font.ttf")

        target_path = File.join(target_dir, File.basename(entry.name))
        # Extract by reading and writing directly to avoid path issues
        File.binwrite(target_path, entry.get_input_stream.read)
      end
    end

    # Make executable on Unix
    FileUtils.chmod(0o755, path) unless platform.include?("windows")
  end

  def http_get(url)
    uri = URI(url)
    response = Net::HTTP.get_response(uri)

    case response
    when Net::HTTPRedirection
      http_get(response["location"])
    when Net::HTTPSuccess
      response
    else
      raise "Failed to get #{url}: #{response.code} #{response.message}\n#{response.body}"
    end
  end
end
