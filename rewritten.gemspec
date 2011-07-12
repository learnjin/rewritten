# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rewritten/version"

Gem::Specification.new do |s|
  s.name        = "rewritten"
  s.version     = Rewritten::VERSION
  s.authors     = ["Kai Rubarth"]
  s.email       = ["kai@doxter.de"]
  s.homepage    = ""
  s.summary     = %q{Rack app that rewrites URLs -- nicely and uncomplicated}

  s.rubyforge_project = "rewritten"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "vegas",           "~> 0.1.2"

  s.description = <<description
    Rewritten is a simple Redis-backed Ruby library that facilitates creating and refactoring 
    arbitrary urls in your Rack applications.

    Rewritten is inspired by the awesome Resque and Rack::Rewrite gems. It is
    compromised of four parts:

    * A Ruby library for creating and modifying URLs for resources 
    * A Rack app that redirects old URLS and rewrites nice URLs to target 
      path and params
    * A Rack app that rewrites links to their nice counterpart 
    * A Sinatra app for managing URLs 
description

end


