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
require_relative 'cash_flow_table_extensions.rb'

opt = OptionParser::new

tablebuilder = Yummi::TableBuilder::new('cash_flow_table.yaml')

@table = tablebuilder.defaults.build_table

@table.data = [['Initial', nil, 0, nil, nil],
               ['Deposit', 100.58, 100.58, true, "QAWSEDRFTGH535"],
               ['Withdraw', -50.23, 50.35, true, "34ERDTF6GYU"],
               ['Withdraw', -100, -49.65, true, "2344EDRFT5"],
               ['Deposit', 50, 0.35, false, nil],
               ['Deposit', 600, 600.35, false, nil],
               ['Total', nil, 600.35, nil, nil]]

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

if @box
  @box << @table
  @box.print
else
  @table.print
end
