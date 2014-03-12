#                         The MIT License
#
# Copyright (c) 2013 Marcelo Guimarães <ataxexe@gmail.com>
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

@box = Yummi::TextBox.new

@box.style.width = 70
@box.style.align = :justify
@box.style.separator[:color] = :magenta
@box.style.border[:color] = :intense_magenta

opt = OptionParser::new

opt.on '--align ALIGN', 'Sets the default alignment to use' do |align|
  @box.style.align = align.to_sym
end
opt.on '--width WIDTH', Integer, 'Sets the text box width' do |width|
  @box.style.width = width
end
opt.on '--left PATTERN', 'Sets the left line pattern' do |pattern|
  @box.style.border[:left] = pattern
end
opt.on '--right PATTERN', 'Sets the right line pattern' do |pattern|
  @box.style.border[:right] = pattern
end
opt.on '--top-left PATTERN', 'Sets the top left corner pattern' do |pattern|
  @box.style.border[:top_left] = pattern
end
opt.on '--top-right PATTERN', 'Sets the top right corner pattern' do |pattern|
  @box.style.border[:top_right] = pattern
end
opt.on '--bottom-left PATTERN', 'Sets the bottom left corner pattern' do |pattern|
  @box.style.border[:bottom_left] = pattern
end
opt.on '--bottom-right PATTERN', 'Sets the bottom right corner pattern' do |pattern|
  @box.style.border[:bottom_right] = pattern
end
opt.on '--top PATTERN', 'Sets the top line pattern' do |pattern|
  @box.style.border[:top] = pattern
end
opt.on '--bottom PATTERN', 'Sets the bottom line pattern' do |pattern|
  @box.style.border[:bottom] = pattern
end
opt.on '--border COLOR', 'Sets the border color' do |color|
  @box.style.border[:color] = color
end
opt.on '--no-border', 'Hide the text box borders' do
  @box.no_border
end
opt.on '--help', 'Prints this message' do
  puts opt
  exit 0
end

opt.parse! ARGV

@box.add 'The MIT License', :color => 'bold.yellow', :align => :center
@box.line_break
@box.add 'Copyright (c) 2013 Marcelo Guimaraes <ataxexe@gmail.com>', :color => :green, :align => :center
@box.separator
@box.add 'Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in the Software
 without restriction, including without limitation the rights to use, copy, modify, merge,
 publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
 to whom the Software is furnished to do so, subject to the following conditions:'
@box.line_break
@box.add 'The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.'
@box.separator :width => @box.style.width / 3, :align => :center
@box.add 'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.',
         :color => :yellow
@box.print
