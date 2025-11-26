# frozen_string_literal: true

require "test_helper"

class TestClient < Minitest::Test
  def test_eval_ruby_returns_simple_expression_result
    with_fixture("simple_game") do |client|
      result = client.eval_ruby("1 + 1")

      assert_equal 2, result
    end
  end

  def test_eval_ruby_can_read_game_state
    with_fixture("simple_game") do |client|
      result = client.eval_ruby("$args.state.tick_count")

      assert_kind_of Integer, result
      assert result >= 0
    end
  end

  def test_click_left_button
    with_fixture("mouse_test") do |client|
      client.click(100, 200, button: :left)
      client.wait_until("$args.state.detected_mouse_events.length >= 2")

      events = client.eval_ruby("$args.state.detected_mouse_events.to_a")

      assert_equal [:left_click, :left_up], events
    end
  end

  def test_click_middle_button
    with_fixture("mouse_test") do |client|
      client.click(100, 200, button: :middle)
      client.wait_until("$args.state.detected_mouse_events.length >= 2")

      events = client.eval_ruby("$args.state.detected_mouse_events.to_a")

      assert_equal [:middle_click, :middle_up], events
    end
  end

  def test_click_right_button
    with_fixture("mouse_test") do |client|
      client.click(100, 200, button: :right)
      client.wait_until("$args.state.detected_mouse_events.length >= 2")

      events = client.eval_ruby("$args.state.detected_mouse_events.to_a")

      assert_equal [:right_click, :right_up], events
    end
  end

  def test_wait_until_raises_on_timeout
    with_fixture("simple_game") do |client|
      error = assert_raises(Enthrall::TimeoutError) do
        client.wait_until("false", timeout: 0.5)
      end

      assert_match(/timed out/i, error.message)
    end
  end

  private

  def with_fixture(fixture_name)
    binary = DragonRubyBinary.new
    game_process = binary.start_game_fixture(fixture_name)
    client = Enthrall::Client.new
    yield client
  ensure
    game_process.kill
  end
end
