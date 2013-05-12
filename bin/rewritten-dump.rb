#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')

require 'optparse'
require 'rewritten'
require 'multi_json'

options = {
  :out => 'rewritten.json'
}

op = OptionParser.new do |opts|
  opts.banner = "Usage: rewriten-dump.rb [options]"

  opts.on("-v", "--verbose", "be more verbose") do |v|
    options[:verbose] = v
  end

  opts.on("-o", "--out FILE", 'output file or "-" for stdout') do |o|
    options[:out] = o
  end

  opts.on("-u", "--uri URI", 'uri to the redis db') do |uri|
    options[:uri] = uri
  end

  opts.on("-h", "--help", 'print help') do
    puts opts
    exit 0
  end

end
op.parse!

Rewritten.redis = options[:uri] if options[:uri] 
File.open(options[:out], "w"){|f| f.write(MultiJson.encode(Rewritten.all_translations) + "\n")}


