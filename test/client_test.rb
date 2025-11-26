# frozen_string_literal: true

require "test_helper"

class TestClient < EnthrallTestCase
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

  def test_press_key_simple
    with_fixture("keyboard_test") do |client|
      client.press_key(:a)
      client.wait_until("$args.state.detected_key_events.length >= 2")

      events = client.eval_ruby("$args.state.detected_key_events.to_a")

      assert_equal [:a_down, :a_up], events
    end
  end

  def test_press_key_with_string
    with_fixture("keyboard_test") do |client|
      client.press_key("space")
      client.wait_until("$args.state.detected_key_events.length >= 2")

      events = client.eval_ruby("$args.state.detected_key_events.to_a")

      assert_equal [:space_down, :space_up], events
    end
  end

  def test_press_key_with_modifier
    with_fixture("keyboard_test") do |client|
      client.press_key(:shift, :a)
      client.wait_until("$args.state.detected_key_events.length >= 4")

      events = client.eval_ruby("$args.state.detected_key_events.to_a")

      # Detection order depends on fixture's check order (keys before modifiers)
      assert_equal [:a_down, :shift_down, :a_up, :shift_up], events
    end
  end

  def test_press_key_f_key
    with_fixture("keyboard_test") do |client|
      client.press_key(:f1)
      client.wait_until("$args.state.detected_key_events.length >= 2")

      events = client.eval_ruby("$args.state.detected_key_events.to_a")

      assert_equal [:f1_down, :f1_up], events
    end
  end

  def test_click_returns_tick
    with_fixture("mouse_test") do |client|
      result = client.click(100, 200)

      assert result[:tick] >= 0
    end
  end

  def test_click_with_delay
    with_fixture("mouse_test") do |client|
      click_result = client.click(100, 200, button: :left, delay: 10)
      client.wait_until("$args.state.timed_mouse_events.length >= 2")

      events = client.eval_ruby("$args.state.timed_mouse_events")
      left_click = events.find { |e| e[:event] == :left_click }

      # Event fires at: returned_tick + delay + 2 (schedule offset + detection delay)
      assert_equal click_result[:tick] + 10 + 2, left_click[:tick]
    end
  end

  def test_press_key_returns_tick
    with_fixture("keyboard_test") do |client|
      result = client.press_key(:a)

      assert result[:tick] >= 0
    end
  end

  def test_press_key_with_delay
    with_fixture("keyboard_test") do |client|
      press_result = client.press_key(:a, delay: 10)
      client.wait_until("$args.state.timed_key_events.length >= 2")

      events = client.eval_ruby("$args.state.timed_key_events")
      a_down = events.find { |e| e[:event] == :a_down }

      # Event fires at: returned_tick + delay + 2 (schedule offset + detection delay)
      assert_equal press_result[:tick] + 10 + 2, a_down[:tick]
    end
  end
end
