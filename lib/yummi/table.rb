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

  class Table

    attr_accessor :data, :header, :title, :default_align, :aliases, :colspan, :colors

    def initialize
      @data = []
      @header = []
      @title = nil
      @colors = {
        :title => :intense_yellow,
        :header => :intense_blue,
        :value => nil
      }

      @colspan = 2

      @aliases = []

      @align = {}
      @formatters = []
      @colorizers = []
      @row_colorizer = nil

      @default_align = :right

      @max_width = []
    end

    def no_colors
      @colors = {
        :title => nil,
        :header => nil,
        :value => nil
      }
      @no_colors = true
    end

    def header= header
      @aliases = header.map { |n| n.downcase.gsub(' ', '_').to_sym } if @aliases.empty?
      @header = header
    end

    def align index, type
      index = parse_index(index)
      @align[index] = type
    end

    def row_colorizer colorizer = nil, &block
      @row_colorizer ||= Yummi::LinkedBlocks::new
      @row_colorizer << (colorizer or block)
    end

    def colorize index, params = {}, &block
      index = parse_index(index)
      @colorizers[index] = (params[:using] or block)
      @colorizers[index] ||= proc do |value|
        params[:with]
      end
    end

    def format index, params = {}, &block
      index = parse_index(index)
      @formatters[index] = (params[:using] or block)
      @formatters[index] ||= proc do |value|
        params[:with] % value
      end
    end

    def print to = $stdout
      to.print to_s
    end

    def to_s
      color_map, output = build_output
      string = ""
      string << Color.colorize(@title, @colors[:title]) << $/ if @title
      output.each_index do |i|
        row = output[i]
        row.each_index do |j|
          column = row[j]
          width = max_width output, j
          align = (@align[j] or @default_align)
          color = color_map[i][j]
          value = Aligner.send align, column.to_s, width
          value = Color.colorize value, color unless @no_colors
          string << value
          string << (" " * @colspan)
        end
        string.strip! << $/
      end
      string
    end

    private

    def build_output
      color_map = []
      output = []

      _colors = []
      _data = []

      @header.each do |h|
        _colors << @colors[:header]
        _data << h
      end
      color_map << _colors
      output << _data

      @data.each_index do |row_index|
        row = @data[row_index]
        _colors = []
        _data = []

        row.each_index do |col_index|
          column = row[col_index]
          colorizer = @colorizers[col_index]
          _colors << (colorizer ? colorizer.call(column) : @colors[:value])

          formatter = @formatters[col_index]
          _data << (formatter ? formatter.call(column) : column)
        end
        if @row_colorizer
          row_data = IndexedData::new @aliases, row
          row_color = @row_colorizer.call row_index, row_data
          _colors.collect! { row_color } if row_color
        end
        color_map << _colors
        output << _data
      end

      [color_map, output]
    end

    def parse_index(value)
      return @aliases.index(value) unless value.is_a? Fixnum
      value
    end

    def max_width data, column
      max = 0
      data.each do |row|
        max = [row[column].to_s.length, max].max
      end
      max
    end

  end

end
