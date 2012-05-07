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
@table.header = ['Server Name', 'Max Memory', 'Free Memory', "Max Threads", "In Use Threads"]
# sets the title
@table.title = 'Server Runtime Info'
# formats memory info for easily reading
@table.format :max_memory, :using => Yummi::Formatter.unit(:byte)
@table.format :free_memory, :using => Yummi::Formatter.unit(:byte)

# colorizer for memory
memory_colorizer = Yummi::Colorizer.by_data_eval do |free_memory, max_memory|
  free_memory.to_f / max_memory
end
memory_colorizer.use(:red) { |value| value > 0.1 and value < 0.3 }
memory_colorizer.use(:intense_red) { |value| value <= 0.1 }

# colorizer for threads
thread_colorizer = Yummi::Colorizer.by_data_eval do |max_threads, in_use_threads|
  in_use_threads.to_f / max_threads
end
thread_colorizer.use(:brown) { |value| value > 0.7 and value < 0.9 }
thread_colorizer.use(:intense_cyan) { |value| value >= 0.9 }

opt.on '--color TYPE', 'Specify the color type (zebra,row,cell,none)' do |type|
  case type
    when 'zebra'
      @table.row_colorizer Yummi::Colorizer.stripe :brown, :purple
    when 'row'
      @table.row_colorizer memory_colorizer
      @table.row_colorizer thread_colorizer
    when 'cell'
      @table.using_row do
        @table.colorize :free_memory, :using => memory_colorizer
        @table.colorize :in_use_threads, :using => thread_colorizer
      end
    when 'none'
      @table.no_colors
    else
  end
end
opt.on '--layout LAYOUT', 'Defines the table layout (horizontal or vertical)' do |layout|
  case layout
    when 'horizonta'
      @table.layout = :horizontal
    when 'vertical'
      @table.layout = :vertical
    else
  end
end
opt.on '--help', 'Prints this message' do
  puts opt
  exit 0
end

opt.parse ARGV

# sets the table data
@table.data = [
  ['Server 1', 1_000_000, 750_000, 200, 170],
  ['Server 2', 1_000_000, 700_000, 200, 180],
  ['Server 3', 1_000_000, 50_000, 200, 50],
  ['Server 4', 1_000_000, 200_000, 200, 50],
  ['Server 5', 1_000_000, 5_000, 200, 50],
  ['Server 6', 1_000_000, 750_000, 200, 50],
  ['Server 6', 1_000_000, 200_000, 200, 170],
  ['Server 6', 1_000_000, 5_000, 200, 180],
]

@table.print
