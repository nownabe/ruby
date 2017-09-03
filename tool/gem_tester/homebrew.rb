# frozen_string_literal: true

module GemTester
  module Homebrew
    OPTIONS = {
      "pg" => proc { "--with-pg-config=#{prefix('postgresql')}/bin/pg_config" },
    }

    class << self
      def configure_bundler(gems, config)
        config.with_clean_env do
          target_gems = gems.is_a?(Array) ? gems : OPTIONS.keys
          target_gems.each do |gem|
            set_bundler_option(gem, instance_eval(&OPTIONS[gem]))
          end
        end
      end

      private

      def brew
        @brew ||= `which brew`.chomp
      end

      def prefix(formula)
        `#{brew} --prefix #{formula}`.chomp
      end

      def set_bundler_option(gem, option)
        if Bundler.settings.respond_to?(:set_command_option)
          Bundler.settings.set_command_option(
            "build.#{gem}",
            option
          )
        else
          Bundler.settings["build.#{gem}"] = option
        end
      end
    end
  end
end
