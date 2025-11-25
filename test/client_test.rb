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

  def test_click_simulates_mouse_click_at_position
    @client.click(100, 200)
    @client.wait_until("$args.state.last_click")

    # Verify click was registered in game state
    x = @client.eval_ruby("$args.state.last_click.x")
    y = @client.eval_ruby("$args.state.last_click.y")

    assert_equal 100, x
    assert_equal 200, y
  end

  def test_wait_until_raises_on_timeout
    error = assert_raises(Enthrall::TimeoutError) do
      @client.wait_until("false", timeout: 0.5)
    end

    assert_match(/timed out/i, error.message)
  end
end
