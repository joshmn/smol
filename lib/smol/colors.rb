# frozen_string_literal: true

module Smol
  module Colors
    refine String do
      def green
        "\e[32m#{self}\e[0m"
      end

      def red
        "\e[31m#{self}\e[0m"
      end

      def yellow
        "\e[33m#{self}\e[0m"
      end

      def bold
        "\e[1m#{self}\e[0m"
      end

      def dim
        "\e[2m#{self}\e[0m"
      end
    end
  end
end
