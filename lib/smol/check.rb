# frozen_string_literal: true

module Smol
  class Check
    include AppLookup

    class << self
      def inherited(subclass)
        super
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

          if candidate.respond_to?(:register_check)
            app_class = find_app_class_for(candidate)
            return if app_class&.explicit_registration?

            candidate.register_check(subclass)
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

      def check_name
        name.split("::").last
          .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
          .gsub(/([a-z\d])([A-Z])/, '\1_\2')
          .downcase
          .tr("_", " ")
      end
    end

    def pass(message)
      CheckResult.new(passed: true, message: message)
    end

    def fail(message)
      CheckResult.new(passed: false, message: message)
    end

    def config
      app_class.config
    end
  end
end
