module Puma::Websockets
  class WebSocketClient
    def initialize(handler, ws, client, io)
      @handler = handler
      @ws = ws
      @client = client
      @io = io
      @closed = false

      @lock = Mutex.new

      @events = []

      ws.on :ping do |ev|
        ws.pong ev
      end

      if handler.respond_to? :on_open
        ws.on :open, method(:queue)
      end

      if handler.respond_to? :on_message
        ws.on :message, method(:queue)
      end

      if handler.respond_to? :on_close
        ws.on :close do |ev|
          queue ev
          @closed = true
        end
      else
        ws.on :close do |ev|
          @closed = true
        end
      end
    end

    def queue(event)
      @lock.synchronize do
        @events << event
      end
    end

    def dispatch(event)
      case event
      when ::WebSocket::Driver::OpenEvent
        @handler.on_open @client
      when ::WebSocket::Driver::CloseEvent
        @handler.on_close @client
      when ::WebSocket::Driver::MessageEvent
        @handler.on_message @client, event.data
      else
        STDERR.puts "Received unknown event for websockets: #{event.class}"
      end
    end

    def stream?
      true
    end

    def read_more
      begin
        data = @io.read_nonblock(1024)
      rescue Errno::EAGAIN
        # ok, no biggy.
      rescue SystemCallError, IOError
        @ws.emit(:close,
                 ::WebSocket::Driver::CloseEvent.new(
                   "remote closed connection", 1011))
      else
        @ws.parse data
      end

      @lock.synchronize { @events.any? }
    end

    def churn
      event = @lock.synchronize { @events.shift }
      return unless event

      dispatch event

      @lock.synchronize { @events.any? }
    end

    def closed?
      @closed
    end
  end
end
