# frozen_string_literal: true

require "gem_tester/default_settings"
require "gem_tester/pseudo_installer"
require "gem_tester/sandbox_config"

module GemTester
  class Sandbox
    attr_reader :rbconfig_patch
    attr_reader :rbconfig_path
    attr_reader :settings

    def initialize(settings = DefaultSettings.as_hash)
      @settings       = settings
      @rbconfig_patch = settings.fetch(:rbconfig_patch)
      @rbconfig_path  = File.join(settings.fetch(:build_dir), "rbconfig.rb")
    end

    # TODO: 排他制御(rbconfig.lock?)
    def run
      rbconfig = File.read(rbconfig_path)
      original_rbconfig = rbconfig.dup

      rbconfig_patch.each do |key, value|
        re = /^\s+CONFIG\["#{key}"\] =\s+"?(?<original>.*?)"?$/
        new_line = %(  CONFIG["#{key}"] = "%s")

        case value
        when String
          rbconfig.sub!(re, new_line % [value])
        when Proc
          rbconfig.sub!(re) { new_line % [value.call($~)] }
        end
      end

      File.write(rbconfig_path, rbconfig)
      Object.send(:remove_const, :RbConfig) if Object.const_defined?(:RbConfig)
      load(rbconfig_path)

      config = SandboxConfig.new(settings)
      PseudoInstaller.new(config).install

      yield(config)
    ensure
      File.write(rbconfig_path, original_rbconfig)
    end
  end
end
