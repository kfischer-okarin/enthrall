# frozen_string_literal: true

require "test_helper"

class TestEnthrall < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Enthrall::VERSION
  end

  def test_start_and_stop_dragonruby_process
    binary = DragonRubyBinary.new
    game_process = binary.start_game("test/fixtures/simple_game")

    assert_instance_of GameProcess, game_process
    sleep 0.5 # Give it a moment to start

    # Check that we can read logs
    refute_nil game_process.stdout_log
    refute_nil game_process.stderr_log

    game_process.kill
  end
end
