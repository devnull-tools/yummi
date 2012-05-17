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
require_relative "yummi/text_box"
require_relative "yummi/logger"

module Yummi
  # Base for colorizing
  module Color
    # Colors from default linux terminal scheme
    COLORS = {
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
    def self.parse key
      keys = key.to_s.split '_'
      type = keys[0].to_sym
      color = keys[1].to_i
      "#{TYPES[type]};3#{color - 1}"
    end

    # Escape the given text with the given color code
    def self.escape key
      return key unless key
      color = (COLORS[key] or key)
      color ||= parse(key)
      "\033[#{color}m"
    end

    # Colorize the given text with the given color
    def self.colorize string, color
      color, end_color = [color, '0;0'].map { |key| Color.escape(key) }
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
    def colorize *args
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
      def initialize *colors
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
      include Yummi::BlockHandler, Yummi::Colorizer

      def resolve_value *args
        block_call args.last, &@block # by convention, the last arg is data
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

  # A class to expose indexed data by numeric indexes and aliases.
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
    def initialize params = {}
      @components = []
      @call_all = params[:call_all]
      @message = (params[:message] or :call)
    end

    # Adds a new component
    def << component = nil, &block
      @components << (component or block)
    end

    #
    # Calls the added components by sending the configured message and the given args.
    #
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
