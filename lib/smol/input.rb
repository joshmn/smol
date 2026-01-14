# frozen_string_literal: true

module Smol
  module Input
    using Colors
    extend self

    def confirm(question, default: nil)
      hint = case default
             when true then "[Y/n]"
             when false then "[y/N]"
             else "[y/n]"
             end

      Smol.output.print "#{question} #{hint} ".yellow
      response = Smol.input.gets&.strip&.downcase

      case response
      when "", nil
        default
      when "y", "yes"
        true
      when "n", "no"
        false
      else
        default
      end
    end

    def ask(question, default: nil)
      prompt = default ? "#{question} [#{default}]" : question
      Smol.output.print "#{prompt}: ".yellow
      response = Smol.input.gets&.strip

      if response.nil? || response.empty?
        default
      else
        response
      end
    end

    def choose(question, choices, default: nil)
      Smol.output.puts question.yellow
      choices.each_with_index do |choice, i|
        marker = (i + 1) == default ? "*" : " "
        Smol.output.puts "#{marker} #{i + 1}) #{choice}"
      end

      Smol.output.print "choice: ".yellow
      response = Smol.input.gets&.strip

      if response.nil? || response.empty?
        default ? choices[default - 1] : nil
      else
        idx = response.to_i - 1
        idx >= 0 && idx < choices.size ? choices[idx] : nil
      end
    end
  end
end
