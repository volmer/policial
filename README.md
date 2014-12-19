# Policial

[![Build Status](https://travis-ci.org/volmer/policial.svg)](https://travis-ci.org/volmer/policial)

*Policial* is a gem that investigates pull requests and accuses style guide
violations. It is based on thoughtbot's [Hound project](https://github.com/thoughtbot/hound).

Currently it only investigates Ruby code throught [RuboCop](https://github.com/bbatsov/rubocop).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'policial'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install policial

## Usage

First, you need to configure Policial with a GitHub access token:

```ruby
Policial.setup do |config|
  config.github_access_token = 'myAccessToken'
end
```

Then you can start running investigations based on pull request events.
Once you get a event payload from a [GitHub `pull_request` webhook](https://developer.github.com/webhooks),
you can instantiate an investigation:

```ruby
investigation = Policial::Investigation.new(webhook_pull_request_payload)

# Let's investigate this pull request...
investigation.run

# Want to know the violations found?
investigation.violations

# Hurry, post comments about those violations on the pull request!
investigation.accuse
```

## Contributing

1. Fork it ( https://github.com/volmer/policial/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
