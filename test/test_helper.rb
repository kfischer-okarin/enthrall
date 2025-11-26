# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "enthrall"

require "minitest/autorun"

# Test support
require_relative "support/dragonruby_binary"
require_relative "support/game_process"

# Ensure DragonRuby binary is available before running tests
DragonRubyBinary.new.ensure_exists!

class EnthrallTestCase < Minitest::Test
  private

  def with_fixture(fixture_name)
    binary = DragonRubyBinary.new
    game_process = binary.start_game_fixture(fixture_name, log_file_name: log_file_name)
    client = Enthrall::Client.new
    yield client
  ensure
    game_process.kill
  end

  def log_file_name
    "#{self.class.name}_#{name}".gsub(/[^a-zA-Z0-9_-]/, "_")
  end
end
