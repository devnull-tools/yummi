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

@basedir = ENV['HOME']

@table = Yummi::Table::new
# setting the header sets the aliases automatically
@table.header = ['Name', 'Size']
@table.aliases << :directory
# sets the title
@table.title = 'File List'
# formats size for easily reading
@table.format :size, :using => Yummi::Formatter.unit(:byte)

opt.on '--color TYPE', 'Specify the color type (zebra,file,none)' do |type|
  case type
    when 'zebra'
      @table.row_colorizer Yummi::Colorizer.stripe :intense_gray, :intense_white
    when 'file'
      @table.row_colorizer do |i, data|
        data[:directory] ? :intense_gray : :intense_white
      end
    when 'none'
      @table.no_colors
    else
  end
end
opt.on '--basedir BASEDIR', 'Selects the basedir to list files' do |basedir|
  @basedir = basedir
end
opt.on '--help', 'Prints this message' do
  puts opt
  exit 0
end

opt.parse ARGV
files = Dir[File.join(@basedir, '*')]
data = []
files.each do |f|
  data << [f, File.size(f), File.directory?(f)] # the last value will not be printed
end
@table.data = data
@table.print
