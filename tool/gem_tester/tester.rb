require "open3"

module GemTester
  class Tester
    def self.setup(config: GemTester.config)
      manager = GemTester.config.manager
      unless manager.installed?("bundler")
        puts "Installing bundler"
        manager.install("bundler")
      end
      require "bundler"
    end

    attr_reader :branch
    attr_reader :command
    attr_reader :condition
    attr_reader :config
    attr_reader :debug
    attr_reader :gem_name
    attr_reader :manager
    attr_reader :repository
    attr_reader :spec

    def initialize(gem_name, branch, config: GemTester.config, debug: false)
      @gem_name = gem_name
      @branch = branch
      @config = config
      @debug = debug

      @condition = config.conditions[gem_name] || {}
      @manager = config.manager
    end

    def run
      manager.install(gem_name) unless manager.installed?(gem_name)
      @spec = manager.get(gem_name)
      @repository = Repository.new(spec, branch, config: config)
      @command = Command.new(spec, config: config)

      unless repository.exist?
        puts "Cloning repository from #{repository.repository} to #{repository.path}"
        repository.clone
      end

      puts "Updating repository #{repository.path}"
      repository.update

      in_repository do
        puts "Installing dependencies"
        install_dependencies
        puts "Executing test"
        execute_test
      end
    end

    private

    def bundle_install
      Bundler::Installer.install(
        repository.path,
        Bundler.definition.tap(&:validate_runtime!),
        bundle_options
      )
    end

    def bundle_options
      {}
    end

    def bundler?
      condition.fetch("bundler", true)
    end

    def execute_test
      if bundler?
        Bundler::SharedHelpers.set_bundle_environment
      end
      puts @command.command
      Result.new(@command.command, *Open3.capture3(@command.command))
    end

    def gem_root
      @gem_root ||= File.join(repository.path, @condition["root"].to_s)
    end

    def in_repository
      org_pwd = Bundler::SharedHelpers.pwd
      Bundler::SharedHelpers.chdir(gem_root)
      Bundler.send(:with_env, config.env) do
        repository.in_branch { yield }
      end
    ensure
      Bundler.reset!
      Bundler::SharedHelpers.chdir(org_pwd)
    end

    def install_additional_dependencies
      return unless condition["additional_dependencies"]
      condition["additional_dependencies"].each do |gem|
        manager.install(gem) unless manager.installed?(gem)
      end
    end

    def install_dependencies
      if bundler?
        bundle_install
      else
        spec.dependencies.reject do |dep|
          manager.installed?(dep.name, dep.requirement)
        end.each do |dep|
          manager.install(dep.name, dep.requirement)
        end
      end
      install_additional_dependencies
    end

    def puts(msg)
      return unless debug
      $stderr.puts(msg)
    end
  end
end
