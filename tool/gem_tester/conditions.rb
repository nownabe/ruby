require "forwardable"
require "yaml"

module GemTester
  class Conditions
    extend Forwardable

    def initialize(path)
      @config = YAML.load_file(path)
    end

    def_delegators(
      :@config,
      :keys,
    )

    def [](key)
      @config[key] ||= {}
    end

    def gems
      @gems ||=
        keys.each_with_object({}) do |k, obj|
          obj[k] = @config[k]&.fetch("branch", nil)
        end
    end
  end
end
