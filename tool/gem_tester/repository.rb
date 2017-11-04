# frozen_string_literal: true

require "open-uri"
require "open3"

module GemTester
  class Repository
    attr_reader :base_dir
    attr_reader :condition
    attr_reader :gem
    attr_reader :path
    attr_reader :repository

    def initialize(gem, base_dir:, condition:)
      @gem       = gem
      @base_dir  = base_dir
      @condition = condition
      detect_repository
    end

    def clone(shallow: false)
      depth = shallow ? "--depth 1" : ""
      execute!("git clone #{depth} #{repository} #{path}")
    end

    def exist?
      File.directory?(path)
    end

    def update
      clone unless exist?

      execute!("git pull --all", chdir: path)
    end

    def in_branch(branch = nil)
      if branch
        org_branch = execute!("git rev-parse --abbrev-ref HEAD", chdir: path)
        execute!("git checkout #{branch}", chdir: path)
      end
      yield
    ensure
      execute!("git checkout #{org_branch}", chdir: path) if branch
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

      @path = File.join(base_dir, "github.com", username, repo)
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
