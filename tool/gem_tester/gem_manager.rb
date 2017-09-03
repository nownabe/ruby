require "rubygems"
require "rubygems/requirement"
require "rubygems/dependency_installer"

module GemTester
  class GemManager
    def bindir
      Gem.bindir
    end

    def get(name, requirement = nil)
      unless requirement.instance_of?(Gem::Requirement)
        requirement = Gem::Requirement.create(requirement)
      end
      Gem::Specification.find_by_name(name, requirement)
    end

    def install(name, requirement = nil, options = {})
      unless requirement.instance_of?(Gem::Requirement)
        requirement = Gem::Requirement.create(requirement)
      end
      installer = Gem::DependencyInstaller.new(default_options.merge(options))
      request_set = installer.resolve_dependencies(name, requirement)
      request_set.install(default_options.merge(options))
      installer.errors { |x| puts x.message }
      get(name, requirement)
    end

    def installed?(name, requirement = nil)
      get(name, requirement)
      return true
    rescue Gem::MissingSpecError
      return false
    end

    private

    def default_options
      {
        document: false
      }
    end
  end
end
