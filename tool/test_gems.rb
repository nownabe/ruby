$LOAD_PATH.unshift(File.expand_path("..", __FILE__))

require "gem_tester/runner"

GemTester::Runner.new(ARGV).run
