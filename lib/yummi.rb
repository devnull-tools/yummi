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
require_relative "yummi/table"
require_relative "yummi/logger"

module Yummi
  # Base for colorizing
  module Color
    # Colors from default linux terminal scheme
    COLORS = {
      :nothing => '0;0',

      :black => '0;30',
      :red => '0;31',
      :green => '0;32',
      :brown => '0;33',
      :blue => '0;34',
      :purple => '0;35',
      :cyan => '0;36',
      :gray => '0;37',

      :black_underscored => '4;30',
      :red_underscored => '4;31',
      :green_underscored => '4;32',
      :brown_underscored => '4;33',
      :blue_underscored => '4;34',
      :purple_underscored => '4;35',
      :cyan_underscored => '4;36',
      :gray_underscored => '4;37',

      :blink_black => '5;30',
      :blink_red => '5;31',
      :blink_green => '5;32',
      :blink_brown => '5;33',
      :blink_blue => '5;34',
      :blink_purple => '5;35',
      :blink_cyan => '5;36',
      :blink_gray => '5;37',

      :highlight_black => '7;30',
      :highlight_red => '7;31',
      :highlight_green => '7;32',
      :highlight_brown => '7;33',
      :highlight_blue => '7;34',
      :highlight_purple => '7;35',
      :highlight_cyan => '7;36',
      :highlight_gray => '7;37',

      :intense_gray => '1;30',
      :intense_red => '1;31',
      :intense_green => '1;32',
      :intense_yellow => '1;33',
      :yellow => '1;33',
      :intense_blue => '1;34',
      :intense_purple => '1;35',
      :intense_cyan => '1;36',
      :intense_white => '1;37',
      :white => '1;37'
    }
    # Types of color
    TYPES = {
      :normal => 0,
      :intense => 1,
      :underscored => 4,
      :blink => 5,
      :highlight => 7
    }
    # Parses the key
    def self.parse(key)
      keys = key.to_s.split '_'
      type = keys[0].to_sym
      color = keys[1].to_i
      "#{TYPES[type]};3#{color - 1}"
    end

    # Escape the given text with the given color code
    def self.escape(key)
      return key unless key
      color = COLORS[key]
      color ||= parse(key)
      "\033[#{color}m"
    end

    # Colorize the given text with the given color
    def self.colorize(str, color)
      col, nocol = [color, :nothing].map { |key| Color.escape(key) }
      col ? "#{col}#{str}#{nocol}" : str
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
    def block_call context, &block
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

    # Aligns the text to the right
    def self.right text, width
      text.rjust(width)
    end

    # Aligns the text to the left
    def self.left text, width
      text.ljust(width)
    end

  end

  # A module with useful colorizers
  module Colorizer

    # Joins the given colorizers to work as one
    def self.join *colorizers
      join = Yummi::GroupedComponent::new
      colorizers.each { |c| join << c }
      join
    end

    # Returns a new instance of #DataEvalColorizer
    def self.by_data_eval &block
      DataEvalColorizer::new &block
    end

    # Returns a new instance of #EvalColorizer
    def self.by_eval &block
      EvalColorizer::new &block
    end

    # Returns the #IndexedDataColorizer module
    def self.by_index
      IndexedDataColorizer
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

      def initialize &block
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
      def use color, component = nil, &eval_block
        @colors << color
        @eval_blocks << (component or eval_block)
      end

      # Resolves the value using the main block and given arguments
      def resolve_value *args
        @block.call *args
      end

      def call *args
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
      include Yummi::BlockHandler

      def resolve_value *args
        block_call args.last, &@block # by convention, the last arg is data
      end

    end

    # A module with colorizers that uses indexes
    module IndexedDataColorizer

      # Returns a colorizer that uses the given color in odd indexes
      def self.odd color
        lambda do |index, data|
          color if index.odd?
        end
      end

      # Returns a colorizer that uses the given color in even indexes
      def self.even color
        lambda do |index, data|
          color if index.even?
        end
      end

      # Returns a colorizer that uses the first color for odd indexes and the second for
      # even indexes.
      def self.zebra first_color, second_color
        Yummi::Colorizer.join odd(first_color), even(second_color)
      end

    end

  end

  # A module with useful formatters
  module Formatter

    # A module for formatting units in a way that makes the value easy to read
    module Unit
      # Holds the information about the units that are supported in #format
      UNITS = {
        :byte => {:range => %w{B KB MB GB TB}, :step => 1024}
      }

      #
      # Formats the value using the given unit.
      #
      # === Args
      #
      # +unit+::
      #   A unit defined in #UNITS or a definition
      # +value+::
      #   The value to format
      # +params+::
      #   Additional parameters:
      #   * precision: the number of fractional digits to display (defaults to 1)
      #
      def self.format unit, value, params = {}
        unit = UNITS[unit] if unit.is_a? Symbol
        params[:precision] ||= 1
        result = value
        units = unit[:range]
        units.each_index do |i|
          minimun = (unit[:step] ** i)
          result = "%.#{params[:precision]}f #{units[i]}" % (value.to_f / minimun) if value >= minimun
        end
        result
      end
    end

    # Formats boolean values using 'Yes' or 'No'
    def self.yes_or_no
      lambda do |value|
        value ? "Yes" : "No"
      end
    end

    # Formats a float value by rounding to the given decinal digits
    def self.round precision
      lambda do |value|
        "%.#{precision}f" % value
      end
    end

    # see #Unit#format
    def self.unit unit, params = {}
      lambda do |value|
        Unit.format unit, value, params
      end
    end

  end

  class IndexedData

    def initialize aliases, data
      @aliases = aliases
      @data = data
    end

    def [] value
      if value.is_a? Fixnum
        @data[value]
      else
        @data[@aliases.index(value)]
      end
    end

  end

  class GroupedComponent

    def initialize params = {}
      @components = []
      @call_all = params[:call_all]
      @message = (params[:message] or :call)
    end

    def << component
      @components << component
    end

    def call *args
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
