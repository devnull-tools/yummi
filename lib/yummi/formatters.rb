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

module Yummi

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

    #
    # A formatter for boolean values that uses 'Yes' or 'No' by default
    #
    # === Hash Args
    #
    # :if_true => String to use when value is true
    # :if_false => String to use when value is false
    #
    def self.boolean params = {}
      Yummi::to_format do |value|
        if value.to_s.downcase == "true"
          (params[:if_true] or "Yes")
        else 
          (params[:if_false] or "No")
        end
      end
    end

    # A formatter to round float values
    def self.round precision
      Yummi::to_format do |value|
        "%.#{precision}f" % value
      end
    end

    # A formatter that uses the given format
    def self.with format
      Yummi::to_format do |value|
        format % value
      end
    end

    #
    # A formatter for numeric values
    #
    # === Hash Args
    #
    # :negative => format to use when value is negative
    # :zero => format to use when value is zero
    # :positive => format to use when value is positive
    #
    def self.numeric params
      Yummi::to_format do |value|
        if params[:negative] and value < 0
          params[:negative] % value.abs
        elsif params[:positive] and value > 0
          params[:positive] % value
        elsif params[:zero] and value == 0
          params[:zero] % value
        end
      end
    end

    #
    # A formatter for percentual values.
    #
    # Paramters:
    #   The precision to use (defaults to 3)
    #
    def self.percentage precision = 3
      Yummi::to_format do |value|
        "%.#{precision}f%%" % (value * 100)
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
end
