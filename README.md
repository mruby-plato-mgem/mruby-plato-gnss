# mruby-plato-gnss   [![Build Status](https://travis-ci.org/mruby-plato/mruby-plato-gnss.svg?branch=master)](https://travis-ci.org/mruby-plato/mruby-plato-gnss)

Plato::gnss module

## install by mrbgems

- add conf.gem line to `build_config.rb`

```ruby
MRuby::Build.new do |conf|

  # ... (snip) ...

  conf.gem :git => 'https://github.com/mruby-plato/mruby-plato-gnss'
end
```

## example

```ruby
uart = UART.new
line = uart.gets
puts Plato::GNSS.parse_line(line)
```

## License

under the MIT License:

- see LICENSE file
