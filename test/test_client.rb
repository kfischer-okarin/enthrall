# frozen_string_literal: true

require "test_helper"

class TestClient < Minitest::Test
  def setup
    binary = DragonRubyBinary.new
    @game_process = binary.start_game_fixture("simple_game")
    @client = Enthrall::Client.new
  end

  def teardown
    @game_process.kill
  end

  def test_eval_ruby_returns_simple_expression_result
    result = @client.eval_ruby("1 + 1")

    assert_equal 2, result
  end

  def test_eval_ruby_can_read_game_state
    result = @client.eval_ruby("$args.state.tick_count")

    assert_kind_of Integer, result
    assert result >= 0
  end
end
