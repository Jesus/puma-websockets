module Puma::Websockets
  class WS
    # WS objects are expected to respond to url, however this won't be needed
    # with newer versions of the WebSockets protocol. By default, Draft75
    # (which is the oldest available) will be used if no version requested.
    #
    # Read more:
    # https://en.wikipedia.org/wiki/WebSocket#Browser_implementation
    def initialize(env, io)
      @env = env
      @io = io
    end

    attr_reader :env

    def write(msg)
      @io.write msg
    end
  end
end
