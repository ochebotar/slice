# frozen_string_literal: true

# Allows view files to be setup that get rendered as PDF.
module Latexable
  extend ActiveSupport::Concern

  included do
    def self.latex_safe(text)
      new.latex_safe(text)
    end

    def self.latex_simple_style(text)
      new.latex_simple_style(text)
    end

    def self.generate_pdf(jobname, output_folder, file_tex)
      # Run twice to allow LaTeX to compile correctly (page numbers, etc)
      `#{ENV['latex_location']} -interaction=nonstopmode --jobname=#{jobname} --output-directory=#{output_folder} #{file_tex}`
      `#{ENV['latex_location']} -interaction=nonstopmode --jobname=#{jobname} --output-directory=#{output_folder} #{file_tex}`
      File.join("tmp", "files", "tex", "#{jobname}.pdf") # Return file name
    end
  end

  def latex_safe(text)
    replacements.inject(text.to_s) do |corpus, (pattern, replacement)|
      corpus.gsub(pattern, replacement)
    end
  end

  def latex_simple_style(text)
    Rails.logger.debug "REMO: in #{text}"
    text = latex_safe(text)
    tags.each do |markup, tag|
      text.gsub!(/#{markup}(.*?)#{markup}/, tag)
    end
    Rails.logger.debug "REMO: out #{text}"
    text
  end

  # List of replacements
  def replacements
    @replacements ||= [
      [/([{}])/,    '\\\\\1'],
      [/\\/,        '\textbackslash{}'],
      [/\^/,        '\textasciicircum{}'],
      [/~/,         '\textasciitilde{}'],
      [/\|/,        '\textbar{}'],
      [/\</,        '\textless{}'],
      [/\>/,        '\textgreater{}'],
      [/([_$&%#])/, '\\\\\1'],
      # Languages (es)
      [/á/, "\\\\'a"],
      [/é/, "\\\\'e"],
      [/í/, "\\\\'i"],
      [/ó/, "\\\\'o"],
      [/ú/, "\\\\'u"],
      [/ü/, "\\\\\"u"],
      [/ñ/, "\\\\~n"],
      [/Á/, "\\\\'A"],
      [/É/, "\\\\'E"],
      [/Í/, "\\\\'I"],
      [/Ó/, "\\\\'O"],
      [/Ú/, "\\\\'U"],
      [/Ü/, "\\\\\"U"],
      [/Ñ/, "\\\\~N"],
      [/¿/, "?`"],
      [/¡/, "!`"]
    ]
  end

  def tags
    @tags ||= [
      ["\\*\\*", "\\textbf{\\1}"],
      ["\\\\_\\\\_", "\\underline{\\1}"],
      ["==", "\\hl{\\1}"],
      ["\\*", "\\\\textit{\\1}"]
    ]
  end
end
