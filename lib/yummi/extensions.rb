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

module Yummi
  module OnBox

    #
    # Returns the string wrapped in a #Yummi#TextBox. The given parameters will be used
    # to instantiate the TextBox.
    #
    def on_box(params = {})
      box = Yummi::TextBox::new params
      box.add self
      return box
    end
    
  end

end

class String
  include Term::ANSIColor
  include Yummi::OnBox

  #
  # Colorizes the string using #Yummi#colorize
  # 
  # If params is a hash, the keys will be used as a regexp and the
  # result of #gsub will be colorized using the value color.
  #
  # Otherwise, the params will be sent to Yummi#colorize
  #
  def colorize(params)
    if params.is_a? Hash
      text = self
      params.each do |regexp, color|
        text = text.gsub(regexp, "\\0".colorize(color))
      end
      return text
    end
    Yummi::colorize self, params
  end

end

class Array

  #
  # Colorizes each array item in a new String array
  #
  def colorize(params)
    map { |n| n.to_s.colorize params }
  end

  #
  # Returns a new array using the items with no color applied
  #
  def uncolored
    map {|n| n.to_s.uncolored}
  end

  #
  # Returns a #Yummi#Table using the array content as the data.
  #
  # The parameters will be used to instantiate the table.
  #
  def on_table(params = {})
    table = Yummi::Table::new params
    table.data = self
    return table
  end

end