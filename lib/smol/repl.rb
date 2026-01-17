# frozen_string_literal: true

module Smol
  class REPL
    include Output
    include ConfigDisplay
    using Colors

    def initialize(app, prompt:, history: true, history_file: nil, parent: nil)
      @app = app
      @prompt = prompt
      @history = history
      @history_file = history_file || File.expand_path("~/.smol_#{app.class.name.downcase}_history")
      @parent = parent
    end

    def run
      setup_readline if @history
      load_history if @history

      show_boot_message

      loop do
        input = read_input
        break if input.nil?

        input = input.strip
        next if input.empty?

        args = input.split(/\s+/)

        case args.first
        when "exit", "quit", "q"
          break
        when "back"
          break if @parent
          warning "not in a sub-app"
        when "help", "h", "?"
          help
        when "config", "c"
          show_config
        when "config:set"
          set_config(args[1], args[2])
        else
          # Check if entering a mounted sub-app
          mount = @app.find_mount(args.first)
          if mount && args.size == 1
            enter_subapp(mount, args.first)
          else
            dispatch(args)
          end
        end

        nl
      end

      save_history if @history
      hint "goodbye"
    end

    private

    def show_boot_message
      case @app.boot
      when :help
        show_boot_help
      when :minimal
        show_boot_minimal
      when :none
        # nothing
      else
        show_boot_help
      end
    end

    def show_boot_help
      banner @app.banner
      nl
      info @prompt.bold + " - interactive mode"
      nl
      help
      nl
      show_config
      nl
    end

    def show_boot_minimal
      banner @app.banner
      nl
      info @prompt.bold + " - interactive mode"
      hint "type 'help' for commands, 'exit' to quit"
      nl
      show_config
      nl
    end

    def enter_subapp(app_class, name)
      sub_repl = REPL.new(
        app_class,
        prompt: "#{@prompt}:#{name}",
        history: false,
        parent: self
      )
      sub_repl.run
    end

    def dispatch(args)
      cmd_name, *cmd_args = args
      klass = @app.find_command(cmd_name)

      if klass.nil?
        warning "unknown command: #{cmd_name}"
        hint "type 'help' for available commands"
        return
      end

      positional, opts = klass.parse_options(cmd_args)

      if klass.args.size > positional.size
        warning "usage: #{klass.usage}"
        return
      end

      klass.new.call(*positional, **opts)
    end

    def help
      out.puts "commands:".bold

      grouped = @app.commands.group_by(&:group)
      ungrouped = grouped.delete(nil) || []

      ungrouped.each do |cmd|
        print_command(cmd)
      end

      grouped.keys.sort.each do |group_name|
        nl
        out.puts "  #{group_name}:".bold
        grouped[group_name].each do |cmd|
          print_command(cmd, indent: 2)
        end
      end

      if @app.mounts.any?
        nl
        out.puts "  sub-apps:".bold
        @app.mounts.each do |name, app_class|
          out.puts "    #{name.ljust(28)}enter #{app_class.banner.empty? ? name : app_class.banner}"
        end
      end

      nl
      out.puts "  config, c".ljust(32) + "show current config"
      out.puts "  config:set <key> <value>".ljust(32) + "set a config value"
      out.puts "  help, h, ?".ljust(32) + "show this help"
      out.puts "  back".ljust(32) + "return to parent app" if @parent
      out.puts "  exit, quit, q".ljust(32) + "exit"
    end

    def print_command(cmd, indent: 0)
      prefix = "  " * (indent + 1)
      out.puts "#{prefix}#{cmd.usage.ljust(30 - indent * 2)}#{cmd.desc}"
      out.puts "#{prefix}  aliases: #{cmd.aliases.join(', ')}".dim if cmd.aliases.any?
    end

    def setup_readline
      Readline.completion_proc = proc do |input|
        commands = @app.commands.flat_map { |c| [c.command_name.to_s] + c.aliases.map(&:to_s) }
        builtins = %w[help h ? config c config:set exit quit q]
        (commands + builtins).grep(/^#{Regexp.escape(input)}/)
      end
    end

    def load_history
      return unless File.exist?(@history_file)

      File.readlines(@history_file).each do |line|
        Readline::HISTORY << line.chomp
      end
    rescue StandardError
      # ignore history load errors
    end

    def save_history
      File.open(@history_file, "w") do |f|
        Readline::HISTORY.to_a.last(1000).each do |line|
          f.puts line
        end
      end
    rescue StandardError
      # ignore history save errors
    end

    def read_input
      if @history
        prompt_str = "#{@prompt}> "
        line = Readline.readline(prompt_str, true)
        Readline::HISTORY.pop if line&.strip&.empty?
        line
      else
        Smol.output.print "#{@prompt}> ".yellow
        Smol.input.gets
      end
    end
  end
end
