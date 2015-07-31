#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
begin
  require 'vegas'
rescue LoadError
  require 'rubygems'
  require 'vegas'
end

require 'rewritten/server'

Vegas::Runner.new(Rewritten::Server, 'rewritten-web', {
                    before_run: lambda {|v|
                      path = (ENV['RESQUECONFIG'] || v.args.first)
                      load path.to_s.strip if path
                    }
                  }) do |runner, opts, _app|
  opts.on('-N NAMESPACE', '--namespace NAMESPACE', 'set the Redis namespace') {|namespace|
    runner.logger.info "Using Redis namespace '#{namespace}'"
    Rewritten.redis.namespace = namespace
  }
end
