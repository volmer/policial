# Policial :cop:

[![Gem Version](https://badge.fury.io/rb/policial.svg)](http://badge.fury.io/rb/policial)
[![Build Status](https://travis-ci.org/volmer/policial.svg)](https://travis-ci.org/volmer/policial)
[![Dependency Status](https://gemnasium.com/volmer/policial.svg)](https://gemnasium.com/volmer/policial)

*Policial* is a gem that investigates pull requests and accuses style guide
violations. It is based on thoughtbot's
[Hound project](https://github.com/thoughtbot/hound).
Currently it only investigates ruby code. You can setup your ruby code style
rules by defining a `.rubocop.yml` file in you repo. Please see
[RuboCop's README](https://github.com/bbatsov/rubocop).

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

1. First, instantiate a new Detective:
  ```ruby
  detective = Policial::Detective.new
  ```

  You might need to pass an Octokit client with your GitHub credentials.
  For more information on this please check the
  [Octokit README](https://github.com/octokit/octokit.rb).

  ```ruby
  octokit = Octokit::Client.new(access_token: 'mygithubtoken666')
  detective = Policial::Detective.new(octokit)
  ```
  If you don't pass an Octokit client Policial will use the global Octokit
  configuration.

2. Let's investigate! Start by briefing your detective about the pull request it
  will run an investigation against. You can setup a pull request manually:

  ```ruby
  detective.brief(
    repo: 'volmer/my_repo',
    number: 3,
    head_sha: 'headsha'
  )
  ```

  Or you can brief it with a
  [GitHub `pull_request` webhook](https://developer.github.com/webhooks):

  ```ruby
  event = Policial::PullRequestEvent.new(webhook_payload)
  detective.brief(event)
  ```

3. Now you can run the investigation:

  ```ruby
  # Let's investigate this pull request...
  detective.investigate

  # Want to know the violations found?
  detective.violations
  ```

4. Hurry, post comments about those violations on the pull request!
  ```ruby
  detective.accuse
  ```
  The result are comments like this on each line that contains violations:
  ![image](https://cloud.githubusercontent.com/assets/301187/5545861/d5c3da76-8afe-11e4-8c15-341b01f3b820.png)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
