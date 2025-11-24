# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "enthrall"

require "minitest/autorun"

# Test support
require_relative "support/dragonruby_binary"

# Ensure DragonRuby binary is available before running tests
DragonRubyBinary.new.ensure_exists!
