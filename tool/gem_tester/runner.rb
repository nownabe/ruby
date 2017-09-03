# frozen_string_literal: true

require "gem_tester/sandbox"
require "gem_tester/tester"

module GemTester
  class Runner
    def initialize(args = ARGV)
      parse_args(args)
    end

    def run
      results = test_gems

      success = results.count { |_, result| result.success? }
      failure = results.size - success
      total = results.size

      puts
      puts "Total: #{total}, Success: #{success}, Failure: #{failure}"
      if failure.nonzero?
        puts "Failed gems:"
        results.reject { |_, result| result.success? }.each do |gem, _|
          puts "  - #{gem}"
        end
      end

      exit failure.zero? ? 0 : 1
    end

    private

    def parse_args(args)
      @homebrew = false

      @test_gems = ARGV.map { |a| a.split(",") }.flatten.each_with_object({}) do |g, obj|
        # TODO: --help
        # TODO: --conditions=
        if /--with-homebrew(=(?<gems>.+))?/ =~ g
          @homebrew = gems ? gems.split(",") : true
          next
        end

        name, branch = g.split(":")
        obj[name] = branch
      end
    end

    def test_gem(gem, branch, config)
      puts "\n* Gem Test: #{gem} (branch or tag: #{branch})"
      tester = GemTester::Tester.new(
        gem,
        branch,
        config: config,
        debug: true,
        homebrew: @homebrew
      )
      result = tester.run

      if result.success?
        puts "- Succeeded!"
      else
        puts "- Failed!"
        puts "\n  - Stdout:"
        puts result.stdout
        puts "\n  - Stderr:"
        puts result.stderr
      end

      [gem, result]
    end

    def test_gems
      Sandbox.new.run do |config|
        GemTester::Tester.setup!(config)

        @test_gems = config.conditions.gems if @test_gems.empty?

        @test_gems.map { |gem, branch| test_gem(gem, branch, config) }
      end
    end
  end
end
