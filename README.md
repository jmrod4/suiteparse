# SuiteParse

**SuiteParser is a derived class from Ruby library OptionParser for
creating lightweight command line suites.**

Any sugestions, comments or bug reports welcome.

## Why to use it?

Pros:

 * if you are familiar with OptionParser you use the same calling syntax 
   and operation
 * lightweight alternative

Cons:
 
 * you tell me :)

Known problems:
 * not managed (i.e. unexpected results) if user calls directly order!() or order()

## Installation

### Install it for all your applications

At the shell prompt execute:

    $ gem install suiteparse

### Install in your own gem application

Add following line to your application Gemfile

```ruby
gem 'suiteparse'
```

And then execute:

    $ bundle

### Manual install

 * Grab the file 'lib/suiteparse.rb'
 * Remove the line 'require "lib/version"'
 * Put it in any accesible place from your application (lib directory?)
 * Add to your app:

    require "suiteparse"

## Usage

All examples of use of 'optparse' should work unchanged with OptionParse.

Additionaly includes command line suite features.

**For an example of use of the extended features a please see the test example
at the end of the file 'lib/optionparse.rb'**

## Developing SuiteParse further 

After checking out the repo, run `bin/setup` to install dependencies. Then, 
run `rake test` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment. Run `bundle exec 
suiteparse` to use   the gem in this directory, ignoring other installed 
copies of this gem.
