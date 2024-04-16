# AllConflict

This is a reproduction repo for an issue I ran into when [trying to upgrade gems in simplecov](https://github.com/simplecov-ruby/simplecov/pull/1088).

The core of the issue is that we use:

* `cucumber`
* `aruba`
* `capybara`

In the same cucumber test suite. `aruba` depends on `rspec-expectations` which defines an `all` matcher that `aruba` uses (f.ex. in `the following files should (not )?exist:`). `capybara` also defines an `all` method in its DSL. These 2 clash, breaking the test suite. Loading capybara in a way where all methods would be on a dedicated object as they sometimes are with capybara ()`page.all`) would likely solve it, but I didn't find how to configure that.

Fwiw this clash doesn't occur on earlier version combinations (you can check out the [simplecov Gemfile.lock](https://github.com/simplecov-ruby/simplecov/blob/main/Gemfile.lock) for versions that work)

Repo is used to show the issue (on various levels).

Most of this works by commenting out/readding thins in `features/support/env.rb`

## Setup

`bundle install`

## rspec-expectations vs. capybara

The steps in the scenario here are one debug step showing where `all` is defined and another easy step that just used fairly simple `rspec/expecations`:

```
Then(/^I want to check something with all$/) do
  expect([2, 4, 6]).to all be_even
end
```

### Only rspec

Make sure env.rb has only:

```
require 'rspec/expectations'
```

Now run `bundle exec cucumber features/all.feature`:

```
tobi@qiqi:~/github/all_conflict$ be cucumber features/all.feature
Feature: Cucumber

  Scenario: First Run                       # features/all.feature:2
/home/tobi/.asdf/installs/ruby/3.2.2/lib/ruby/gems/3.2.0/gems/rspec-expectations-3.13.0/lib/rspec/matchers.rb
662
    def all(expected)
      BuiltIn::All.new(expected)
    end
    Then I debug what the hell `all` is     # features/step_definitions/debug.rb:3
    Then I want to check something with all # features/step_definitions/debug.rb:10

1 scenario (1 passed)
2 steps (2 passed)
0m0.002s
```

### Adding capybara

env.rb:

```
require 'capybara/cucumber'


Capybara.app = Rack::Builder.new do
  use Rack::Static, urls: {"/" => "index.html"}, root: "."
  run Rack::Directory.new(".")
end.to_app
```

running `all.feature` again:

```
tobi@qiqi:~/github/all_conflict$ be cucumber features/all.feature
Feature: Cucumber

  Scenario: First Run                       # features/all.feature:2
/home/tobi/.asdf/installs/ruby/3.2.2/lib/ruby/gems/3.2.0/gems/capybara-3.40.0/lib/capybara/dsl.rb
51
        def #{method}(...)
          page.method("#{method}").call(...)
        end
    Then I debug what the hell `all` is     # features/step_definitions/debug.rb:3
/home/tobi/.asdf/installs/ruby/3.2.2/lib/ruby/gems/3.2.0/gems/capybara-3.40.0/lib/capybara/selector/selector.rb:69: warning: Locator RSpec::Matchers::BuiltIn::BePredicate:#<RSpec::Matchers::BuiltIn::BePredicate:0x00007c0259e213c8 @method_name=:be_even, @args=[], @block=nil> for selector :css must be an instance of String or Symbol. This will raise an error in a future version of Capybara. Called from: /home/tobi/github/all_conflict/features/step_definitions/debug.rb:11
    Then I want to check something with all # features/step_definitions/debug.rb:10
      undefined method `include?' for #<RSpec::Matchers::BuiltIn::BePredicate:0x00007c0259e213c8 @method_name=:be_even, @args=[], @block=nil> (NoMethodError)
      ./features/step_definitions/debug.rb:11:in `/^I want to check something with all$/'
      features/all.feature:4:in `I want to check something with all'

Failing Scenarios:
cucumber features/all.feature:2 # Scenario: First Run

1 scenario (1 failed)
2 steps (1 failed, 1 passed)
0m0.002s
```

As you can see the method source changed and we error now, purely by capybara.


## aruba vs. capybara with a basic example

This one uses a basic aruba scenario that uses one of the steps using the `all` matcher (the last step):

```
Feature: Cucumber
  Scenario: First Run
    Given a file named "file.txt" with:
    """
    Hello, Aruba!
    """
    Then I debug what the hell `all` is
    And the following files should exist:
    | file.txt |
```

### aruba only

`env.rb` set to:

```
require 'aruba/cucumber'
```

Now let's run `bundle exec features/feature.feature` (yes I'm creative with my naming):

```
tobi@qiqi:~/github/all_conflict$ be cucumber features/feature.feature
Feature: Cucumber

  Scenario: First Run                     # features/feature.feature:2
    Given a file named "file.txt" with:   # aruba-2.2.0/lib/aruba/cucumber/file.rb:26
      """
      Hello, Aruba!
      """
/home/tobi/.asdf/installs/ruby/3.2.2/lib/ruby/gems/3.2.0/gems/rspec-expectations-3.13.0/lib/rspec/matchers.rb
662
    def all(expected)
      BuiltIn::All.new(expected)
    end
    Then I debug what the hell `all` is   # features/step_definitions/debug.rb:3
    And the following files should exist: # aruba-2.2.0/lib/aruba/cucumber/file.rb:92
      | file.txt |

1 scenario (1 passed)
3 steps (3 passed)
0m0.003s
```

### add in capybara

env.rb to:

```
require 'aruba/cucumber'
require 'capybara/cucumber'


Capybara.app = Rack::Builder.new do
  use Rack::Static, urls: {"/" => "index.html"}, root: "."
  run Rack::Directory.new(".")
end.to_app
```

and same error:

```
tobi@qiqi:~/github/all_conflict$ be cucumber features/feature.feature
Feature: Cucumber

  Scenario: First Run                     # features/feature.feature:2
    Given a file named "file.txt" with:   # aruba-2.2.0/lib/aruba/cucumber/file.rb:26
      """
      Hello, Aruba!
      """
/home/tobi/.asdf/installs/ruby/3.2.2/lib/ruby/gems/3.2.0/gems/capybara-3.40.0/lib/capybara/dsl.rb
51
        def #{method}(...)
          page.method("#{method}").call(...)
        end
    Then I debug what the hell `all` is   # features/step_definitions/debug.rb:3
/home/tobi/.asdf/installs/ruby/3.2.2/lib/ruby/gems/3.2.0/gems/capybara-3.40.0/lib/capybara/selector/selector.rb:69: warning: Locator RSpec::Matchers::DSL::Matcher:#<RSpec::Matchers::DSL::Matcher be_an_existing_file> for selector :css must be an instance of String or Symbol. This will raise an error in a future version of Capybara. Called from: /home/tobi/.asdf/installs/ruby/3.2.2/lib/ruby/gems/3.2.0/gems/aruba-2.2.0/lib/aruba/cucumber/file.rb:98
    And the following files should exist: # aruba-2.2.0/lib/aruba/cucumber/file.rb:92
      | file.txt |
      undefined method `include?' for #<RSpec::Matchers::DSL::Matcher be_an_existing_file> (NoMethodError)
      features/feature.feature:8:in `the following files should exist:'

Failing Scenarios:
cucumber features/feature.feature:2 # Scenario: First Run

1 scenario (1 failed)
3 steps (1 failed, 2 passed)
0m0.005s
```

FWIW the error reads slightly different when also running with apparition as a driver for capybara, but since it still fails in this setup I didn't want to unnecessarily complicate the setup.
