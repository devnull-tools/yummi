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
  # A Table that supports colorizing title, header, values and also formatting the values.
  class Table
    # The table data. It holds a two dimensional array.
    attr_accessor :data
    # The table title
    attr_accessor :title
    # Default align. Yummi::Aligner should respond to it.
    attr_accessor :default_align
    # Aliases that can be used by formatters and colorizers instead of numeric indexes.
    # The aliases are directed mapped to their respective index in this array
    attr_accessor :aliases
    # The table colspan
    attr_accessor :colspan
    # The table colors. This Map should have colors for the following elements:
    #
    # * Title: using :title key
    # * Header: using :header key
    # * Values: using :value key
    #
    # The colors must be supported by Yummi::Color::parse or defined in Yummi::Color::COLORS
    attr_accessor :colors
    # Creates a new table with the default attributes:
    #
    # * Title color: intense_yellow
    # * Header color: intense_blue
    # * Values color: none
    # * Colspan: 2
    # * Default Align: right and first element to left
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

      @align = [:left]
      @formatters = []
      @colorizers = []
      @row_colorizer = nil

      @default_align = :right
    end
    # Indicates that the table should not use colors.
    def no_colors
      @colors = {
        :title => nil,
        :header => nil,
        :value => nil
      }
      @no_colors = true
    end
    #
    # === Description
    #
    # Sets the table header. If no aliases are defined, they will be defined as the texts
    # in lowercase with line breaks and spaces replaced by underscores.
    #
    # === Args
    #
    # +header+::
    #   Array containing the texts for displaying the header. Line breaks are supported
    #
    # === Examples
    #
    #   table.header = ['Name', 'Email', 'Work Phone', "Home\nPhone"]
    #
    # This will create the following aliases: :name, :email, :work_phone and :home_phone
    #
    def header= header
      max = 0
      header.each_index do |i|
        max = [max, header[i].split("\n").size].max
      end
      @header = []
      max.times { @header << [] }
      header.each_index do |i|
        names = header[i].split("\n")
        names.each_index do |j|
          @header[j][i] = names[j]
        end
      end
      @aliases = header.map { |n| n.downcase.gsub(' ', '_').gsub("\n", '_').to_sym } if @aliases.empty?
    end
    #
    # === Description
    #
    # Sets the align for a column in the table. Yummi::Aligner should respond to it.
    #
    # === Args
    #
    # +index+::
    #   The column index or its alias
    #
    def align index, type
      index = parse_index(index)
      @align[index] = type
    end

    def row_colorizer colorizer = nil, &block
      @row_colorizer ||= Yummi::LinkedBlocks::new
      @row_colorizer << (colorizer or block)
    end

    def using_row
      @using_row = true
      self
    end

    def using_cell
      @using_row = true
      self
    end

    def colorize index, params = {}, &block
      index = parse_index(index)
      obj = (params[:using] or block or (proc { |v| params[:with] }))
      @colorizers[index] = {:use_row => @using_row, :component => obj}
      @using_row = false
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

      @header.each do |line|
        _colors = []
        _data = []
        line.each do |h|
          _colors << @colors[:header]
          _data << h
        end
        color_map << _colors
        output << _data
      end

      @data.each_index do |row_index|
        row = @data[row_index]
        _colors = []
        _data = []

        row.each_index do |col_index|
          next if @header and @header[0].size < col_index + 1
          column = row[col_index]
          colorizer = @colorizers[col_index]
          if colorizer
            arg = colorizer[:use_row] ? IndexedData::new(@aliases, row) : column
            _colors << colorizer[:component].call(arg)
          else
            _colors << @colors[:value]
          end
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
