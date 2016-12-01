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

## Authentication

To authenticate, you need to set API and APP keys for your DataDog account.

#### Environment variables

Export `DATADOG_API_KEY` and `DATADOG_APP_KEY` environment variables and `doggy` will catch them up automatically.

#### ejson

Set up `ejson` by putting `secrets.ejson` in your root object store.

#### json (plaintext)

If you're feeling adventurous, just put plaintext `secrets.json` in your root object store like this:

```json
{
  "datadog_api_key": "key1",
  "datadog_app_key": "key2"
}
```

## Usage

```bash
# Download items. If no ID is given it will download all the items managed by dog.
$ doggy pull [IDs]

# Upload items to Datadog. If no ID is given it will push all items.
$ doggy push [IDs]

# Edit an item in WYSIWYG
$ doggy edit ID

# Delete selected items from both Datadog and local storage
$ doggy delete IDs

# Mute monitor(s) forever
$ doggy mute IDs

# Unmute monitor(s)
$ doggy unmute IDs
```
Multiple IDs should be separated by space.

## Development

After checking out the repo, run `bundle install` to install dependencies.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/bai/doggy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
