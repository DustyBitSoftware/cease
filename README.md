# Cease

![GitHub Actions](https://github.com/DustyBitSoftware/cease/actions/workflows/ci.yml/badge.svg)

`cease` is a tool that scans for Ruby code marked as EOL.

## Installation

Install via rubygems:
```sh
gem install cease
```

## Usage

Run it:
```sh
cease [directory_or_source_file]*
```

## Example
### Basic usage
Given a source file called `example.rb` that contains the following code:

```ruby
# [cease] at 12pm on 1/1/1999
class RemoveMeLater
  def foo
    puts 'bar'
  end
end
# [/cease]
```

You should see the output:
```sh
$ cease example.rb
Scanning 1 source(s)...

(example.rb)

  [3, 9]: Overdue by roughly 23 years
    class RemoveMeLater
      def foo
        puts 'bar'
      end
    end


Total of 1 evictions(s) found.
```

### Options
Cease supports both 12 and 24 hour clocks:
```ruby
# [cease] at 13:00 on 1/1/1999
class RemoveMeLater
...
# [/cease]
```

Multiple commands per source:
```ruby
# [cease] at 12pm on 1/1/1999
class RemoveMeLater
  def foo
    puts 'bar'
  end
end
# [/cease]

# [cease] at 1pm on 3/3/3333
class RemoveMeWayLater
  def foo
    puts 'bar'
  end
end
# [/cease]
```

If a date isn't provided, Cease attempts to guess the date based on the git commit:
```ruby
# [cease] at 13:00 # The date will be based on the commit timestamp of this comment.
class RemoveMeLater
...
# [/cease]
```

You can provide an optional timezone (defaults to UTC):
```ruby
# [cease] at 1pm on 1/1/1999 { timezone: 'PST' }
class RemoveMeLater
...
# [/cease]
```

**NOTE: Do not nest commands! This will not work:**
```ruby
# [cease] at 1pm
  class RemoveMe
    # [cease] at 3pm
    def initialize
    end
    # [/cease]
  end
# [/cease]
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake test` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/DustyBitSoftware/cease. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [code of
conduct](https://github.com/nohmar/cease/blob/master/CODE_OF_CONDUCT.md).


## Code of Conduct

Everyone interacting in the Cease project's codebases, issue trackers, chat
rooms and mailing lists is expected to follow the [code of
conduct](https://github.com/nohmar/cease/blob/master/CODE_OF_CONDUCT.md).
