require_relative "./gem_tester"

def test(gem, branch, config, homebrew: false)
  puts "\n* Gem Test: #{gem} (branch or tag: #{branch})"
  tester = GemTester::Tester.new(gem, branch, config: config, debug: true, homebrew: homebrew)
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
  [gem, result]
end

with_homebrew = false

test_gems = ARGV.map { |a| a.split(",") }.flatten.each_with_object({}) do |g, obj|
  if /--with-homebrew(=(?<gems>.+))?/ =~ g
    with_homebrew = gems ? gems.split(",") : true
    next
  end

  name, branch = g.split(":")
  obj[name] = branch
end

results = GemTester.with_patched_rbconfig do |config|
  GemTester.setup!(config)
  GemTester::Tester.setup!(config)

  test_gems = config.conditions.gems if test_gems.empty?

  test_gems.map { |gem, branch| test(gem, branch, config, homebrew: with_homebrew) }
end

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
