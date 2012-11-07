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

require 'ostruct'

module Yummi

  # A box to decorate texts
  class TextBox
    # The box content
    attr_accessor :content
    #
    # Holds the style information for this box. Supported properties are:
    # 
    # width: the box width (default: none)
    # align: the default alignment to use (default: left)
    # separator: the style for separators, defined as a hash
    #   color: separator color (default: none)
    #   pattern: separator pattern (default: '-')
    #   width: separator width (default: box width)
    # 
    attr_reader :style    

    def initialize
      @color = :white
      @content = []
      @style = OpenStruct::new
      @style.separator = {}
      @style.separator[:pattern] = '-'
      @style.separator[:width] = nil
      @style.separator[:align] = :left

      @style.border = {}
      @style.border[:color] = nil
      @style.border[:top] = '-'
      @style.border[:bottom] = '-'
      @style.border[:left] = '|'
      @style.border[:right] = '|'
      @style.border[:top_left] = '+'
      @style.border[:top_right] = '+'
      @style.border[:bottom_left] = '+'
      @style.border[:bottom_right] = '+'
    end

    def no_border
      @style.border = nil
    end

    #
    # Adds a line text to this box
    #
    # === Args
    #
    # +line_text+::
    #   The text to add.
    # +params+::
    #   A hash of parameters. Currently supported are:
    #     color: the text color (see #Yummi#COLORS)
    #     width: the text maximum width. Set this to break the lines automatically.
    #            If the #width is set, this will override the box width for this lines.
    #     align: the text alignment (see #Yummi#Aligner)
    #
    def add (text, params = {})
      params = {
        :width => style.width,
        :align => style.align
      }.merge! params
      if params[:width]
        width = params[:width]
        words = text.gsub($/, ' ').split(' ')
        buff = ''
        words.each do |word|
          # go to next line if the current word blows up the width limit
          if buff.size + word.size >= width and not buff.empty?
            _add_ buff, params
            buff = ''
          end
          buff << ' ' unless buff.empty?
          buff << word
        end
        unless buff.empty?
          _add_ buff, params
        end
      else
        text.each_line do |line|
          _add_ line, params
        end
      end
    end

    # Adds the given object as it
    def << (object)
      text = object.to_s
      text.each_line do |line|
        add line
      end
    end

    #
    # Adds a line separator.
    #
    # === Args
    #
    # +params+::
    #   A hash of parameters. Currently supported are:
    #     pattern: the pattern to build the line
    #     color: the separator color (see #Yummi#COLORS)
    #     width: the separator width (#self#width will be used if unset)
    #     align: the separator alignment (see #Yummi#Aligner)
    #
    def separator (params = {})
      params = style.separator.merge! params
      params[:width] ||= style.width
      raise Exception::new("Define a width for using separators") unless params[:width]
      line = fill(params[:pattern], params[:width])
      #replace the width with the box width to align the separator
      params[:width] = style.width
      add line, params
    end

    # Adds a line break to the text.
    def line_break
      @content << $/
    end

    # Prints the #to_s into the given object.
    def print (to = $stdout)
      to.print to_s
    end

    def to_s
      width = 0
      sizes = []
      content.each do |line|
        size = (Yummi::Color::raw line.chomp).size
        sizes << size
        width = [width, size].max
      end
      left = [''] * content.size
      right = [''] * content.size
      border = @style.border
      if border
        color = border[:color]
        top = Yummi.colorize(
          border[:top_left] + fill(border[:top], width) + border[:top_right],
          color
        ) + $/
        left = fill(border[:left], content.size).split(//).collect do |c|
          Yummi.colorize(c, color)
        end
        right = fill(border[:right], content.size).split(//).collect do |c|
          Yummi.colorize(c, color)
        end
        bottom = Yummi.colorize(
          border[:bottom_left] + fill(border[:bottom], width) + border[:bottom_right],
          color
        ) + $/
      end
      buff = ''
      buff << top if border
      i = 0
      content.each do |line|
        diff = width - sizes[i]
        buff << left.shift.to_s << line.chomp << (' ' * diff) << right.shift.to_s << $/
        i += 1
      end
      buff << bottom if border
      buff
    end

    private

    def _add_ (text, params)
      if params[:align] and params[:width]
        text = Yummi::Aligner.align params[:align], text, params[:width]
      end
      @content << Yummi.colorize(truncate(text), params[:color])
    end

    def truncate text, width = style.width
      return text[0...width] if width
      text
    end

    def fill text, width = style.width
      width = [width, style.width].min if style.width
      truncate text * width, width
    end

  end

end
