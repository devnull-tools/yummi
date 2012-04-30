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
    # Default align. #Yummi#Aligner should respond to it.
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
    # The colors must be supported by #Yummi#Color#parse or defined in #Yummi#Color#COLORS
    attr_accessor :colors
    # The table layout (horizontal or vertical)
    attr_accessor :layout

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
      @layout = :horizontal
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
    # Sets the table header. If no aliases are defined, they will be defined as the texts
    # in lowercase with line breaks and spaces replaced by underscores.
    #
    # Defining headers also limits the printed column to only columns that has a header
    # (even if it is empty).
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
    # Sets the align for a column in the table. #Yummi#Aligner should respond to it.
    #
    # === Args
    #
    # +index+::
    #   The column index or its alias
    # +type+::
    #   The alignment type
    #
    # === Example
    #
    #   table.align :description, :left
    #   table.align :value, :right
    #
    def align index, type
      index = parse_index(index)
      @align[index] = type
    end

    #
    # Adds a component to colorize the entire row (overrides column color).
    # The component must respond to +call+ with the index and the row as the arguments and
    # return a color or +nil+ if default color should be used. A block can also be used.
    #
    # You can add as much colorizers as you want. The first color returned will be used.
    #
    # === Example
    #
    #   table.row_colorizer { |i, row| :red if row[:value] < 0 }
    #
    def row_colorizer colorizer = nil, &block
      @row_colorizer ||= Yummi::GroupedComponent::new
      @row_colorizer << (colorizer or block)
    end

    #
    # Indicates that the column colorizer (#colorize) should receive the entire row as the
    # argument instead of just the column value for all definitions inside of the given
    # block.
    #
    # === Example
    #
    #   table.using_row do
    #     table.colorize(:value) { |row| :red if row[:value] < row[:average] }
    #   end
    #
    def using_row
      @using_row = true
      yield
      @using_row = false
    end

    #
    # Sets a component to colorize a column.
    #
    # The component must respond to +call+ with the column value (or row if used with
    # #using_row) as the arguments and return a color or +nil+ if default color should be
    # used. A block can also be used.
    #
    # You can add as much colorizers as you want. The first color returned will be used.
    #
    # === Args
    #
    # +index+::
    #   The column index or its alias
    # +params+::
    #   A hash with params in case a block is not given:
    #     - :using defines the component to use
    #     - :with defines the color to use (to use the same color for all columns)
    #
    # === Example
    #
    #   table.colorize :description, :with => :purple
    #   table.colorize(:value) { |value| :red if value < 0 }
    #
    def colorize index, params = {}, &block
      index = parse_index(index)
      @colorizers[index] ||= []
      obj = (params[:using] or block or (proc { |v| params[:with] }))
      @colorizers[index] << {:use_row => @using_row, :component => obj}
    end

    #
    # Sets a component to format a column.
    #
    # The component must respond to +call+ with the column value
    # as the arguments and return a color or +nil+ if default color should be used.
    # A block can also be used.
    #
    # === Args
    #
    # +index+::
    #   The column index or its alias
    # +params+::
    #   A hash with params in case a block is not given:
    #     - :using defines the component to use
    #     - :with defines the format to use (to use the same format for all columns)
    #
    # === Example
    #
    #   table.format :value, :with => '%.2f'
    #
    def format index, params = {}, &block
      index = parse_index(index)
      @formatters[index] = (params[:using] or block)
      @formatters[index] ||= proc do |value|
        params[:with] % value
      end
    end

    #
    # Prints the #to_s into the given object.
    #
    def print to = $stdout
      to.print to_s
    end

    #
    # Return a colorized and formatted table.
    #
    def to_s
      header_color_map, header_output = build_header_output
      data_color_map, data_output = build_data_output

      string = ""
      string << Color.colorize(@title, @colors[:title]) << $/ if @title
      color_map = header_color_map + data_color_map
      table_data = header_output + data_output
      if @layout == :vertical
        # don't use array transpose because the data may differ in each line size
        color_map = rotate color_map
        table_data = table_data.transpose
      end
      string << content(color_map, table_data)
    end

    #
    # Gets the content string for the given color map and content
    #
    def content color_map, data
      string = ""
      data.each_index do |i|
        row = data[i]
        row.each_index do |j|
          column = row[j]
          width = max_width data, j
          align = (@align[j] or @default_align)
          color = color_map[i][j]
          value = Aligner.send align, column.to_s, width
          value = Color.colorize value, color unless @no_colors
          string << value
          string << (' ' * @colspan)
        end
        string.strip! << $/
      end
      string
    end

    #
    # Builds the header output for this table.
    #
    # Returns the color map and the header.
    #
    def build_header_output
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
      [color_map, output]
    end

    #
    # Builds the data output for this table.
    #
    # Returns the color map and the formatted data.
    #
    def build_data_output
      color_map = []
      output = []

      @data.each_index do |row_index|
        row = @data[row_index]
        _colors = []
        _data = []

        row.each_index do |col_index|
          next if @header and @header[0].size < col_index + 1
          column = row[col_index]
          colorizers = @colorizers[col_index]
          if colorizers
            colorizers.each do |colorizer|
              arg = colorizer[:use_row] ? IndexedData::new(@aliases, row) : column
              c = colorizer[:component].call(arg)
              if c
                _colors << c
                break
              end
            end
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

    private

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

    def rotate data
      new_data = []
      data.each_index do |i|
        data[i].each_index do |j|
          new_data[j] ||= []
          new_data[j][i] = data[i][j]
        end
      end
      new_data
    end

  end

end
