# frozen_string_literal: true

require "fileutils"

module GemTester
  class PseudoInstaller
    attr_reader :config

    def initialize(config)
      @config = config
    end

    def install
      install_bin
      install_include
      install_lib
    end

    private

    def copy(from, to)
      return unless File.exist?(from)
      return if File.exist?(to)
      mkdir(File.dirname(to))
      FileUtils.cp_r(from, to)
    end

    def install_bin
      copy(File.join(config.source_dir, "bin"), config[:bindir])
      link(config.built_files.ruby, config.ruby)
    end

    def install_include
      copy(File.join(config.source_dir, "include"), config[:rubyhdrdir])

      configh_path_suffix = File.join(config[:arch], "ruby", "config.h")
      link(
        File.join(config.built_files.extout, "include", configh_path_suffix),
        File.join(config[:rubyhdrdir], configh_path_suffix)
      )
    end

    def install_lib
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
      copy(
        File.join(config.source_dir, "lib"),
        File.join(config[:rubylibdir])
      )
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
