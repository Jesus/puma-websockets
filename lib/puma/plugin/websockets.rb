require 'puma/plugin'
require 'websocket/driver'

require 'puma/websockets'

UPGRADE_P = "rack.upgrade?".freeze
UPGRADE = "rack.upgrade".freeze

module Puma::Websockets
  Puma::Plugin.create do
    def self.on_before_rack(env)
      # Detect and advertise websocket upgrade ability
      env[UPGRADE_P] = :websocket if WebSocket::Driver.websocket?(env)
    end

    def self.on_after_rack(env, headers, io)
      if handler = env[UPGRADE]
        ws = WebSocket::Driver.rack(WS.new(env, io))

        connection = Connection.new(ws, handler)

        headers.each do |k, vs|
          ws.set_header(k, vs.to_s) if vs.respond_to?(:to_s)
        end

        rec = WebSocketClient.new(io)
        rec.start(handler, ws, connection)

        ws.start

        rec
      end
    end
  end
end
