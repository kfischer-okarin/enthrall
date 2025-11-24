# frozen_string_literal: true

require "json"
require "net/http"

module Enthrall
  class Client
    def initialize(host: "localhost", port: 9001)
      @host = host
      @port = port
    end

    def eval_ruby(code)
      uri = URI("http://#{@host}:#{@port}/dragon/eval/")
      response = Net::HTTP.post(uri, {code: code}.to_json, "Content-Type" => "application/json")

      raise "Failed to eval: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      eval(response.body) rescue response.body
    end
  end
end
