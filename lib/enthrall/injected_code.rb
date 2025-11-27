# frozen_string_literal: true

module Enthrall
  module InjectedCode
    def self.tadpole_code
      <<~'RUBY'
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

            MOUSE_BUTTONS = {left: 1, middle: 2, right: 3}.freeze

            def initialize
              @input_queue = {}
            end

            def click(x, y, button:, delay: 0)
              current_tick = $gtk.args.state.tick_count
              button_id = MOUSE_BUTTONS[button]
              # Flip y coordinate: DragonRuby has y=0 at bottom, SDL has y=0 at top
              screen_y = 720 - y
              log_received_command "click(#{x}, #{y}, button: #{button}, delay: #{delay})"
              # Mouse down next tick (plus delay)
              schedule_callback_in(delay + 1) do
                log_injected_input  "mouse_move(#{x}, #{screen_y})"
                $gtk.send :mouse_move, x, screen_y
                log_injected_input "mouse_button_pressed(#{button_id})"
                $gtk.send :mouse_button_pressed, button_id
              end
              # Mouse up 6 ticks later
              schedule_callback_in(delay + 7) do
                log_injected_input "mouse_button_up(#{button_id})"
                $gtk.send :mouse_button_up, button_id
              end
              {tick: current_tick}
            end

            def press_key(key, modifiers, delay: 0)
              current_tick = $gtk.args.state.tick_count
              keycode = KEYCODES[key]
              scancode = SCANCODES[key]
              flags = modifiers.map { |m| MODIFIER_FLAGS[m] || 0 }.reduce(0, :|)

              log_injected_input "press_key(#{key}, modifiers: #{modifiers}, delay: #{delay})"

              # Key down at tick+1 (with modifiers pressed first)
              schedule_callback_in(delay + 1) do
                # Press modifier keys first
                modifiers.each do |mod|
                  mod_keycode = KEYCODES[mod]
                  mod_scancode = SCANCODES[mod]
                  log_injected_input "key_down_raw(#{mod_keycode}, 0)"
                  $gtk.send :key_down_raw, mod_keycode, 0 if mod_keycode
                  log_injected_input "scancode_down_raw(#{mod_scancode}, 0)"
                  $gtk.send :scancode_down_raw, mod_scancode, 0 if mod_scancode
                end

                # Then press main key with modifier flags
                log_injected_input "key_down_raw(#{keycode}, #{flags})"
                $gtk.send :key_down_raw, keycode, flags if keycode
                log_injected_input "scancode_down_raw(#{scancode}, #{flags})"
                $gtk.send :scancode_down_raw, scancode, flags if scancode
              end

              # Key up at tick+7 (release main key then modifiers)
              schedule_callback_in(delay + 7) do
                log_injected_input "key_up_raw(#{keycode}, #{flags})"
                $gtk.send :key_up_raw, keycode, flags if keycode
                log_injected_input "scancode_up_raw(#{scancode}, #{flags})"
                $gtk.send :scancode_up_raw, scancode, flags if scancode
                # Release modifiers
                modifiers.each do |mod|
                  mod_keycode = KEYCODES[mod]
                  mod_scancode = SCANCODES[mod]
                  log_injected_input "key_up_raw(#{mod_keycode}, 0)"
                  $gtk.send :key_up_raw, mod_keycode, 0 if mod_keycode
                  log_injected_input "scancode_up_raw(#{mod_scancode}, 0)"
                  $gtk.send :scancode_up_raw, mod_scancode, 0 if mod_scancode
                end
              end
              {tick: current_tick}
            end

            def process_tick
              current_tick = $gtk.args.state.tick_count
              if @input_queue[current_tick]
                @input_queue[current_tick].each(&:call)
                @input_queue.delete(current_tick)
              end
            end

            private

            def schedule_callback_in(ticks, &block)
              target_tick = $gtk.args.state.tick_count + ticks
              @input_queue[target_tick] ||= []
              @input_queue[target_tick] << block
            end

            def log_received_command(message)
              puts "A tremor ripples through the tadpole's nerves: #{message} (#{Kernel.global_tick_count})"
            end

            def log_injected_input(message)
              puts "The tadpole flexes its will over the host: #{message} (#{Kernel.global_tick_count})"
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
    end
  end
end
