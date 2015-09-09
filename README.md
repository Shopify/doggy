# Doggy

Doggy manages your DataDog dashboards, alerts, monitors, and screenboards.

## Installation

Add this line to your Gemfile:

```ruby
gem 'doggy'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install doggy

## Usage

```
# Export your DataDog credentials or use ejson
$ export DATADOG_API_KEY=api_key_goes_here
$ export DATADOG_APP_KEY=app_key_goes_here

# Download selected items from DataDog
$ doggy pull ID ID

# Download all items
$ doggy pull

# Upload selected items to DataDog
$ doggy push ID ID ID

# Upload all items to DataDog
$ doggy push

# Create a new dashboard
$ doggy create dash 'My New Dash'

# Delete selected items from both DataDog and local storage
$ doggy delete ID ID ID
```

Note that we currently don't support global upload due to high risk of overwriting things. We'll turn this feature on after initial testing period.

## Development

After checking out the repo, run `bundle install` to install dependencies.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/bai/doggy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
