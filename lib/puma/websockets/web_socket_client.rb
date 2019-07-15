require 'puma/stream_client'

module Puma::Websockets
  class WebSocketClient < Puma::StreamClient
    def start(handler, ws, connection)
      @handler = handler
      @ws = ws
      @connection = connection

      @lock = Mutex.new

      @events = []

      ws.on :ping do |ev|
        ws.pong ev
      end

      if handler.respond_to? :on_open
        ws.on :open, method(:enqueue)
      end

      if handler.respond_to? :on_message
        ws.on :message, method(:enqueue)
      end

      if handler.respond_to? :on_close
        ws.on :close do |ev|
          enqueue ev
          @io.close
        end
      else
        ws.on :close do |ev|
          @io.close
        end
      end
    end

    def enqueue(event)
      @lock.synchronize do
        @events << event
      end
    end

    def dispatch(event)
      case event
      when WebSocket::Driver::OpenEvent
        @handler.on_open @connection
      when WebSocket::Driver::CloseEvent
        @handler.on_close @connection
      when WebSocket::Driver::MessageEvent
        @handler.on_message @connection, event.data
      else
        STDERR.puts "Received unknown event for websockets: #{event.class}"
      end
    end

    def on_read_ready
      begin
        data = @io.read_nonblock(1024)
      rescue Errno::EAGAIN
        # ok, no biggy.
      rescue SystemCallError, IOError => e
        on_broken_pipe
      else
        @ws.parse data
      end

      @lock.synchronize { @events.any? }
    end

    def on_broken_pipe
      @ws.emit(
        :close,
        WebSocket::Driver::CloseEvent.new("remote closed connection", 1011)
      )
    end

    def on_shutdown
      @io.close
      @handler.on_close @connection
    end

    def churn
      event = @lock.synchronize { @events.shift }
      return unless event

      dispatch event

      @lock.synchronize { @events.any? }
    end
  end
end
