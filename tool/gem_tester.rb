$LOAD_PATH.unshift(File.expand_path("..", __FILE__))

require "fileutils"
require "gem_tester/default_settings"

module GemTester
  autoload :BuiltFiles, "gem_tester/built_files"
  autoload :Command,    "gem_tester/command"
  autoload :Conditions, "gem_tester/conditions"
  autoload :Config,     "gem_tester/config"
  autoload :GemManager, "gem_tester/gem_manager"
  autoload :Homebrew,   "gem_tester/homebrew"
  autoload :Repository, "gem_tester/repository"
  autoload :Result,     "gem_tester/result"
  autoload :Tester,     "gem_tester/tester"

  class << self
    def setup!(config)
      # /bin
      copy(File.join(config.source_dir, "bin"), config[:bindir])
      link(config.built_files.ruby, config.ruby)

      # /lib
      [
        config[:LIBRUBY_SO],
        *config[:LIBRUBY_ALIASES].split,
      ].each do |a|
        link(config.built_files.libruby_so, File.join(config[:libdir], a))
      end
      link(
        File.join(config.build_dir, config[:LIBRUBY_A]),
        File.join(config[:libdir], config[:LIBRUBY_A])
      )

      # /include
      copy(File.join(config.source_dir, "include"), config[:rubyhdrdir])

      # /include/$(rubyarchhdrdir)/ruby/config.h
      # = /include/$(rubyhdrdir)/$(arch)/ruby/config.h
      configh_path = File.join(config[:arch], "ruby", "config.h")
      copy(
        File.join(config.built_files.extout, "include", configh_path),
        File.join(config[:rubyhdrdir], configh_path)
      )
    end

    def with_patched_rbconfig(settings = DefaultSettings.as_hash)
      require "rbconfig"
      build_dir = settings.fetch(:build_dir)
      rbconfig_file = File.join(build_dir, "rbconfig.rb")
      rbconfig = File.read(rbconfig_file)
      original_rbconfig = rbconfig.dup

      settings.fetch(:rbconfig_patch).each do |key, value|
        re = /^\s+CONFIG\["#{key}"\] =\s+"?(?<original>.*?)"?$/
        new_line = %(  CONFIG["#{key}"] = "%s")

        case value
        when String
          rbconfig.sub!(re, new_line % [value])
        when Proc
          rbconfig.sub!(re) { new_line % [value.call($~)] }
        end
      end

      File.write(rbconfig_file, rbconfig)

      Object.send(:remove_const, :RbConfig)
      load(File.join(build_dir, "rbconfig.rb"))

      yield(Config.new(settings))
    ensure
      File.write(rbconfig_file, original_rbconfig)
    end

    private

    def copy(from, to)
      return unless File.exist?(from)
      return if File.exist?(to)
      mkdir(File.dirname(to))
      FileUtils.cp_r(from, to)
    end

    def link(source, link)
      return unless File.exist?(source)
      return if File.exist?(link)
      mkdir(File.dirname(link))
      FileUtils.symlink(source, link)
    end

    def mkdir(dir)
      FileUtils.mkdir_p(dir) unless File.exist?(dir)
    end
  end
end
