require_relative "./gem_tester"

results = nil

GemTester.with_patched_rbconfig do
  GemTester.setup

  test_gems =
    if ARGV.empty?
      GemTester.config.conditions.gems
    else
      ARGV.map { |a| a.split(",") }.flatten.each_with_object({}) do |g, obj|
        name, branch = g.split(":")
        obj[name] = branch
      end
    end

  results =
    test_gems.map do |gem, branch|
      puts "Start #{gem} (branch or tag: #{branch})"
      tester = GemTester::Tester.new(gem, branch, debug: true)
      result = tester.run
      # TODO: make better output
      if result.success?
        puts "Succeeded #{gem} test."
        puts result.stdout
      else
        puts "Failed #{gem} test."
        puts result.stdout
        puts result.stderr
      end
      result
    end
end

success = 0
failure = 0
total = results.size

results.each do |r|
  r.success? ? success += 1 : failure += 1
end

puts
puts "Total: #{total}, Success: #{success}, Failure: #{failure}"

exit failure.zero? ? 0 : 1
