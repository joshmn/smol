# frozen_string_literal: true

module Smol
  module AppLookup
    private

    def app_class
      parts = self.class.name.split("::")
      parent = Object.const_get(parts.first)
      parent.const_get(:App)
    end
  end
end
