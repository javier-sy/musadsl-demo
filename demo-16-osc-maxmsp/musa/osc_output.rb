# Demo 16: OSC Output
#
# Envía notas generadas hacia Max/MSP via OSC::Client.

require 'osc-ruby'

class OscOutput
  def initialize(host:, port:)
    @client = OSC::Client.new(host, port)
  end

  # /note pitch velocity duration_ms
  def send_note(pitch, velocity, duration_ms)
    @client.send(OSC::Message.new('/note', pitch.to_i, velocity.to_i, duration_ms.to_i))
  rescue => e
    puts "OSC Error (note): #{e.message}"
  end
end
