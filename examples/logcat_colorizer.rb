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

require_relative '../lib/yummi'

log = <<LOG
[INFO] Starting
[WARN] Example output
[DEBUG] Connecting to server
[ERROR] Error while connecting
caused by: ConnectionException
            at Connection.connect
              at Startup
[INFO] Could not connect to server
[FATAL] A fatal error
[WARN] Application shutdown
[DEBUG] Shutdown command executed
LOG

colorizer = Yummi::Colorizers.pattern :prefix => /\[/,
  :suffix => /\]/,
  :patterns => {
    'ERROR' => :red,
    'FATAL' => :intense_red,
    'WARN'  => :yellow,
    'INFO'  => :green,
    'DEBUG' => :gray
  }

log.each_line do |line|
  puts colorizer.colorize(line.chomp)
end
