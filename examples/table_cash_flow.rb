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

require_relative '../lib/yummi'

table = Yummi::Table::new
# run with --no-color for printing the data without colors
table.no_colors if ARGV[0] == '--no-color'
# setting the header sets the aliases automaically
table.header = ['Description', 'Value', 'Total', 'Eletronic']
# sets the title
table.title = 'Cash Flow'
# aligns the first column to the left
table.align :description, :left
# colorize all values from the Description column to purple
table.colorize :description, :with => :purple
# colorize booleans based on their values
table.colorize :eletronic, :using => Yummi::Colorizer.case(
  [:==, true, :with => :blue],
  [:==, false, :with => :cyan]
)
# colorize the values based on comparison
colorizer = Yummi::Colorizer.case(
  [:<, 0, :with => :red],
  [:>, 0, :with => :green],
  [:==, 0, :with => :brown]
)
table.colorize :value, :using => colorizer
table.colorize :total, :using => colorizer
# colorize rows that Value is greather than Total
table.row_colorizer Yummi::RowColorizer.if(:value, :>, :total, :with => :white)
# formats booleans using Yes or No
table.format :eletronic, :using => Yummi::Formatter.yes_or_no
# shows values without minus signal and rounded
table.format :value, :using => lambda { |value| "%.2f" % value.abs }
# shows totals rounded
table.format :total, :with => "%.2f"
# table data
table.data = [['Initial', 0, 0, false],
              ['Deposit', 100, 100, true],
              ['Withdraw', -50, 50, true],
              ['Withdraw', -100, -50, true],
              ['Deposit', 50, 0, false],
              ['Deposit', 600, 600, false]]

table.print
