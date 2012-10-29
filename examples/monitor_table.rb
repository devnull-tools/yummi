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
@table.format [:max_memory, :free_memory], :using => Yummi::Formatters.byte

@table.bottom do
  @table.format [:max_memory, :free_memory], :using => Yummi::Formatters.byte
  @table.colorize_row :with => :white
end

# colorizer for memory
@memory_colorizer = Yummi::Colorizers.percentage :max => :max_memory, :free => :free_memory

# colorizer for threads
@thread_colorizer = Yummi::Colorizers.percentage :max => :max_threads,
                                                 :using => :in_use_threads,
                                                 :threshold => {
                                                   :warn => 0.9,
                                                   :bad => 0.7
                                                 }

def zebra_colors
  @table.colorize_row :using => Yummi::Colorizers.stripe(:yellow, :purple)
end

def full_colors
  @table.colorize :server_name, :with => :purple
  @table.colorize :free_memory, :using => @memory_colorizer
  @table.colorize :in_use_threads, :using => @thread_colorizer
  @table.colorize [:max_memory, :max_threads], :with => :gray
end

full_colors

opt.on '--color TYPE', 'Specify the color type (zebra,full,none)' do |type|
  case type
    when 'zebra'
      zebra_colors
    when 'full'
      full_colors
    when 'none'
      @table.no_colors
    else
  end
end
opt.on '--layout LAYOUT', 'Defines the table layout (horizontal or vertical)' do |layout|
  case layout
    when 'horizontal'
      @table.layout = :horizontal
    when 'vertical'
      @table.layout = :vertical
    else
  end
end
opt.on '--box', 'Prints the table inside a box' do
  @box = Yummi::TextBox::new
end
opt.on '--help', 'Prints this message' do
  puts opt
  exit 0
end

opt.parse ARGV

# sets the table data
@table.data = [
  ['Server 1', 1_000_000_000, 750_000_000, 200, 170],
  ['Server 2', 1_000_000_000, 700_000_000, 200, 180],
  ['Server 3', 1_000_000_000, 50_000_000, 200, 50],
  ['Server 4', 1_000_000_000, 200_000_000, 200, 50],
  ['Server 5', 1_000_000_000, 5_000_000, 200, 50],
  ['Server 6', 1_000_000_000, 750_000_000, 200, 50],
]

@table.add :server_name => 'Server 7',
          :max_memory => 1_000_000_000,
          :free_memory => 200_000_000,
          :max_threads => 200,
          :in_use_threads => 170

class ServerStatus
  attr_reader :server_name, :max_memory, :free_memory, :max_threads, :in_use_threads

  def initialize server_name, max_memory, free_memory, max_threads, in_use_threads
    @server_name = server_name
    @max_memory = max_memory
    @free_memory = free_memory
    @max_threads = max_threads
    @in_use_threads = in_use_threads
  end
end

@table.add ServerStatus::new(
    'Server 8',
    1_000_000_000,
    5_000_000,
    200,
    180
  )

@table.add :server_name => 'Total',
          :max_memory => @table.column(:max_memory).inject(:+),
          :free_memory => @table.column(:free_memory).inject(:+),
          :max_threads => @table.column(:max_threads).inject(:+),
          :in_use_threads => @table.column(:in_use_threads).inject(:+)

if @box
  @box << @table
  @box.print
else
  @table.print
end
