# Yummi

This is a tool to make your console app more tasty. Yummi provides a set of console line elements
also with a delegator for colorizing Strings using the awesome gem term-ansicolor.

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

Yummi exposes a 'yummi' program that you can use to colorize texts and apply
patterns to colorize lines (usefull to tail logs).

Examples:

    yummi -c intense_red -m "some text"
    echo "some text" | yummi -c intense_red
    tail -f $JBOSS_HOME/standalone/log/server.log | yummi -p defined-pattern

Line patterns are configured with an yaml file containing:

  * prefix  (optional): prefix for pattern
  * suffix  (optional): suffix for pattern
  * options (optional): option flags to use
  * patterns: a pattern => color map

Example:

    prefix: '\d{2}:\d{2}:\d{2},\d{3}\s'
    patterns:
      TRACE : cyan
      DEBUG : blue
      INFO  : black
      WARN  : yellow
      ERROR : red
      FATAL : intense_red

Yummi provides a set of patterns, check yummi/patterns dir.

    tail -f $JBOSS_HOME/standalone/log/server.log | yummi -p jboss

User patterns must be in `~/.yummi/patterns` directory with the name `$PATTERN_NAME.yaml`. User patterns can override builtin patterns.

Patterns also has levels according to the order in the mapping file. The example above generates the following levels:

- TRACE : 0
- DEBUG : 1
- INFO  : 2
- WARN  : 3
- ERROR : 4
- FATAL : 5

To limit the levels in console, use the parameter `--level`. If you set it to 3, for example, only messages with the patterns `TRACE`, `DEBUG`, `INFO` and `WARN` will be displayed. This is usefull for filtering log files using `cat` or `tail`.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
