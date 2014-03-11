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
    # A context or a value.
    #
    def colorize (arg)
      arg = Yummi::Context::new(arg) unless arg.is_a? Context
      Yummi.colorize arg.value.to_s, color_for(arg)
    end

    #
    # Returns the color for the given value
    #
    # === Args
    #
    # A context or a value.
    # 
    def color_for (arg)
      arg = Yummi::Context::new(arg) unless arg.is_a? Context
      call(arg)
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

    # Returns a new instance of #StripeColorizer
    def self.stripe *colors
      StripeColorizer::new(*colors)
    end

    # Returns a new instance of #PatternColorizer
    def self.pattern mappings, level = nil
      colorizer = PatternColorizer::new(mappings)
      colorizer.level = level if level
      colorizer
    end

    #
    # A colorizer that uses the given color.
    #
    def self.with color
      Yummi::to_colorize do |ctx|
        color
      end
    end

    def self.when params
      Yummi::to_colorize do |ctx|
        value = ctx.value
        color = params[value]
        return color if color
        if value.respond_to? :to_sym
          color = params[value.to_sym]
        end
        unless color
          params.each do |k, v|
            return v if k.to_s == value.to_s
          end
        end
        color
      end
    end

    #
    # A colorizer for boolean values.
    #
    # Parameters:
    #   - if_true: color used if the value is true (defaults to green)
    #   - if_false: color used if the value is false (defaults to yellow)
    #
    def self.boolean params = {}
      Yummi::to_colorize do |ctx|
        value = ctx.value
        if value.to_s.downcase == "true"
          (params[:if_true] or :green)
        else
          (params[:if_false] or :yellow)
        end
      end
    end
    
    #
    # A colorizer that uses a set of minimun values to use a color.
    #
    # Parameters:
    #   - MINIMUN_VALUE: COLOR_TO_USE
    #
    def self.threshold params
      params = params.dup
      mode = (params.delete(:mode) or :min)
      colorizer = lambda do |ctx|
        value = ctx.value
        case mode.to_sym
        when :min
          params.sort.reverse_each do |limit, color|
            return color if value >= limit
          end
        when :max
          params.sort.each do |limit, color|
            return color if value <= limit
          end
        end
        nil
      end
      Yummi::to_colorize(&colorizer)
    end

    def self.percentage params
      PercentageColorizer::new params
    end

    #
    # A colorizer for numeric values
    #
    # === Hash Args
    #
    # :negative => color to use when value is negative
    # :zero => color to use when value is zero
    # :positive => color to use when value is positive
    # :any => color to use for any value (overridable by the options above)
    #
    def self.numeric params
      Yummi::to_format do |ctx|
        value = ctx.value
        negative = (params[:negative] or params[:any])
        positive = (params[:positive] or params[:any])
        zero = (params[:zero] or params[:any])
        if negative and value < 0
          negative
        elsif positive and value > 0
          positive
        elsif zero and value == 0
          zero
        end
      end
    end

    class PercentageColorizer
      include Yummi::Colorizer

      def initialize(params)
        @max = params[:max].to_sym
        @free = params[:free]
        @using = params[:using]
        color = {
          :bad => :red,
          :warn => :yellow,
          :good => :green
        }.merge!(params[:colors] || {})
        threshold = {
          :warn => 0.30,
          :bad => 0.15,
          :good => 1
        }.merge!(params[:threshold] || {})

        threshold_params = { :mode => :max }
        color.each do |type, name|
          threshold_params[threshold[type]] = name
        end
        @threshold = Yummi::Colorizers.threshold threshold_params
      end

      def call(data)
        max = data[@max].to_f
        free = @using ? max - data[@using.to_sym].to_f : data[@free.to_sym].to_f

        percentage = free / max

        @threshold.color_for(percentage)
      end

    end

    #
    # A colorizer for strings that follows a pattern. This colorizer is usefull
    # for log files.
    #
    class PatternColorizer
      include Yummi::Colorizer

      attr_writer :level

      def initialize mappings = nil
        @patterns = []
        map mappings if mappings
      end

      #
      # Maps a set of patterns to colors.
      #
      # === Args
      #
      # A hash containing the following keys:
      #
      #   * prefix: a pattern prefix
      #   * suffix: a pattern suffix
      #   * options: option flags to use
      #   * mode: the mode to use:
      #       - all  : colorize the entire text
      #       - grep : colorize only the matched text
      #   * patterns: a pattern => color hash
      #
      # If a string is passed instead of a hash, a file containing a
      # YAML configuration will be loaded. If the string doesn't represent
      # a file, the following patterns will be used to find it:
      # 
      #   * $HOME/.yummi/patterns/PATTERN.yaml
      #   * $YUMMI_GEM/yummy/patterns/PATTERN.yaml
      #
      def map params
        if params.is_a? Array
          params.each { |p| map p }
        elsif params.is_a? String or params.is_a? Symbol
          map Yummi::Helpers::load_resource(params, :from => :patterns)
        else
          config params
        end
      end

      def call ctx
        ctx = Yummi::Context::new(ctx) unless ctx.is_a? Context
        text = ctx.value.to_s
        @patterns.each do |config|
          level = -1
          config[:patterns].each do |regex, color|
            level += 1
            return if @level and level > @level and not @last_color
            if regex.match(text)
              return match(text, config)
            end
          end
        end
        return text.colorize(@last_color) if @last_color
        text
      end

      alias :colorize :call

      private 

      def config params
        Yummi::Helpers.symbolize_keys(params)
        prefix  = params[:prefix]
        suffix  = params[:suffix]
        options = params[:options]
        mode    = (params[:mode] or :all)

        patterns = Hash[*(params[:patterns].collect do |pattern, color|
          [
            Regexp::new("#{prefix}#{pattern.to_s}#{suffix}",options),
            color
          ]
        end).flatten]

        @patterns << {
          :mode => mode,
          :patterns => patterns
        }
      end

      def match(text, config)
        send "colorize_#{config[:mode]}", text, config
      end

      def colorize_all(text, match)
        match[:patterns].each do |regex, color|
          if regex.match(text)
            @last_color = color
            return text.colorize(color)
          end
        end
        text
      end

      def colorize_grep(text, match)
        return text unless match
        @last_color = nil
        match[:patterns].each do |regex, color|
          text = text.colorize regex => color
        end
        text
      end

    end

    # A colorizer that cycles through colors to create a striped effect
    class StripeColorizer
      include Yummi::Colorizer

      # Creates a new colorizer using the given colors
      def initialize (*colors)
        @colors = colors.flatten
        @colors = [nil] if @colors.empty?
        @count = -1
      end

      def call *args
        @count += 1
        @colors[@count % @colors.size]
      end

    end

  end

end