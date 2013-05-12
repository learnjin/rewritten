#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')

require 'optparse'
require 'rewritten'
require 'multi_json'

options = {
  :drop => false
}

op = OptionParser.new do |opts|
  opts.banner = "Usage: rewriten-dump.rb [options]"

  opts.on("-v", "--verbose", "be more verbose") do |v|
    options[:verbose] = v
  end

  opts.on("-f", "--file FILE", 'input file') do |o|
    options[:file] = o
  end

  opts.on("-u", "--uri URI", 'uri to the redis db') do |uri|
    options[:uri] = uri
  end

  opts.on("-d", "--drop", 'drop translations first') do
    options[:drop] = true
  end

end

op.parse!

unless options[:file]
  puts op
  exit
end

Rewritten.redis = options[:uri] if options[:uri] 

Rewritten.clear_translations if options[:drop]

File.open(options[:file]) do |f|
  h = MultiJson.decode(f.read)
  h.each{|k,v| Rewritten.add_translations(k,v) }
end


