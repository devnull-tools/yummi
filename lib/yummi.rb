require_relative "yummi/version"
require_relative "yummi/table"

module Yummi

  module Color
    COLORS = {
      :nothing => '0;0',
      :black => '0;30',
      :red => '0;31',
      :green => '0;32',
      :brown => '0;33',
      :blue => '0;34',
      :cyan => '0;36',
      :purple => '0;35',
      :light_gray => '0;37',
      :dark_gray => '1;30',
      :light_red => '1;31',
      :light_green => '1;32',
      :yellow => '1;33',
      :light_blue => '1;34',
      :light_cyan => '1;36',
      :light_purple => '1;35',
      :white => '1;37',
    }

    def self.escape(key)
      COLORS.key?(key) and "\033[#{COLORS[key]}m"
    end

    def self.colorize(str, color)
      col, nocol = [color, :nothing].map { |key| Color.escape(key) }
      col ? "#{col}#{str}#{nocol}" : str
    end

  end

  module Aligner

    def self.right text, width
      text.rjust(width)
    end

    def self.left text, width
      text.ljust(width)
    end

  end

  module RowColorizer

    def self.if first, operation, second, params
      lambda do |row|
        params[:with] if row[first].send operation, row[second]
      end
    end

    def self.unless first, operation, second, params
      lambda do |row|
        params[:with] unless row[first].send operation, row[second]
      end
    end

    def self.case *args
      lambda do |value|
        color = nil
        args.each do |arg|
          _color = self.if(*arg).call(value)
          color = _color if _color
        end
        color
      end
    end

  end

  module Colorizer

    def self.if operation, argument, params
      lambda do |value|
        params[:with] if value.send operation, argument
      end
    end

    def self.unless operation, argument, params
      lambda do |value|
        params[:with] unless value.send operation, argument
      end
    end

    def self.case *args
      lambda do |value|
        color = nil
        args.each do |arg|
          _color = self.if(*arg).call(value)
          color = _color if _color
        end
        color
      end
    end

  end

  module Formatter

    def self.yes_or_no
      lambda do |value|
        value ? "Yes" : "No"
      end
    end

  end

end
