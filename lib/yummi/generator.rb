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

require 'erb'

module Yummi

  class Generator

    class ShellScript

      def initialize params = {}
        params = {
          :function_prefix => "color_",
          :colors => Yummi::Color::color_names,
          :types => Yummi::Color::type_names,
          :use_color_numbers => true
        }.merge! params
        @function_prefix = params[:function_prefix]
        colors = Yummi::Color::color_names & params[:colors]
        colors += (1..7).to_a if params[:use_color_numbers]
        types = Yummi::Color::type_names & params[:types]
        @colors = Yummi::Color::COLORS.select do |key, pattern|
          type, color = key.to_s.split("_") if key.to_s.include?("_")
          type ||= "default" unless color
          color ||= key.to_s
          colors.include?(color) and types.include?(type)
        end
      end

      def generate_library file
        @header = parse "header"
        script = parse("colorize-functions")
        File.open(file, "w") { |f| f.write script }
      end

      def generate_program file
        @functions = parse "colorize-functions"
        @header = parse "header"
        script = parse("colorize")
        File.open(file, "w") { |f| f.write script }
        File.chmod(0755, file)
      end

      private

      def parse template
        file = File.join(File.dirname(__FILE__), "generate/#{template}.sh.erb")
        content = File.read(file)
        erb = ERB::new(content, 0, "%<>")
        erb.result binding
      end

    end

  end

end