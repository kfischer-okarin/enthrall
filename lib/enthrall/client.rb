# frozen_string_literal: true

require "json"
require "net/http"

module Enthrall
  TADPOLE_CODE = <<~'RUBY'
    module Enthrall
      class Tadpole
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

    def click(x, y, button: :left)
      button_id = MOUSE_BUTTONS[button]
      raise ArgumentError, "Invalid button: #{button.inspect}. Use :left, :middle, or :right" unless button_id

      inject_tadpole
      eval_ruby("$gtk.tadpole.click(#{x}, #{y}, button: #{button_id})")
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
