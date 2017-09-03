# frozen_string_literal: true

require "rbconfig"

require "gem_tester/built_files"
require "gem_tester/conditions"
require "gem_tester/gem_manager"

module GemTester
  class SandboxConfig
    attr_reader :build_dir
    attr_reader :built_files
    attr_reader :conditions
    attr_reader :gem_home
    attr_reader :manager
    attr_reader :original_env
    attr_reader :repos_dir
    attr_reader :source_dir

    def initialize(settings)
      @build_dir  = settings.fetch(:build_dir)
      @gem_home   = settings.fetch(:gem_home)
      @repos_dir  = settings.fetch(:repos_dir)
      @source_dir = settings.fetch(:source_dir)

      @built_files = BuiltFiles.new(build_dir, rbconfig: self)
      @conditions  = Conditions.new(settings.fetch(:conditions_file))
      @manager     = GemManager.new

      @original_env = ENV.to_hash
    end

    def [](k)
      RbConfig::CONFIG[k.to_s]
    end

    def clean_env
      {
        "HOME" => original_env["HOME"],
        "PATH" => original_env["PATH"],
        "TERM" => original_env["TERM"],
      }
    end

    def enable_shared?
      self[:ENABLE_SHARED] == "yes"
    end

    def env
      clean_env.merge(
        "GEM_HOME" => gem_home,
        "GEM_PATH" => gem_home,
        "PATH" => path,
        "RUBY" => ruby,
        "RUBYLIB" => rubylib,
        "RUBYOPT" => "-EUTF-8",
      ).merge(libpath_env).merge(preload_env)
    end

    def ruby
      File.join(self[:bindir], self[:RUBY_INSTALL_NAME] + self[:EXEEXT])
    end

    def with_clean_env(options = {})
      org_env = ENV.to_hash
      ENV.replace(clean_env.merge(options))
      yield(ENV.to_hash)
    ensure
      ENV.replace(org_env)
    end

    def with_env(options = {})
      org_env = ENV.to_hash
      org_gem_paths = {
        "GEM_HOME" => Gem.paths.home,
        "GEM_PATH" => Gem.paths.path.join(File::PATH_SEPARATOR)
      }

      ENV.replace(env.merge(options))
      Gem.paths = { "GEM_HOME" => gem_home }

      yield(ENV.to_hash)
    ensure
      Gem.paths = org_gem_paths
      ENV.replace(org_env)
    end

    private

    def libpath_env
      key = self[:LIBPATHENV]
      return {} if key.nil? || key.empty?
      { key => [build_dir, ENV[key]].compact.join(File::PATH_SEPARATOR) }
    end

    def path
      [
        self[:bindir],
        File.join(gem_home, "bin"),
        ENV["PATH"]
      ].compact.join(File::PATH_SEPARATOR)
    end

    def preload_env
      return {} unless enable_shared?
      return {} if /darwin/ =~ RUBY_PLATFORM
      key = self[:PRELOADENV]
      return {} unless key
      key = "LD_PRELOAD" if key.empty? && /linux/ =~ RUBY_PLATFORM
      { key => [built_files.libruby_so, ENV[key]].compact.join(File::PATH_SEPARATOR) }
    end

    def rubylib
      libs = [self[self[:libdirname]]]
      libs << build_dir
      libs << self[:rubylibdir]
      if built_files.extout
        libs << File.join(built_files.extout, self[:arch])
        libs << File.join(built_files.extout, "common")
      end
      libs.reverse.join(File::PATH_SEPARATOR)
    end
  end
end
