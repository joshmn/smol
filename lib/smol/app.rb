# frozen_string_literal: true

module Smol
  class App
    class << self
      def inherited(subclass)
        super
        subclass.instance_variable_set(:@commands, [])
        subclass.instance_variable_set(:@checks, [])
        subclass.instance_variable_set(:@mounts, {})

        parent_module = find_parent_module(subclass)
        setup_registry_methods(parent_module, subclass) if parent_module
      end

      def banner(text = nil)
        @banner = text if text
        @banner || ""
      end

      def cli(enabled = nil)
        @cli_enabled = enabled unless enabled.nil?
        @cli_enabled.nil? ? true : @cli_enabled
      end

      def repl(enabled = nil)
        @repl_enabled = enabled unless enabled.nil?
        @repl_enabled.nil? ? true : @repl_enabled
      end

      def boot(mode = nil)
        @boot_mode = mode if mode
        @boot_mode || :help
      end

      def history_file(path = nil)
        @history_file = path if path
        @history_file
      end

      def config
        @config ||= Config.new
      end

      def commands
        @commands ||= []
      end

      def checks
        @checks ||= []
      end

      def mounts
        @mounts ||= {}
      end

      def mount(app_class, as:)
        mounts[as.to_s] = app_class
      end

      def find_command(name)
        # Check for mounted app prefix (e.g., "admin:users")
        if name.include?(":")
          prefix, sub_name = name.split(":", 2)
          if mounts[prefix]
            return mounts[prefix].find_command(sub_name)
          end
        end

        commands.find { |c| c.matches?(name) }
      end

      def find_mount(name)
        mounts[name.to_s]
      end

      def register_command(command_class)
        commands << command_class
      end

      def register_check(check_class)
        checks << check_class
      end

      def register(command_class)
        @explicit_registration = true
        commands << command_class
      end

      def explicit_registration?
        @explicit_registration || false
      end

      private

      def find_parent_module(subclass)
        parts = subclass.name&.split("::")
        return nil unless parts && parts.size > 1

        parent_name = parts[0..-2].join("::")
        begin
          Object.const_get(parent_name)
        rescue NameError
          nil
        end
      end

      def setup_registry_methods(parent_module, app_class)
        unless parent_module.respond_to?(:register_command)
          parent_module.define_singleton_method(:register_command) do |cmd|
            app_class.register_command(cmd)
          end
        end
        unless parent_module.respond_to?(:register_check)
          parent_module.define_singleton_method(:register_check) do |check|
            app_class.register_check(check)
          end
        end
      end
    end
  end
end
