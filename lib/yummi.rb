#                         The MIT License
#
# Copyright (c) 2013 Marcelo Guimarães <ataxexe@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'set'
require 'term/ansicolor'
require_relative "yummi/version"

module Yummi

  #
  # Checks if the environment is supported by Yummi.
  #
  # Currently (known) unsupported environments are:
  #   * Windows
  #
  def self.supported?
    not RUBY_PLATFORM['mingw'] #Windows
  end

  #
  # Colorizes the given string with the given color
  # 
  # The color may be an integer, a string or a dot
  # separated color style (ex: "bold.yellow" or 
  # "underline.bold.green").
  # 
  # Since this method delegates to Term::ANSIColor,
  # the given color should be compatible with it.
  #
  def self.colorize string, color
    return string unless color
    if color.is_a? Fixnum
      string.color color
    elsif color.match(/\./)
      result = string
      color.to_s.split(/\./).each { |c| result = colorize(result, c) }
      result
    elsif color.match(/\d+/)
      string.color color.to_i
    else
      string.send color
    end
  end

  # A module to align texts based on a reference width
  module Aligner

    #
    # Aligns the text
    #
    # === Args
    #
    # +to+::
    #   Defines the type of the alignment (must be a method defined in this module)
    # +text+::
    #   The text to align
    # +width+::
    #   The width of alignment, this will define how much the text will be moved.
    #
    def self.align to, text, width
      send to, text, width
    end

    # Aligns the text to the right
    def self.right text, width
      text = text.to_s unless text.is_a? String
      text.rjust(width)
    end

    # Aligns the text to the left
    def self.left text, width
      text = text.to_s unless text.is_a? String
      text.ljust(width)
    end

    # Aligns the text to the center
    def self.center text, width
      text = text.to_s unless text.is_a? String
      return text if text.size >= width
      size = width - text.size
      left_size = size / 2
      right_size = size - left_size
      (' ' * left_size) << text << (' ' * right_size)
    end

    # Aligns the text to both sides
    def self.justify text, width
      text = text.to_s unless text.is_a? String
      extra_spaces = width - text.size
      return text unless extra_spaces > 0
      words = text.split ' '
      # do not justify only one word
      return text if words.size == 1
      # do not justify few words
      return text if extra_spaces / (words.size - 1) > 2
      until extra_spaces == 0
        words.each_index do |i|
          break if i - 1 == words.size # do not add spaces in the last word
          words[i] << ' '
          extra_spaces -= 1
          break if extra_spaces == 0
        end
      end
      words.join ' '
    end

  end

  #
  # A module to handle blocks by dynamically resolving parameters
  #
  # see #DataEvalColorizer
  #
  module BlockHandler

    #
    # Calls the block resolving the parameters by getting the parameter name from the
    # given context.
    #
    # === Example
    #
    #   context = :max => 10, :curr => 5, ratio => 0.15
    #   percentage = BlockHandler.call_block(context) { |max,curr| curr.to_f / max }
    #
    def block_call (context, &block)
      args = []
      block.parameters.each do |parameter|
        args << context[parameter[1]]
      end
      block.call(*args)
    end

    module_function :block_call

  end

  class Context
    attr_reader :value, :obj

    def initialize (value)
      @value = value
    end

    def [] (index)
      obj[index]
    end
  end

  # A class to expose indexed data by numeric indexes and aliases.
  class IndexedData

    def initialize (aliases, data)
      @aliases = aliases.collect {|a| a.to_s}
      @data = data
    end

    def [](value)
      if value.is_a? Fixnum
        @data[value]
      else
        index = @aliases.index(value.to_s)
        raise Exception::new("Unknow alias #{value}: \nAliases: #{@aliases}") unless index
        @data[index]
      end
    end

  end

  # A class to group components and blocks
  class GroupedComponent

    #
    # Creates a new GroupedComponent
    #
    # === Args
    #
    # +params+::
    #   Hash parameters:
    #     - call_all: indicates if all components must be called. For use if the return
    #     should be ignored
    #     - message: the message to send. Defaults to :call
    #
    def initialize (params = {})
      @components = []
      @call_all = params[:call_all]
      @message = (params[:message] or :call)
    end

    # Adds a new component
    def << (component = nil, &block)
      @components << (component or block)
    end

    #
    # Calls the added components by sending the configured message and the given args.
    #
    def call (*args)
      result = nil
      @components.each do |component|
        break if result and not @call_all
        result = component.send @message, *args
      end
      result
    end

  end

  module Helpers

    def self.load_resource name, params = {:from => ''}
      file = File.expand_path name.to_s
      if File.file? file
        return YAML::load_file(file)
      else
        from = params[:from].to_s
        [
          File.join(File.expand_path('~/.yummi'), from),
          File.join(File.dirname(__FILE__), 'yummi', from)
        ].each do |path|
          file = File.join(path, "#{name}.yaml")
          return YAML::load_file(file) if File.exist?(file)
        end
      end
      raise Exception::new("Unable to load #{name}")
    end

    def self.symbolize_keys hash
      hash.replace(hash.inject({}) do |h, (k, v)|
        v = symbolize_keys(v) if v.is_a? Hash
        if v.is_a? Array
          v.each do |e|
            if e.is_a? Hash
              symbolize_keys(e)
            end
          end
        end
        k = k.to_sym if k.respond_to? :to_sym
        h[k] = v
        h
      end)
    end
  end

end

require_relative 'yummi/no_colors' unless Yummi::supported?

require_relative 'yummi/extensions'
require_relative 'yummi/data_parser'
require_relative "yummi/colorizers"
require_relative "yummi/formatters"
require_relative 'yummi/table'
require_relative 'yummi/table_builder'
require_relative 'yummi/text_box'
require_relative 'yummi/logger'

# if the output is being piped, turn off the colors
unless $stdout.isatty
  require 'yummi/no_colors'
end
