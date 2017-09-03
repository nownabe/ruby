require "rbconfig"
require "yaml"

module GemTester
  class Config
    attr_accessor :build_dir
    attr_accessor :conditions
    attr_accessor :conditions_file
    attr_accessor :debug
    attr_accessor :gem_home
    attr_accessor :manager
    attr_accessor :repos_dir
    attr_accessor :source_dir

    def initialize
      @build_dir       = File.expand_path(".")
      @conditions_file = File.expand_path("../conditions.yaml", __FILE__)
      @conditions      = Conditions.new(@conditions_file)
      @gem_home        = File.join(build_dir, "gems")
      @repos_dir       = File.join(gem_home, "repos")
      @source_dir      = File.expand_path("../../../", __FILE__)
      @manager         = GemManager.new(config: self)
    end

    def built_ruby
      File.join(
        build_dir,
        rbconfig["RUBY_INSTALL_NAME"] + rbconfig["EXEEXT"]
      )
    end

    def env
      {
        "GEM_HOME" => gem_home,
        "GEM_PATH" => gem_home,
        "PATH" => path,
        "RUBY" => ruby,
        "RUBYLIB" => rubylib,
        "RUBYOPT" => "-EUTF-8",
      }.merge(libpath_env).merge(preload_env)
    end

    def extout_path
      File.join(build_dir, rbconfig["EXTOUT"]) if rbconfig["EXTOUT"]
    end

    def libruby_so
      File.join(build_dir, rbconfig["LIBRUBY_SO"])
    end

    def rbconfig
      RbConfig::CONFIG
    end

    def ruby
      File.join(
        build_dir,
        "bin",
        rbconfig["RUBY_INSTALL_NAME"] + rbconfig["EXEEXT"]
      )
    end

    private

    def libpath_env
      key = rbconfig["LIBPATHENV"]
      return {} if key.nil? || key.empty?
      { key => [build_dir, ENV[key]].compact.join(File::PATH_SEPARATOR) }
    end

    def path
      [
        File.join(build_dir, "bin"),
        File.join(gem_home, "bin"),
        ENV["PATH"]
      ].compact.join(File::PATH_SEPARATOR)
    end

    def preload_env
      key = rbconfig["PRELOADENV"]
      return {} unless key
      key = "LD_PRELOAD" if key.empty? && /linux/ =~ RUBY_PLATFORM
      { key => [libruby_so, ENV[key]].compact.join(File::PATH_SEPARATOR) }
    end

    def rubylib
      libs = [build_dir]
      if extout_path
        libs << File.expand_path("common", extout_path)
        libs << File.expand_path(rbconfig["arch"], extout_path)
      end
      libs << File.expand_path("lib", source_dir)
      libs |= ENV["RUBYLIB"].split(File::PATH_SEPARATOR) if ENV["RUBYLIB"]

      libs.join(File::PATH_SEPARATOR)
    end
  end
end
