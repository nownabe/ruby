require_relative "./gem_tester"

GemTester.with_patched_rbconfig do |config|
  GemTester.setup!(config)

  config.with_env do
    system(ARGV.join(" "))
  end
end
