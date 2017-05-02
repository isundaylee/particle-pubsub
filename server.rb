require 'socket'
require 'thread'

require_relative 'locked_queue.rb'

PORT = 8787

class ParticlePubsubServer

  def initialize(server)
    @server = server
    @cids = []
    @pending_notifications = {}
  end

  def log(cid, message)
    puts "[Client #{cid}] #{message}"
  end

  def notify(cid, message)
    @pending_notifications[cid].push(message)
  end

  def start_receive_thread(cid, socket)
    Thread.start do
      # Listening for client messages
      loop do
        message = socket.gets
        break if message.empty?
        log cid, "Received message: " + message

        if message.split.first == 'pub'
          event_data = message.split.drop(1).join(' ')

          @cids.each do |other|
            next if other == cid
            notify other, event_data
          end
        end
      end
    end
  end

  def start_send_thread(cid, socket)
    Thread.start do
      loop do
        messages = @pending_notifications[cid].retrieve_all

        # Distributing previous notifications
        messages.each do |notification|
          socket.puts("notify " + notification)
        end

        sleep(0.01)
      end
    end
  end

  def handle_client(cid, socket)
    log cid, "New client connected. "

    @pending_notifications[cid] = LockedQueue.new
    @cids << cid

    start_receive_thread(cid, socket)
    start_send_thread(cid, socket)
  end

  def serve
    1.upto(Float::INFINITY) do |cid|
      client = @server.accept
      handle_client(cid, client)
    end
  end

end

server = ParticlePubsubServer.new(TCPServer.new(PORT))
server.serve
