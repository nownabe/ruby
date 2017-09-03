require "forwardable"

module GemTester
  class Result
    extend Forwardable

    attr_reader :command
    attr_reader :exit_status
    attr_reader :stdout
    attr_reader :stderr

    def initialize(command, stdout, stderr, exit_status)
      @command = command
      @stdout = stdout
      @stderr = stderr
      @exit_status = exit_status
    end

    def_delegators(
      :@exit_status,
      :success?
    )
  end
end
