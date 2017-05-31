# Policial :cop:

[![Gem Version](https://badge.fury.io/rb/policial.svg)](http://badge.fury.io/rb/policial)
[![Build Status](https://travis-ci.org/volmer/policial.svg)](https://travis-ci.org/volmer/policial)
[![Dependency Status](https://gemnasium.com/volmer/policial.svg)](https://gemnasium.com/volmer/policial)

*Policial* is a gem that investigates pull requests and accuses style guide
violations. It is based on thoughtbot's
[Hound project](https://github.com/thoughtbot/hound).
It currently supports Ruby, SCSS and CoffeeScript.

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

4. Want to know the violations found?
  ```ruby
  violations = detective.violations
  # => [#<Policial::Violation:0x007ff0b5abad30 @filename="lib/test.rb", @line_number=1, ...>]

  violations.first.message
  "Prefer single-quoted strings when you don't need string interpolation or special symbols."
  ```

## Ruby

You can setup your Ruby code style rules with a `.rubocop.yml` file in
your repo. Please see [RuboCop's README](https://github.com/bbatsov/rubocop).

## CoffeeScript

You can setup your CoffeeScript code style rules with a `coffeelint.json`
file in your repo. For more information on how customize the linter rules please
visit the [Coffeelint website](http://coffeelint.org).

## SCSS

SCSS linting is disabled by default. To enable it, you need to install the
[SCSS-Lint](https://github.com/brigade/scss-lint) gem:

```
gem install scss_lint
```

Or add the following to your `Gemfile` and run `bundle install`:

```ruby
gem 'scss_lint', require: false
```

The `require: false` is necessary because `scss-lint` monkey patches `Sass`.
More info [here](https://github.com/brigade/scss-lint#installation).

Now you can enable SCSS on Policial:

```ruby
Policial.style_guides << Policial::StyleGuides::Scss
```

You can setup your SCSS code style rules with a `.scss-lint.yml` file in your
repo. For more information on how to customize the linter rules please
read [SCSS-Lint's README](https://github.com/brigade/scss-lint#configuration).

## ERB

ERB linting is disabled by default. To enable it, you need to install the
[erb-lint](https://github.com/justinthec/erb-lint) gem:

```
gem install erb_lint
```

Or add the following to your `Gemfile` and run `bundle install`:

```ruby
gem 'erb_lint'
```

Now you can enable ERB on Policial:

```ruby
Policial.style_guides << Policial::StyleGuides::Erb
```

You can setup your ERB code style rules with a `.erb-lint.yml` file in your
repo. For more information on how to customize the linter rules please
read [ERB-Lint's README](https://github.com/justinthec/erb-linter#configuration).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
