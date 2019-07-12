module Puma::Websockets
  # This is the object that will be given to the Rack application when
  # its callbacks are invoked.
  class Connection
    def initialize(ws, handler)
      @ws = ws
      @handler = handler
    end

    def write(str)
      @ws.text str
    end

    def close
      @ws.close
    end

    def open?
      @ws.state == :open
    end
  end
end
