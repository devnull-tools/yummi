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

require 'yaml'

module Yummi
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
      Yummi.colorize args.first.to_s, color_for(args)
    end

    #
    # Returns the color for the given value
    #
    # === Args
    #
    # An array of arguments that will be passed to :call: method to get the color. By
    # convention, the first argument must be the object to colorize (to_s is called on it
    # for getting the text to colorize).#
    def color_for (*args)
      call *args
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
      DataEvalColorizer::new(&block)
    end

    # Returns a new instance of #EvalColorizer
    def self.by_eval &block
      EvalColorizer::new(&block)
    end

    # Returns a new instance of #StripeColorizer
    def self.stripe *colors
      StripeColorizer::new(*colors)
    end

    # Returns a new instance of #LineColorizer
    def self.line mappings
      LineColorizer::new mappings
    end

    #
    # A colorizer for lines that follows a pattern. This colorizer is usefull
    # for log files.
    #
    class LineColorizer
      include Yummi::Colorizer

      #
      # Creates a new instance using the parameters.
      #
      # === Args
      #
      # A hash containing the following keys:
      #
      #   * prefix: a pattern prefix
      #   * suffix: a pattern suffix
      #   * patterns: a pattern => color hash
      #
      # If a string is passed, a file containing a YAML configuration
      # will be loaded. If the string doesn't represent a file, the
      # following patterns will be used to find it:
      # 
      #   * $HOME/.yummi/PATTERN.yaml
      #   * $YUMMI_GEM/yummy/mappings/PATTERN.yaml
      #
      def initialize params
        unless params.is_a? Hash
          file = File.expand_path params.to_s
          if File.exist? file
            params = YAML::load_file file
          else
            ['~/.yummi', File.join(File.dirname(__FILE__), 'mappings')].each do |path|
              file = File.join(path, "#{params}.yaml")
              if File.exist? file
                params = YAML::load_file file
                break
              end
            end
          end
        end
        patterns = (params[:patterns] or params['patterns'])
        prefix = (params[:prefix] or params['prefix'])
        suffix = (params[:suffix] or params['suffix'])
        @patterns = Hash[*(patterns.collect do |pattern, color|
          [/#{prefix}#{pattern.to_s}#{suffix}/, color]
        end).flatten]

        @last_color = nil
      end

      def call *args
        line = args.first.to_s
        @patterns.each do |regex, color|
          if regex.match(line)
            @last_color = color
            return color
          end
        end
        @last_color
      end

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

end