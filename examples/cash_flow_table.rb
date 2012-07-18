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

require 'optparse'
require_relative '../lib/yummi'

opt = OptionParser::new

@table = Yummi::Table::new
# setting the header sets the aliases automatically
@table.header = ['Description', 'Value', 'Total', 'Eletronic', "Authentication\nCode"]
# sets the title
@table.title = 'Cash Flow'
@table.description = 'How you spend your money'
# formats booleans using Yes or No
@table.format :eletronic, :using => Yummi::Formatters.yes_or_no
# shows values without minus signal and rounded
@table.format :value, :using => lambda { |value| "%.2f" % value.abs }
# shows totals rounded
@table.format :total, :using => Yummi::Formatters.round(2)
@table.format_null :with => 'none'
# table data
@table.data = [['Initial', 0, 0, false, nil],
               ['Deposit', 100.58, 100.58, true, "QAWSEDRFTGH535"],
               ['Withdraw', -50.23, 50.35, true, "34ERDTF6GYU"],
               ['Withdraw', -100, -49.65, true, "2344EDRFT5"],
               ['Deposit', 50, 0.35, false, nil],
               ['Deposit', 600, 600.35, false, nil]]

def full_colors
  @table.colorize :description, :with => :purple
  # Authentication Code will be highlighted
  @table.colorize :authentication_code, :with => :highlight_gray
  # colorize booleans based on their values
  @table.colorize :eletronic do |b|
    b ? :blue : :cyan
  end
  # colorize the values based on comparison
  red_to_negative = lambda { |value| :red if value < 0 }
  green_to_positive = lambda { |value| :green if value > 0 }
  brown_to_zero = lambda { |value| :brown if value == 0 }
  @table.colorize [:value, :total], :using => Yummi::Colorizers.join(
    red_to_negative, green_to_positive, brown_to_zero
  )
  # colorize rows that Value is greater than Total
  @table.row_colorizer do |data| # or |data, index| if you need the index
    :white if data[:value] > data[:total]
  end
  @table.colorize_null :with => :red
end

def zebra_colors
  @table.row_colorizer Yummi::Colorizers.stripe :brown, :purple
end

def no_colors
  @table.no_colors
end

opt.on '--color TYPE', 'Specify the color type (zebra,full,none)' do |type|
  case type
    when 'zebra'
      zebra_colors
    when 'full'
      # colorize all values from the Description column to purple
      full_colors
    when 'none'
      no_colors
    else
  end
  @colors = type
end

opt.on '--layout LAYOUT', 'Defines the table layout (horizontal or vertical)' do |layout|
  @table.layout = layout.to_sym
end

opt.on '--box', 'Prints the table inside a box' do
  @box = Yummi::TextBox::new
end
opt.on '--help', 'Prints this message' do
  puts opt
  exit 0
end

opt.parse ARGV

full_colors unless @colors

if @box
  @box << @table
  @box.print
else
  @table.print
end
