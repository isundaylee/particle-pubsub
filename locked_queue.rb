require 'thread'

class LockedQueue

  def initialize
    @mutex = Mutex.new
    @queue = []
  end

  def push(element)
    @mutex.synchronize do
      @queue << element
    end
  end

  def retrieve_all()
    answer = @queue
    @mutex.synchronize do
      @queue = []
    end
    answer
  end

end