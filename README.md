# Yummi

This is a tool to colorize your console app.

## Installation

Add this line to your application's Gemfile:

    gem 'yummi'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install yummi

## Ruby Tools

Yummi module provides a set of tools to colorize inputs. Check docs for more information
about how to build tables, text boxes, colored log formatters and more. You can also check
the examples dir to see how to use Yummi features.

## Command Line Tools

Yummi exposes a 'colorize' program that you can use to colorize texts and apply
patterns to colorize lines (usefull to tail logs).

Examples:

    colorize -c intense_red -t "some text"
    echo "some text" | colorize -c intense_red
    tail -f $JBOSS_HOME/standalone/log/server.log | colorize -p path-to-your-jboss7-mapping.yaml

Line patterns are configured with an yaml file containing:

  * prefix (optional): prefix for pattern
  * suffix (optional): suffix for pattern
  * patterns: a pattern => color map

Example:

    prefix: '\d{2}:\d{2}:\d{2},\d{3}\s'
    patterns:
      TRACE : cyan
      DEBUG : blue
      INFO  : gray
      WARN  : yellow
      ERROR : red
      FATAL : intense_red

Yummi provides a set of mappings that you, check yummi/mappings dir.

Mappings provided by yummi can be passed with the file name, example:

    tail -f $JBOSS_HOME/standalone/log/server.log | colorize -p jboss7

Mappings in ~/.yummi dir may also used only with the file name.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
