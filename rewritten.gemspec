# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rewritten/version"

Gem::Specification.new do |s|
  s.name        = "rewritten"
  s.version     = Rewritten::VERSION
  s.authors     = ["Kai Rubarth"]
  s.email       = ["kai@doxter.de"]
  s.homepage    = ""
  s.summary     = %q{A redis-based URL rewriting engine}

  s.rubyforge_project = "rewritten"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "redis-namespace"
  s.add_dependency "vegas",           "~> 0.1.2"
  s.add_dependency "sinatra",         ">= 0.9.2"
  s.add_dependency "multi_json",      "~> 1.0"

  s.description = <<description
    Rewritten is a lookup-based rewriting engine that rewrites requested
    URLs on the fly. The URL manipulations depend on translations found in
    a redis database.

    If a matching translation is found, the result of a request is either a
    redirection or a modification of path and request parameters. For URLs
    without translation entries the request is left unmodified.

    Rewritten takes larges parts from the Resque codebase (which rocks). The
    gem is compromised of four parts:

    1. A Ruby library for creating, modifying and querying translations
    2. A Sinatra app for displaying and managing translations
    3. A Rack app for rewriting and redirecting request (Rack::Rewritten::Url)
    4. A Rack app for substituting URLs in HTML pages with their current translation (Rack::Rewritten::Html)
    5. A Rack app for recording successful request (Rack::Rewritten::Record)
description

end


