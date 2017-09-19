# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("..", __FILE__))

require "gem_tester/sandbox"

GemTester::Sandbox.new.run do |config|
  config.with_env do
    system(ARGV.join(" "))
  end
end
