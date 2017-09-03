module GemTester
  class BuiltFiles
    attr_reader :build_dir
    attr_reader :rbconfig

    def initialize(build_dir)
      @build_dir = build_dir
    end

    def extout
      join(c["EXTOUT"]) if c["EXTOUT"]
    end

    def libruby_so
      join(c["LIBRUBY_SO"])
    end

    def ruby
      runner = join("ruby-runner#{c['EXEEXT']}")

      if File.exist?(runner)
        runner
      else
        join("#{c[:RUBY_INSTALL_NAME]}#{c[:EXEEXT]}")
      end
    end

    private

    def c
      RbConfig::CONFIG
    end

    def join(*path)
      File.join(build_dir, *path)
    end
  end
end
