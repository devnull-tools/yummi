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

require 'logger'

module Yummi

  module Formatter

    #
    # A colorful log formatter
    #
    class LogFormatter < Logger::Formatter
      include Yummi::BlockHandler
      #
      # Colors for each severity:
      #
      # * :debug
      # * :info
      # * :warn
      # * :error
      # * :fatal
      # * :any
      #
      attr_accessor :colors

      #
      # Creates a new formatter with the colors (assuming Linux default terminal colors):
      #
      # * +DEBUG+: no color
      # * +INFO+: green
      # * +WARN+: brown
      # * +ERROR+: red
      # * +FATAL+: red (intense)
      # * +ANY+: gray (intense)
      #
      # If a block is passed, it will be used to format the message
      #
      def initialize &block
        @colors = {
          :debug => nil,
          :info => :green,
          :warn => :brown,
          :error => :red,
          :fatal => :intense_red,
          :any => :intense_gray
        }
        @format_block = block
      end

      alias_method :super_call, :call

      def call(severity, time, program_name, message)
        color = @colors[severity.downcase.to_sym]
        Yummi::Color.colorize output(severity, time, program_name, message), color
      end

      # Formats the message, override this method instead of #call
      def output severity, time, program_name, message
        if @format_block
          context = {
            :severity => severity,
            :time => time,
            :program_name => program_name,
            :message => message
          }
          block_call(context, &@format_block) << $/
        else
          super_call severity, time, program_name, message
        end
      end

    end

  end

end
