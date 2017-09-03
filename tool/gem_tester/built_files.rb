# frozen_string_literal: true

require "rbconfig"

module GemTester
  class BuiltFiles
    attr_reader :build_dir
    attr_reader :rbconfig

    def initialize(build_dir, rbconfig: RbConfig::CONFIG)
      @build_dir = build_dir
      @rbconfig  = rbconfig
    end

    def extout
      join(rbconfig["EXTOUT"]) if rbconfig["EXTOUT"]
    end

    def libruby_so
      join(rbconfig["LIBRUBY_SO"])
    end

    def ruby
      runner = join("ruby-runner#{rbconfig['EXEEXT']}")

      if File.exist?(runner)
        runner
      else
        join("#{rbconfig['RUBY_INSTALL_NAME']}#{rbconfig['EXEEXT']}")
      end
    end

    private

    def join(*path)
      File.join(build_dir, *path)
    end
  end
end
