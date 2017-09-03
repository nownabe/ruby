module GemTester
  class Command
    attr_reader :command
    attr_reader :condition
    attr_reader :config
    attr_reader :gem
    attr_reader :manager

    def initialize(gem, config:)
      @gem = gem
      @config = config
      @condition = config.conditions[gem.name]
      @manager = config.manager
      @command = detect_command
    end

    private

    def detect_command
      if condition.key?("rake")
        "rake #{condition['rake']}"
      elsif condition.key?("exec")
        condition["exec"]
      elsif condition.key?("command")
        condition["command"]
      else
        # TODO: make more intelligent
        "rake"
      end
    end
  end
end
