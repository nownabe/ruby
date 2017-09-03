require "open-uri"
require "open3"

module GemTester
  class Repository
    attr_reader :branch
    attr_reader :config
    attr_reader :condition
    attr_reader :gem
    attr_reader :path
    attr_reader :repository

    def initialize(gem, branch, config:)
      @gem = gem
      @branch = branch
      @config = config
      @condition = config.conditions[gem.name]
      detect_repository
    end

    def clone
      execute!("git clone #{repository} #{path}")
    end

    def exist?
      File.directory?(path)
    end

    def update
      clone unless exist?

      execute!("git pull --all", chdir: path)
    end

    def in_branch
      org_branch = execute!("git rev-parse --abbrev-ref HEAD", chdir: path)
      execute!("git checkout #{branch}", chdir: path) if branch
      yield
    ensure
      execute!("git checkout #{org_branch}", chdir: path) if org_branch
    end

    private

    def detect_repository
      if condition.key?("github")
        @repository = "https://github.com/#{condition['github']}.git"
      elsif %r{https?://github\.com} =~ gem.metadata["source_code_uri"]
        @repository = gem.metadata["source_code_uri"]
      elsif %r{https?://github\.com} =~ gem.homepage
        @repository = gem.homepage
      else
        guess_repository
        raise "Only GitHub repository can be tested." unless @repository
      end
      @repository = @repository.sub(%r{/$}, "")
      @repository = "#{@repository}.git" unless @repository =~ /\.git$/

      _, _, username, repo = @repository.sub(/\.git$/, "").split(%r{//?})

      @path = File.join(@config.repos_dir, "github.com", username, repo)
    end

    def execute!(cmd, options = {})
      o, e, s = Open3.capture3(cmd, options)
      unless s.success?
        raise "Failed: #{cmd}, exited with #{s.exitstatus}.\n#{e}"
      end
      o
    end

    def guess_repository
      url = "https://github.com/#{gem.name}/#{gem.name}"
      open(url)
      @repository = url
    rescue OpenURI::HTTPError
    end
  end
end
