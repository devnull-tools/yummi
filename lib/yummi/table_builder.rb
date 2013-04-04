#                         The MIT License
#
# Copyright (c) 2013-2012 Marcelo Guimarães <ataxexe@gmail.com>
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
  class TableBuilder

    attr_accessor :config, :repositories

    def initialize config = {}
      if config.is_a? String
        config = Yummi::Helpers::symbolize_keys(YAML::load_file(config))
      end
      @config = config
      @repositories = {}
    
      @repositories[:formatters] = [Yummi::Formatters]    
      @repositories[:colorizers] = [Yummi::Colorizers]    
      @repositories[:row_colorizers] = [Yummi::Colorizers]    
    end

    def defaults
      component [:color, :colorize, :state, :health], :repository => :colorizers,
                                                      :invoke     => :colorize

      component :format, :repository => :formatters,
                         :invoke     => :format

      component [:row_color, :colorize_row], :repository => :row_colorizers,
                                             :invoke     => :colorize_row,
                                             :row_based  => true

      self
    end

    def components
      @components ||= {}
      @components
    end

    def component keys, params
      [*keys].each do |key|
        components[key] = params
      end
    end 

    def build_table
      table = Yummi::Table::new
      table.title = config[:title]
      table.description= config[:description]
      table.aliases = config[:aliases] if config[:aliases]
      table.header = config[:header] if config[:header]
      table.layout = config[:layout].to_sym if config[:layout]

      build_components table, config

      [:bottom, :top].each do |context|
        contexts = config[context]
        if contexts
          contexts.each do |context_config|
            table.send context, context_config do
              build_components table, context_config
            end
          end
        end
      end

      table
    end

    def build_components(table, config)
      components.each do |key, component_config|
        block = lambda do |params|
          table.send component_config[:invoke], *params
        end
        if component_config[:row_based]
          parse_row_based_component config[key], component_config, &block
        else
          parse_component config[key], component_config, &block
        end
      end
    end

    def parse_component(definitions, config)
      if definitions
        definitions.each do |column, component_config|
          callback = []
          column = column.to_s.split(/,/)
          callback << column
          component = create_component(component_config, config)
          callback << {:using => component}
          yield(callback)
        end
      end
    end

    def parse_row_based_component(definitions, config)
      if definitions
        if definitions.is_a? Hash
          definitions.each do |component_name, params|
            component = create_component({component_name => params}, config)
            yield([{:using => component}])
          end
        else
          component = create_component(definitions, config)
          yield([{:using => component}])
        end
      end
    end

    def create_component(component_config, config)
      repositories = @repositories[config[:repository]].reverse
      if component_config.is_a? Hash
        component_config = Yummi::Helpers::symbolize_keys(component_config)
        component = Yummi::GroupedComponent::new
        component_config.each do |component_name, params|
          repositories.each do |repository|
            if repository.respond_to? component_name
              component << repository.send(component_name, params)
              break
            end
          end
        end
        return component
      else
        repositories.each do |repository|
          if repository.respond_to? component_config
            return repository.send(component_config)
          end
        end
      end
    end

  end

end
