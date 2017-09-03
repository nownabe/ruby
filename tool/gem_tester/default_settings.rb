module GemTester
  module DefaultSettings
    class << self
      def as_hash
        {
          build_dir: build_dir,
          conditions_file: conditions_file,
          rbconfig_patch: rbconfig_patch,
          gem_home: gem_home,
          repos_dir: repos_dir,
          source_dir: source_dir,
        }
      end

      def build_dir
        @build_dir ||= File.expand_path(".").freeze
      end

      def conditions_file
        @conditions_file ||= File.expand_path("../conditions.yaml", __FILE__).freeze
      end

      def gem_home
        @gem_home ||= File.join(build_dir, "gems").freeze
      end

      def initialize
        as_hash
      end

      def rbconfig_patch
        {
          prefix: build_dir,
        }
      end

      def repos_dir
        @repos_dir ||= File.join(gem_home, "repos").freeze
      end

      def source_dir
        @source_dir ||= File.expand_path("../../../", __FILE__).freeze
      end
    end
  end
end

GemTester::DefaultSettings.initialize
