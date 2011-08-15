# after starting server.rb
# 
$: << File.join(File.dirname(__FILE__), "../lib")
require 'fiber_future'

class Worker
  @queue       = Queue.new
  @workers     = []
  @concurrency = 50

  def self.task cmdline, &callback
    self.start
    @queue << [cmdline, callback]
  end
  
  def self.start
    return if @started
    @started = true 

    @concurrency.times do
      @workers << Thread.start do
        loop do
          cmdline, callback = @queue.shift
          break if cmdline.nil?
          result = `#{cmdline}`
          callback.call result
        end
      end
    end
  end

  def self.finish
    sleep 0.1 until @queue.empty?
    @concurrency.times do
      @queue << nil
    end
    @workers.each do |t|
      t.join
    end
  end
end

at_exit do
  sleep 0.1
  Worker.finish
  FiberFuture.finish
end

def wget url
  ff = FiberFuture.current
  Worker.task "wget -q -O - #{url}" do |body|
    ff.set body
  end
  return ff.get
end

urls = ("00".."99").map do |i|
  "http://localhost:3000/#{i}"
end

FiberFuture.each urls do |url|
  body = wget url
  puts "#{url} #{body}"
end
