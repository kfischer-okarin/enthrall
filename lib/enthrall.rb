# frozen_string_literal: true

require_relative "enthrall/client"
require_relative "enthrall/injected_code"
require_relative "enthrall/version"

module Enthrall
  class Error < StandardError; end
  class TimeoutError < Error; end
end
