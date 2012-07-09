#                         The MIT License
#
# Copyright (c) 2012 Marcelo Guimarães <ataxexe@gmail.com>
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

require_relative "yummi/version"

module Yummi
  # Base for colorizing
  module Color

    # The Color Schema Definition
    module Schema
      # Normal Linux Terminal Colors, used by default in normal, underscore, blink and
      # highlight color types
      NORMAL_COLORS = {
        :colors => [:black, :red, :green, :brown, :blue, :purple, :cyan, :gray],
        :default => :gray
      }
      # Intense Linux Terminal Colors, used by default in intense and strong color types
      ALTERNATE_COLORS = {
        :colors => [:gray, :red, :green, :yellow, :blue, :purple, :cyan, :white],
        :default => :gray
      }
    end

    # Colors from default linux terminal scheme
    COLORS = {}

    def self.load_color_map mappings
      COLORS.clear
      mappings.each do |type, config|
        schema = config[:schema]
        schema[:colors].each_with_index do |color, key_code|
          # maps the default color for a type
          COLORS[type] = "#{config[:key_code]};3#{key_code}" if color == schema[:default]
          # do not use prefix if schema is default
          prefix = (type == :default ? '' : "#{type}_")
          # maps the color using color name
          key = "#{prefix}#{color}"
          COLORS[key.to_sym] = "#{config[:key_code]};3#{key_code}"
          # maps the color using color key code
          key = "#{prefix}#{key_code + 1}"
          COLORS[key.to_sym] = "#{config[:key_code]};3#{key_code}"
          # maps the color using color name if default schema does not defines it
          # example: yellow and white are present only in strong/intense schema
          COLORS[color.to_sym] = "#{config[:key_code]};3#{key_code}" unless COLORS[color]
        end
      end
    end

    # Escape the given text with the given color code
    def self.escape key
      return key unless key and COLORS[key.to_sym]
      "\033[#{COLORS[key.to_sym]}m"
    end

    # Colorize the given text with the given color
    def self.colorize string, color
      color, end_color = [color, "\033[0;0m"].map { |key| Color.escape(key) }
      color ? "#{color}#{string}#{end_color}" : string
    end

    # Extracts the text from a colorized string
    def self.raw string
      string.gsub(/\033\[\d;\d{2}m/, '').gsub(/\033\[0;0m/, '')
    end

  end

  # see #Color#colorize
  def self.colorize string, color
    Color.colorize string, color
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
      block.call *args
    end

    module_function :block_call

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
      text.rjust(width)
    end

    # Aligns the text to the left
    def self.left text, width
      text.ljust(width)
    end

    # Aligns the text to the center
    def self.center text, width
      return text if text.size >= width
      size = width - text.size
      left_size = size / 2
      right_size = size - left_size
      (' ' * left_size) << text << (' ' * right_size)
    end

    # Aligns the text to both sides
    def self.justify text, width
      extra_spaces = width - text.size
      return text unless extra_spaces > 0
      words = text.split ' '
      return text if words.size == 1
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
  # A module that defines a colorizer capable component.
  #
  # Include this module in any component that returns a color in response for :call:.
  #
  module Colorizer

    #
    # Colorizes a string by passing the arguments to the :call: method to get the proper
    # color.
    #
    # === Args
    #
    # An array of arguments that will be passed to :call: method to get the color. By
    # convention, the first argument must be the object to colorize (to_s is called on it
    # for getting the text to colorize).
    #
    def colorize (*args)
      color = call *args
      Yummi.colorize args.first.to_s, color
    end

  end

  #
  # Adds the #Colorizer module to the given block, so you can use it to colorize texts.
  #
  # === Example
  #
  #   colorizer = Yummi.to_colorize { |value| value % 2 == 0 ? :green : :blue }
  #   10.times { |n| puts colorizer.colorize n }
  #
  def self.to_colorize &block
    block.extend Colorizer
  end

  # A module with useful colorizers
  module Colorizers

    # Joins the given colorizers to work as one
    def self.join *colorizers
      join = Yummi::GroupedComponent::new
      colorizers.each { |c| join << c }
      join.extend Colorizer
    end

    # Returns a new instance of #DataEvalColorizer
    def self.by_data_eval &block
      DataEvalColorizer::new &block
    end

    # Returns a new instance of #EvalColorizer
    def self.by_eval &block
      EvalColorizer::new &block
    end

    # Returns a new instance of #StripeColorizer
    def self.stripe *colors
      StripeColorizer::new *colors
    end

    # A colorizer that cycles through colors to create a striped effect
    class StripeColorizer
      include Yummi::Colorizer

      # Creates a new colorizer using the given colors
      def initialize (*colors)
        @colors = colors
        @count = -1
      end

      def call *args
        @count += 1
        @colors[@count % @colors.size]
      end

    end

    #
    # A colorizer that evaluates a main block and returns a color based on other blocks.
    #
    # The main block must be compatible with the colorizing type (receiving a column
    # value in case of a table column colorizer or the row index and row value in case
    # of a table row colorizer).
    #
    # === Example
    #
    #   # assuming that the table has :max and :current aliases
    #   colorizer = DataEvalColorizer::new { |index, data| data[:current] / data[:max] }
    #   # the result of the expression above will be passed to this block
    #   colorizer.use(:red) { |value| value >= 0.9 }
    #
    #   table.using_row.colorize :current, :using => colorizer
    #
    class EvalColorizer
      include Yummi::Colorizer

      def initialize (&block)
        @block = block
        @colors = []
        @eval_blocks = []
      end

      #
      # Uses the given color if the given block returns something when evaluated with the
      # result of main block.
      #
      # An objtect that responds to :call may also be used.
      #
      def use (color, component = nil, &eval_block)
        @colors << color
        @eval_blocks << (component or eval_block)
      end

      # Resolves the value using the main block and given arguments
      def resolve_value (*args)
        @block.call *args
      end

      def call (*args)
        value = resolve_value *args
        @eval_blocks.each_index do |i|
          return @colors[i] if @eval_blocks[i].call(value)
        end
        nil
      end

    end

    #
    # A colorizer that evaluates a main block and returns a color based on other blocks.
    #
    # The main block can receive any parameters and the names must be aliases the current
    # evaluated data.
    #
    # === Example
    #
    #   # assuming that the table has :max and :current aliases
    #   colorizer = DataEvalColorizer::new { |max, current| current / max }
    #   # the result of the expression above will be passed to this block
    #   colorizer.use(:red) { |value| value >= 0.9 }
    #
    #   table.using_row.colorize :current, :using => colorizer
    #
    class DataEvalColorizer < EvalColorizer
      include Yummi::BlockHandler, Yummi::Colorizer

      def resolve_value (*args)
        block_call args.first, &@block # by convention, the first arg is data
      end

    end

  end

  # A module used to create an alias method in a formatter block
  module FormatterBlock

    # Calls the :call: method
    def format (value)
      call value
    end

  end

  # Extends the given block with #FormatterBlock
  def self.to_format &block
    block.extend FormatterBlock
  end

  # A module with useful formatters
  module Formatters

    # A formatter for boolean values that uses 'Yes' or 'No'
    def self.yes_or_no
      Yummi::to_format do |value|
        value ? "Yes" : "No"
      end
    end

    # A formatter to float values that uses the precision to round the value
    def self.round precision
      Yummi::to_format do |value|
        "%.#{precision}f" % value
      end
    end

    # Defines the modes to format a byte value
    BYTE_MODES = {
      :iec => {
        :range => %w{B KiB MiB GiB TiB PiB EiB ZiB YiB},
        :step => 1024
      },
      :si => {
        :range => %w{B KB MB GB TB PB EB ZB YB},
        :step => 1000
      }
    }

    #
    # Formats a byte value to ensure easily reading
    #
    # === Hash Args
    #
    # +precision+::
    #   How many decimal digits should be displayed. (Defaults to 1)
    # +mode+::
    #   Which mode should be used to display unit symbols. (Defaults to :iec)
    #
    # See #BYTE_MODES
    #
    def self.byte params = {}
      Yummi::to_format do |value|
        value = value.to_i if value.is_a? String
        mode = (params[:mode] or :iec)
        range = BYTE_MODES[mode][:range]
        step = BYTE_MODES[mode][:step]
        params[:precision] ||= 1
        result = value
        range.each_index do |i|
          minimun = (step ** i)
          result = "%.#{params[:precision]}f #{range[i]}" % (value.to_f / minimun) if value >= minimun
        end
        result
      end
    end

  end

  # A class to expose indexed data by numeric indexes and aliases.
  class IndexedData

    def initialize (aliases, data)
      @aliases = aliases
      @data = data
    end

    def [](value)
      if value.is_a? Fixnum
        @data[value]
      else
        @data[@aliases.index(value)]
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

end

require_relative 'yummi/no_colors' if RUBY_PLATFORM['mingw'] #Windows

require_relative 'yummi/color_mapping'
require_relative 'yummi/table'
require_relative 'yummi/text_box'
require_relative 'yummi/logger'
