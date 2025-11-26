# frozen_string_literal: true

require "json"
require "net/http"

module Enthrall
  TADPOLE_CODE = <<~'RUBY'
    module Enthrall
      class Tadpole
        KEYCODES = {
          # Letters (lowercase ASCII)
          a: 97, b: 98, c: 99, d: 100, e: 101, f: 102, g: 103, h: 104,
          i: 105, j: 106, k: 107, l: 108, m: 109, n: 110, o: 111, p: 112,
          q: 113, r: 114, s: 115, t: 116, u: 117, v: 118, w: 119, x: 120,
          y: 121, z: 122,
          # Numbers (use symbol names to avoid starting with digit)
          zero: 48, one: 49, two: 50, three: 51, four: 52,
          five: 53, six: 54, seven: 55, eight: 56, nine: 57,
          # Common keys
          space: 32, enter: 13, tab: 9, backspace: 8, escape: 27, delete: 127,
          # F keys (SDL extended, base 0x40000000)
          f1: 1073741882, f2: 1073741883, f3: 1073741884, f4: 1073741885,
          f5: 1073741886, f6: 1073741887, f7: 1073741888, f8: 1073741889,
          f9: 1073741890, f10: 1073741891, f11: 1073741892, f12: 1073741893,
          # Arrows
          left: 1073741904, right: 1073741903, up: 1073741906, down: 1073741905,
          # Modifiers (as keys themselves)
          shift: 1073742049, control: 1073742048, alt: 1073742050, meta: 1073742051,
        }.freeze

        SCANCODES = {
          # Letters
          a: 4, b: 5, c: 6, d: 7, e: 8, f: 9, g: 10, h: 11,
          i: 12, j: 13, k: 14, l: 15, m: 16, n: 17, o: 18, p: 19,
          q: 20, r: 21, s: 22, t: 23, u: 24, v: 25, w: 26, x: 27,
          y: 28, z: 29,
          # Numbers
          one: 30, two: 31, three: 32, four: 33, five: 34,
          six: 35, seven: 36, eight: 37, nine: 38, zero: 39,
          # Common keys
          enter: 40, escape: 41, backspace: 42, tab: 43, space: 44,
          # F keys
          f1: 58, f2: 59, f3: 60, f4: 61, f5: 62, f6: 63,
          f7: 64, f8: 65, f9: 66, f10: 67, f11: 68, f12: 69,
          # Arrows
          right: 79, left: 80, down: 81, up: 82,
          # Modifiers
          control: 224, shift: 225, alt: 226, meta: 227,
        }.freeze

        MODIFIER_FLAGS = {
          shift: 1, control: 64, alt: 256, meta: 1024,
        }.freeze

        def initialize
          @input_queue = {}
        end

        def click(x, y, button:)
          current_tick = $gtk.args.state.tick_count
          # Flip y coordinate: DragonRuby has y=0 at bottom, SDL has y=0 at top
          screen_y = 720 - y
          puts "[Tadpole] click(#{x}, #{y}) -> screen(#{x}, #{screen_y}) scheduled at tick #{current_tick}"
          # Mouse down next tick
          schedule_input(current_tick + 1) do
            puts "[Tadpole] mouse_move(#{x}, #{screen_y}) + mouse_button_pressed(#{button})"
            $gtk.send :mouse_move, x, screen_y
            $gtk.send :mouse_button_pressed, button
          end
          # Mouse up 6 ticks later
          schedule_input(current_tick + 7) do
            puts "[Tadpole] mouse_button_up(#{button})"
            $gtk.send :mouse_button_up, button
          end
        end

        def press_key(key, modifiers)
          current_tick = $gtk.args.state.tick_count
          keycode = KEYCODES[key]
          scancode = SCANCODES[key]
          flags = modifiers.map { |m| MODIFIER_FLAGS[m] || 0 }.reduce(0, :|)

          puts "[Tadpole] press_key(#{key}, modifiers: #{modifiers}) scheduled at tick #{current_tick}"

          # Key down at tick+1 (with modifiers pressed first)
          schedule_input(current_tick + 1) do
            # Press modifier keys first
            modifiers.each do |mod|
              mod_keycode = KEYCODES[mod]
              mod_scancode = SCANCODES[mod]
              $gtk.send :key_down_raw, mod_keycode, 0 if mod_keycode
              $gtk.send :scancode_down_raw, mod_scancode, 0 if mod_scancode
            end
            # Then press main key with modifier flags
            $gtk.send :key_down_raw, keycode, flags if keycode
            $gtk.send :scancode_down_raw, scancode, flags if scancode
          end

          # Key up at tick+7 (release main key then modifiers)
          schedule_input(current_tick + 7) do
            $gtk.send :key_up_raw, keycode, flags if keycode
            $gtk.send :scancode_up_raw, scancode, flags if scancode
            # Release modifiers
            modifiers.each do |mod|
              mod_keycode = KEYCODES[mod]
              mod_scancode = SCANCODES[mod]
              $gtk.send :key_up_raw, mod_keycode, 0 if mod_keycode
              $gtk.send :scancode_up_raw, mod_scancode, 0 if mod_scancode
            end
          end
        end

        def process_tick
          current_tick = $gtk.args.state.tick_count
          if @input_queue[current_tick]
            puts "[Tadpole] process_tick #{current_tick}, #{@input_queue[current_tick].size} actions"
            @input_queue[current_tick].each(&:call)
            @input_queue.delete(current_tick)
          end
        end

        private

        def schedule_input(tick, &block)
          @input_queue[tick] ||= []
          @input_queue[tick] << block
        end
      end
    end

    module TadpoleInjection
      def tick_gtk_engine_before
        $gtk.tadpole.process_tick
        super
      end
    end

    class GTK::Runtime
      def tadpole
        @tadpole ||= Enthrall::Tadpole.new
      end
    end

    GTK::Runtime.prepend(TadpoleInjection)
  RUBY

  class Client
    def initialize(host: "localhost", port: 9001)
      @host = host
      @port = port
      @injected = false
    end

    def eval_ruby(code)
      uri = URI("http://#{@host}:#{@port}/dragon/eval/")
      response = Net::HTTP.post(uri, {code: code}.to_json, "Content-Type" => "application/json")

      raise "Failed to eval: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      return nil if response.body.nil? || response.body.empty?

      begin
        eval(response.body)
      rescue SyntaxError, NameError
        response.body
      end
    end

    MOUSE_BUTTONS = {left: 1, middle: 2, right: 3}.freeze
    MODIFIERS = [:shift, :control, :alt, :meta].freeze

    def click(x, y, button: :left)
      button_id = MOUSE_BUTTONS[button]
      raise ArgumentError, "Invalid button: #{button.inspect}. Use :left, :middle, or :right" unless button_id

      inject_tadpole
      eval_ruby("$gtk.tadpole.click(#{x}, #{y}, button: #{button_id})")
    end

    def press_key(*modifiers_and_key)
      raise ArgumentError, "press_key requires at least one argument (key)" if modifiers_and_key.empty?

      # Normalize all arguments to symbols (accept both 'a' and :a)
      args = modifiers_and_key.map { |arg| arg.to_s.to_sym }

      # Last argument is the key, rest are modifiers
      key = args.last
      modifiers = args[0...-1]

      # Validate modifiers
      invalid_mods = modifiers - MODIFIERS
      unless invalid_mods.empty?
        raise ArgumentError, "Invalid modifiers: #{invalid_mods.inspect}. Use: #{MODIFIERS.inspect}"
      end

      inject_tadpole
      eval_ruby("$gtk.tadpole.press_key(:#{key}, #{modifiers.inspect})")
    end

    def wait_until(expression, timeout: 10, interval: 0.1)
      start_time = Time.now
      loop do
        result = eval_ruby(expression)
        return result if result

        elapsed = Time.now - start_time
        raise Enthrall::TimeoutError, "Timed out after #{timeout}s waiting for: #{expression}" if elapsed >= timeout

        sleep interval
      end
    end

    private

    def inject_tadpole
      return if @injected

      eval_ruby(TADPOLE_CODE)
      @injected = true
    end
  end
end
