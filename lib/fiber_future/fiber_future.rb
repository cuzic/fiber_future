require 'thread'
require 'fiber'

class FiberFuture
  def get
    @@fibers[object_id] = Fiber.current
    return Fiber.yield
  end

  def set value
    @@queue << [:value, object_id, value]
  end

  def self.value oid, value
    fiber = @@fibers[oid]
    fiber.resume value
    @@fibers.delete oid
  end

  def self.schedule &block
    @@queue << [:task, block]
  end

  def self.task block, *args
    Fiber.new do
      @current_ff = self.new
      block.call
    end.resume
  end

  @@queue = Queue.new
  @@fibers = {}
  def self.each enumerable
    start

    enumerable.each do |elem|
      schedule do
        yield elem
      end
    end
  end

  def self.start
    return if @started
    @started = true

    @thread = Thread.start do
      while box = @@queue.shift
        method, *args = *box
        self.__send__ method, *args
      end
    end
  end

  def self.finish
    @@queue << nil
    @thread.join
  end

  def self.current
    @current_ff
  end
end
