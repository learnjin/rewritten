require 'sinatra/base'
require 'erb'
require 'rewritten'
require 'rewritten/version'
require 'time'

module Rewritten
  class Server < Sinatra::Base

    get "/" do
      "Hello Rewritten Sinatra Server!"
    end

  end
end


