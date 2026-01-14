# frozen_string_literal: true

module Smol
  module ConfigDisplay
    include Output
    using Colors

    private

    def show_config
      out.puts "config:".bold
      @app.config.each do |key, value, setting|
        line = "  #{key}: #{value}"
        line += " - #{setting[:desc]}" if setting[:desc]
        out.puts line.dim
      end
    end

    def set_config(key, value)
      if key.nil? || value.nil?
        warning "usage: config:set <key> <value>"
        return
      end

      @app.config.set(key.to_sym, value)
      success "#{key} = #{@app.config[key.to_sym]}"
    rescue ArgumentError => e
      failure e.message
    end
  end
end
