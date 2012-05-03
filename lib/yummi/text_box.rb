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

  # A box to decorate texts
  class TextBox
    # The border color
    attr_accessor :color
    # The box content
    attr_accessor :content

    def initialize params = {}
      params = {
        :color => :white,
        :content => ''
      }.merge! params
      @color = params[:color]
      @content = params[:content].to_s
    end

    # Adds a content to this box
    def add obj
      content << obj.to_s
    end

    alias_method :<<, :add

    # Adds a line text to this box
    def line line_text, params = {}
      line_text.each_line do |line|
        line = line.chomp
        add Yummi.colorize line, params[:color]
        add $/
      end
    end

    #
    # Prints the #to_s into the given object.
    #
    def print to = $stdout
      to.print to_s
    end

    def to_s
      width = 0
      sizes = []
      content.each_line do |line|
        size = (Yummi::Color::raw line.chomp).size
        sizes << size
        width = [width, size].max
      end
      border = Yummi.colorize('+' + ('-' * width) + '+', color) + $/
      pipe = Yummi.colorize '|', color
      buff = ''
      buff << border
      i = 0
      content.each_line do |line|
        diff = width - sizes[i]
        buff << pipe << line.chomp << (' ' * diff) << pipe << $/
        i += 1
      end
      buff << border
      buff
    end

  end

end
