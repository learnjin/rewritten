Rewritten [![Build Status](https://travis-ci.org/learnjin/rewritten.png?branch=master)](https://travis-ci.org/learnjin/rewritten/) [![Csdfode Climate](https://codeclimate.com/github/learnjin/rewritten.png)](https://codeclimate.com/github/learnjin/rewritten) [![Coverage Status](https://coveralls.io/repos/learnjin/rewritten/badge.png)](https://coveralls.io/r/learnjin/rewritten)
=========

Rewritten is a lookup-based rewriting engine that rewrites requested URLs on
the fly. The URL manipulations depend on translations found in a redis
database. URLs without translations are passed through while URLs with
translations result in a either redirection or ultimatively in a modification
of path and request parameters. The gem is compromised of several parts:

1. A Ruby library for creating, modifying and querying translations.
2. A Sinatra app for displaying and managing translations
3. A Rack app for rewriting and redirecting requests (Rack::Rewritten::Url)
4. A Rack app for substituting URLs in HTML pages with their current translation (Rack::Rewritten::Html)
5. A Rack app for recording requests (Rack::Rewritten::Record)
6. A Rack app for identifying subdomains (Rack::Rewritten::Subdomain)

Part 1. and 2. are based heavily on parts from the Resque codebase.

## Installation

    gem install rewritten

On Rails add Rewritten to your Gemfile:

    gem 'rewritten'

Rewritten works completely transparent and decoupled as Rack middleware. Add it to your rack stack.

    # config.ru
    require 'rewritten'
    
    Rewritten.redis = Redis.new(host: 'host', port: 'port', password: 'password' )

    map "/" do
      use Rack::Rewritten::Url
      use Rack::Rewritten::Html
      run MyApp::Application
    end


This will translate pretty/SEO requests to the language that MyApp speaks and translate the HTML-Output of
MyApp to the desired pretty/SEO language.

On Rails the HTML translation can also be achieved by including the following to your <tt>application_controller.rb</tt>:

    require 'rewritten/rails'

    class ApplicationController < Action:Controller::Base
    
      include Rewritten::Rails::UrlHelper
    
      # ....
      #

    end

This way all routes helpers will be translated.


## Managing Vocabulary

To manage the vocabulary from within your Rack app you need to establish a connection to the same
redis db (on Rails put this into an initializer).

    include 'rewritten'
    Rewritten.redis = Redis.new(host: 'host', port: 'port', password: 'password' )

The ruby library allows you to successively add and remove vocabulary:

    Rewritten.add_translation('/apple-computer/newton', '/products/4e4d3c6a1d41c811e8000009')
    Rewritten.add_translation('/apple/ipad', '/products/4e4d3c6a1d41c811e8000009')

    Rewritten.remove_translation('/failed-computer/newton', '/products/4e4d3c6a1d41c811e8000009')


To query for the current "trade language" use:

    Rewritten.get_current_translation('/products/4e4d3c6a1d41c811e8000009')         # => "/apple/ipad"


## The web front end

Rewritten comes with a Sinatra-based front end for dislaying and
managing your URL translations (layout taken from Resque). Include it in your Rack stack with:

    require 'rewritten/server'

    map "/rewritten" do
      use Rack::Auth::Basic do |username, password|
        username == 'user' and password == 'password'
      end
      run Rewritten::Server
    end

### Standalone

Running the gem in standalone mode is easy as well:

    $ rewritten-web 

It's based on Vegas, a thin layer around rackup, and as such configurable as well:

    $ rewritten-web -p 8282























