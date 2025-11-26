# frozen_string_literal: true

require "json"
require "net/http"

module Enthrall
  class Client
    MOUSE_BUTTONS = {left: 1, middle: 2, right: 3}.freeze
    MODIFIERS = [:shift, :control, :alt, :meta].freeze

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

    def click(x, y, button: :left, delay: 0)
      button_id = MOUSE_BUTTONS[button]
      raise ArgumentError, "Invalid button: #{button.inspect}. Use :left, :middle, or :right" unless button_id

      inject_tadpole
      eval_ruby("$gtk.tadpole.click(#{x}, #{y}, button: #{button_id}, delay: #{delay})")
    end

    def press_key(*modifiers_and_key, delay: 0)
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
      eval_ruby("$gtk.tadpole.press_key(:#{key}, #{modifiers.inspect}, delay: #{delay})")
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

      eval_ruby(InjectedCode.tadpole_code)
      @injected = true
    end
  end
end
