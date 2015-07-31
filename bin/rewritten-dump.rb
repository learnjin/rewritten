#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')

require 'optparse'
require 'rewritten'

options = {
  out: 'rewritten.csv',
  verbose: false
}

op = OptionParser.new do |opts|
  opts.banner = 'Usage: rewriten-dump.rb [options]'

  opts.on('-v', '--verbose', 'be more verbose') do
    options[:verbose] = true
  end

  opts.on('-o', '--out FILE', 'output file or "-" for stdout') do |o|
    options[:out] = o
  end

  opts.on('-u', '--uri URI', 'uri to the redis db') do |uri|
    options[:uri] = uri
  end

  opts.on('-h', '--help', 'print help') do
    puts opts
    exit 0
  end
end
op.parse!

Rewritten.redis = options[:uri] if options[:uri]

file = options[:out] == '-' ? STDOUT : File.open(options[:out], 'w')

file.puts '#from;to'
Rewritten.all_tos.each do |to|
  file.puts Rewritten.get_all_translations(to).map { |from| "#{Rewritten.full_line(from)};#{to}" }.join("\n")
end
