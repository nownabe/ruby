$LOAD_PATH.unshift(File.expand_path("..", __FILE__))

require "fileutils"

module GemTester
  autoload :Command,    "gem_tester/command"
  autoload :Conditions, "gem_tester/conditions"
  autoload :Config,     "gem_tester/config"
  autoload :GemManager, "gem_tester/gem_manager"
  autoload :Repository, "gem_tester/repository"
  autoload :Result,     "gem_tester/result"
  autoload :Tester,     "gem_tester/tester"

  class << self
    def default_config
      @default_config ||= Config.new
    end
    alias config default_config

    def make_dummy_install_directories(config: self.config)
      # /bin
      link(config.built_ruby, config.ruby)

      # /lib
      [
        RbConfig::CONFIG["LIBRUBY_SO"],
        *RbConfig::CONFIG["LIBRUBY_ALIASES"].split
      ].each do |a|
        link(config.libruby_so, File.join(config.rbconfig["libdir"], a))
      end

      # /include
      copy(
        File.join(config.source_dir, "include"),
        config.rbconfig["rubyhdrdir"]
      )
      configh_path = File.join(config.rbconfig["arch"], "ruby", "config.h")
      copy(
        File.join(config.extout_path, "include", configh_path),
        File.join(config.rbconfig["rubyhdrdir"], configh_path)
      )
    end

    def setup
      make_dummy_install_directories
      GemManager.setup
      Tester.setup
    end

    def with_patched_rbconfig(config: self.config)
      require "rbconfig"
      rbconfig_file = File.join(config.build_dir, "rbconfig.rb")
      rbconfig = File.read(rbconfig_file)
      original_rbconfig = rbconfig.dup

      # Replace prefix with dummy directory.
      rbconfig.sub!(
        /^\s+CONFIG\["prefix"\] = .+$/,
        "  CONFIG[\"prefix\"] = \"#{config.build_dir}\""
      )

      # Replace includedir with source directory
      # includedir = File.join(config.build_dir, RbConfig::CONFIG["EXTOUT"])
      # includedir = File.join(config.extout_path, "include")
      # rbconfig.sub!(
      #   /^\s+CONFIG\["includedir"\] = .+$/,
      #   "  CONFIG[\"includedir\"] = \"#{includedir}\""
      # )
      # RbConfig::CONFIG["includedir"] = includedir


      # Replace libdir with the directory of built ruby.
      # rbconfig.sub!(
      #   /^\s+CONFIG\["libdir"\] = .+$/,
      #   "  CONFIG[\"libdir\"] = \"#{config.build_dir}\""
      # )
      # RbConfig::CONFIG["libdir"] = config.build_dir

      # Replace bindir with the directory of built ruby.
      # rbconfig.sub!(
      #   /^\s+CONFIG\["bindir"\] = .+$/,
      #   "  CONFIG[\"bindir\"] = \"#{config.build_dir}\""
      # )

      # Add $extout for mkmf.rb
      #
      # TODO: Remove this.
      #       It is required for rdiscount(bundler dependency) in mkmf.rb.
      #       mkmf.rb makes Makefile with empty `extout`.
      #       Is it a bug of mkmf.rb?
      # if RbConfig::CONFIG["EXTOUT"]
      #   extout = File.join(config.build_dir, RbConfig::CONFIG["EXTOUT"])
      #   rbconfig << "\n$extout = \"#{extout}\"\n"
      #   $extout = extout
      # end

      File.write(rbconfig_file, rbconfig)

      Object.send(:remove_const, :RbConfig)
      load(File.join(config.build_dir, "rbconfig.rb"))

      yield
    ensure
      File.write(rbconfig_file, original_rbconfig)
    end

    private

    def copy(from, to)
      return if File.exist?(to)
      mkdir(File.dirname(to))
      FileUtils.cp_r(from, to)
    end

    def link(source, link)
      return if File.exist?(link)
      mkdir(File.dirname(link))
      FileUtils.symlink(source, link)
    end

    def mkdir(dir)
      FileUtils.mkdir_p(dir) unless File.exist?(dir)
    end
  end
end
