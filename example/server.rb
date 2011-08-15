#
# to start:
#    thin -R server.rb start
require 'rubygems'
require 'sinatra'
require 'sinatra/base'
require 'sinatra/async'
require 'eventmachine'

class Delayed < Sinatra::Base
  register Sinatra::Async
  
  aget "/:path" do |path|
    waitsec = rand * 2
    EM.add_timer waitsec do 
      body {path}
    end
  end
end


