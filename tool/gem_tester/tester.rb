require "open3"

module GemTester
  class Tester
    def self.setup!(config)
      config.with_env do
        unless config.manager.installed?("bundler")
          puts "Installing bundler"
          config.manager.install("bundler")
        end
        require "bundler"
      end
    end

    attr_reader :branch
    attr_reader :command
    attr_reader :condition
    attr_reader :config
    attr_reader :debug
    attr_reader :gem_name
    attr_reader :homebrew
    attr_reader :manager
    attr_reader :repository
    attr_reader :spec

    def initialize(gem_name, branch, config:, debug: false, homebrew: false)
      @gem_name = gem_name
      @branch = branch
      @config = config
      @debug = debug
      @homebrew = homebrew

      @condition = config.conditions[gem_name]
      @manager = config.manager
    end

    def run
      config.with_env do
        puts "- Installing #{gem_name}"
        manager.install(gem_name) unless manager.installed?(gem_name)
        @spec = manager.get(gem_name)
        @repository = Repository.new(spec, branch, config: config)
        @command = Command.new(spec, config: config)

        in_repository do
          install_dependencies
          execute_test
        end
      end
    end

    private

    def bundle_install
      Homebrew.configure_bundler(homebrew, config) if homebrew

      Bundler::Installer.install(
        repository.path,
        Bundler.definition.tap(&:validate_runtime!),
        bundle_options
      )
    end

    def bundle_options
      {
        update: true,
      }
    end

    def bundler?
      @is_bundler ||=
        File.exist?(File.join(repository.path, "Gemfile")) ||
        File.exist?(File.join(gem_root, "Gemfile"))
    end

    def execute_precommand
      return unless condition["precommand"]
      puts "- Executing command: `#{condition['precommand']}`"
      Open3.capture3(condition["precommand"])
    end

    def execute_postcommand
      return unless condition["postcommand"]
      puts "- Executing command: `#{condition['postcommand']}`"
      Open3.capture3(condition["postcommand"])
    end

    def execute_test_command
      puts "- Executing command: `#{@command.command}`"
      Result.new(@command.command, *Open3.capture3(@command.command))
    end

    def execute_test
      if bundler?
        Bundler::SharedHelpers.set_bundle_environment
      end
      execute_precommand
      result = execute_test_command
      execute_postcommand
      result
    end

    def gem_root
      @gem_root ||= File.join(repository.path, @condition["root"].to_s)
    end

    def in_repository
      org_env = ENV.to_hash
      org_pwd = Bundler::SharedHelpers.pwd

      setup_repository

      ENV.replace(config.env)
      Bundler::SharedHelpers.chdir(gem_root)

      repository.in_branch { yield }
    ensure
      Bundler.reset!
      Bundler::SharedHelpers.chdir(org_pwd)
      ENV.replace(org_env)
    end

    def install_additional_dependencies
      return unless condition["additional_dependencies"]
      condition["additional_dependencies"].each do |gem|
        name, version = gem.split(":")
        manager.install(name, version) unless manager.installed?(name, version)
      end
    end

    def install_dependencies
      puts "- Installing dependencies"
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

    def setup_repository
      unless repository.exist?
        puts "- Cloning repository from #{repository.repository} to #{repository.path}"
        repository.clone
      end

      puts "- Updating repository #{repository.path}"
      repository.update
    end
  end
end
