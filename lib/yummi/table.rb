module Yummi

  class Table

    attr_accessor :data, :header, :title, :default_align, :aliases, :colspan, :colors

    def initialize
      @data = []
      @header = []
      @title = nil
      @colors = {
        :title => :yellow,
        :header => :light_blue,
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

    def header= header
      @aliases = header.map { |n| n.downcase.gsub(' ', '_').to_sym } if @aliases.empty?
      @header = header
    end

    def align index, type
      index = parse_index(index)
      @align[index] = type
    end

    def row_colorizer colorizer = nil, &block
      @row_colorizer = (colorizer or block)
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
          value = Color.colorize value, color
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
          row_data = RowData::new @aliases, row
          row_color = @row_colorizer.call row_data
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

  class RowData

    def initialize aliases, data
      @aliases = aliases
      @data = data
    end

    def [] value
      if value.is_a? Fixnum
        @data[value]
      else
        @data[@aliases.index(value)]
      end
    end

  end

end
