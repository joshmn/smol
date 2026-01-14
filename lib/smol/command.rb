# frozen_string_literal: true

module Smol
  class Command
    include AppLookup

    class << self
      include Coercion

      def inherited(subclass)
        super
        subclass.prepend ErrorHandler
        subclass.prepend Callbacks
        subclass.prepend AutoMessage
        register_to_app(subclass)
      end

      private

      def register_to_app(subclass)
        parts = subclass.name&.split("::")
        return unless parts && parts.size > 1

        parts[0..-2].size.times do |i|
          candidate_name = parts[0..-(i + 2)].join("::")
          begin
            candidate = Object.const_get(candidate_name)
          rescue NameError
            next
          end

          if candidate.respond_to?(:register_command)
            app_class = find_app_class_for(candidate)
            return if app_class&.explicit_registration?

            candidate.register_command(subclass)
            return
          end
        end
      end

      def find_app_class_for(candidate)
        return candidate if candidate.respond_to?(:explicit_registration?)

        if candidate.const_defined?(:App, false)
          app = candidate.const_get(:App)
          return app if app.respond_to?(:explicit_registration?)
        end
        nil
      end

      public

      def command_name(text = nil)
        if text
          @command_name = text
        else
          @command_name || derive_command_name
        end
      end

      def title(text = nil)
        @title = text if text
        @title
      end

      def explain(text = nil)
        @explain = text if text
        @explain
      end

      def aliases(*args)
        @aliases = args if args.any?
        @aliases || []
      end

      def args(*args)
        @args = args if args.any?
        @args || []
      end

      def option(name, short: nil, type: :string, default: nil, desc: nil)
        @options ||= {}
        @options[name] = { short: short, type: type, default: default, desc: desc }
      end

      def options
        @options || {}
      end

      def desc(text = nil)
        @desc = text if text
        @desc || ""
      end

      def group(text = nil)
        @group = text if text
        @group
      end

      def before_action(method_name)
        @before_actions ||= []
        @before_actions << method_name
      end

      def before_actions
        @before_actions || []
      end

      def after_action(method_name)
        @after_actions ||= []
        @after_actions << method_name
      end

      def after_actions
        @after_actions || []
      end

      def matches?(input)
        input == command_name.to_s || aliases.map(&:to_s).include?(input)
      end

      def usage
        parts = [command_name]
        parts += args.map { |a| "<#{a}>" }
        options.each do |name, opt|
          flag = opt[:short] ? "-#{opt[:short]}/--#{name}" : "--#{name}"
          parts << "[#{flag}]"
        end
        parts.join(" ")
      end

      def parse_options(argv)
        positional = []
        opts = options.transform_values { |o| o[:default] }

        i = 0
        while i < argv.length
          arg = argv[i]
          if arg.start_with?("--")
            key, value = arg[2..].split("=", 2)
            key = key.tr("-", "_").to_sym
            if options[key]
              value ||= argv[i += 1]
              opts[key] = coerce_value(value, options[key][:type])
            end
          elsif arg.start_with?("-") && arg.length == 2
            short = arg[1]
            opt_name = options.find { |_, o| o[:short]&.to_s == short }&.first
            if opt_name
              value = argv[i += 1]
              opts[opt_name] = coerce_value(value, options[opt_name][:type])
            end
          else
            positional << arg
          end
          i += 1
        end

        [positional, opts]
      end

      def rescue_from(*exceptions, with: nil, &block)
        handler = block || with
        raise ArgumentError, "rescue_from requires a block or :with handler" unless handler

        @error_handlers ||= []
        exceptions.each do |exception|
          @error_handlers << [exception, handler]
        end
      end

      def error_handlers
        @error_handlers || []
      end

      private

      def derive_command_name
        return "anonymous" unless name

        name.split("::").last
          .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
          .gsub(/([a-z\d])([A-Z])/, '\1_\2')
          .downcase
      end
    end

    module AutoMessage
      def call(*args, **opts)
        if self.class.title
          header self.class.title
          desc self.class.explain if self.class.explain
          nl
        end
        super
      end
    end

    module Callbacks
      def call(*args, **opts)
        self.class.before_actions.each do |method_name|
          result = send(method_name, *args, **opts)
          return result if result == false
        end

        result = super

        self.class.after_actions.each do |method_name|
          send(method_name, *args, result: result, **opts)
        end

        result
      end
    end

    module ErrorHandler
      def call(*args, **opts)
        super
      rescue => e
        handler = find_error_handler(e)
        if handler
          if handler.is_a?(Symbol)
            send(handler, e)
          else
            instance_exec(e, &handler)
          end
        else
          raise
        end
      end

      private

      def find_error_handler(error)
        self.class.error_handlers.each do |exception_class, handler|
          return handler if error.is_a?(exception_class)
        end
        nil
      end
    end

    include Output
    include Input

    def config
      app_class.config
    end

    def app
      app_class
    end

    def checking(name)
      warning "checking: #{name}"
      nl
    end

    def dropping(target)
      warning "dropping: #{target}"
      nl
    end

    def done(hint_text = nil)
      nl
      success "done"
      hint hint_text if hint_text
    end

    def checks_passed?(all_passed, pass_hint: nil, fail_hint: nil)
      nl
      if all_passed
        success "all checks passed"
        hint pass_hint if pass_hint
      else
        failure "some checks failed"
        hint fail_hint if fail_hint
      end
      all_passed
    end

    def run_checks(*check_classes, args: [])
      results = check_classes.map do |klass|
        result = klass.new(*args).call
        check_result(klass.check_name, result)
        nl
        result.passed?
      end
      results.all?
    end
  end
end
