module Puma::Websockets
  class WS
    # XXX: Implement `#url` too.
    def initialize(env, io)
      @env = env
      @io = io
    end

    attr_reader :env

    def write(msg)
      @io.write(msg)
    end
  end
end
