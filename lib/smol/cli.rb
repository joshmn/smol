# frozen_string_literal: true

module Smol
  class CLI
    include Output
    include ConfigDisplay
    using Colors

    def initialize(app, prompt:, history: true)
      @app = app
      @prompt = prompt
      @history = history
    end

    def run(args)
      if args.empty?
        if @app.repl
          REPL.new(@app, prompt: @prompt, history: @history, history_file: history_file_path).run
        else
          usage
          exit 1
        end
        return
      end

      unless @app.cli
        failure "CLI mode is disabled"
        hint "run without arguments for interactive mode" if @app.repl
        exit 1
      end

      cmd_name, *cmd_args = args

      case cmd_name
      when "help", "-h", "--help"
        usage
        exit 1
      when "config"
        show_config
        return
      when "config:set"
        set_config(cmd_args[0], cmd_args[1])
        return
      end

      klass = @app.find_command(cmd_name)

      if klass.nil?
        usage
        exit 1
      end

      positional, opts = klass.parse_options(cmd_args)
      result = klass.new.call(*positional, **opts)

      if result == true || result == false
        exit(result ? 0 : 1)
      end
    end

    private

    def usage
      banner @app.banner

      out.puts <<~USAGE
        #{@prompt.bold} - CLI app

        #{"usage:".bold}
          ./#{@prompt}.rb              start interactive mode
          ./#{@prompt}.rb <command>    run a single command

        #{"commands:".bold}
      USAGE

      grouped = @app.commands.group_by(&:group)
      ungrouped = grouped.delete(nil) || []

      ungrouped.each do |cmd|
        out.puts "  #{cmd.usage.ljust(34)}#{cmd.desc}"
      end

      grouped.keys.sort.each do |group_name|
        nl
        out.puts "  #{group_name}:".bold
        grouped[group_name].each do |cmd|
          out.puts "    #{cmd.usage.ljust(32)}#{cmd.desc}"
        end
      end

      if @app.mounts.any?
        nl
        out.puts "  #{"sub-apps:".bold}"
        @app.mounts.each do |name, app_class|
          out.puts "    #{(name + ":*").ljust(32)}#{app_class.banner.empty? ? name : app_class.banner}"
        end
      end

      out.puts "  #{"config".ljust(34)}show current config"
      out.puts "  #{"config:set <key> <value>".ljust(34)}set a config value"

      nl
      show_config
      nl

      out.puts "#{"environment:".bold}"

      @app.config.each do |key, _, setting|
        line = "  #{key.to_s.upcase}"
        line += " - #{setting[:desc]}" if setting[:desc]
        out.puts line
      end
    end

    def history_file_path
      @app.history_file || File.expand_path("~/.smol_#{@prompt}_history")
    end
  end
end
