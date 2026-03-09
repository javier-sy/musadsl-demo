# Demo 16: Input Handler
#
# Recibe parámetros de control desde Max/MSP via OSC::Server.
# Cuando un parámetro cambia, lanza un evento en el sequencer
# para que el score reaccione inmediatamente.

require 'osc-ruby'

class InputHandler
  MODES = { 0 => :major, 1 => :minor, 2 => :dorian, 3 => :mixolydian }.freeze
  MODE_NAMES = { major: "Mayor", minor: "Menor", dorian: "Dórico", mixolydian: "Mixolidio" }.freeze

  attr_reader :params

  def initialize(port:, sequencer:, do_log: false)
    @server = OSC::Server.new(port)
    @port = port
    @sequencer = sequencer
    @do_log = do_log

    @params = {
      root: 0,          # 0-11 (nota cromática: 0=C, 1=C#, ..., 11=B)
      mode: :major,     # :major, :minor, :dorian, :mixolydian
      density: 4,       # 1-8 (notas por compás)
      register: 0       # -2..2 (desplazamiento de octava)
    }

    setup_handlers
  end

  def start
    @thread = Thread.new { @server.run }
    puts "  OSC Input escuchando en puerto #{@port}" if @do_log
  end

  def stop
    @thread&.exit
  end

  private

  def setup_handlers
    @server.add_method('/root') do |message|
      update(:root, message.to_a.first.to_i.clamp(0, 11), :root_changed)
    end

    @server.add_method('/mode') do |message|
      idx = message.to_a.first.to_i.clamp(0, 3)
      update(:mode, MODES[idx], :mode_changed)
    end

    @server.add_method('/density') do |message|
      update(:density, message.to_a.first.to_i.clamp(1, 8), :density_changed)
    end

    @server.add_method('/register') do |message|
      update(:register, message.to_a.first.to_i.clamp(-2, 2), :register_changed)
    end
  end

  # Actualiza el param y lanza evento en el sequencer si cambió
  def update(key, value, event)
    old = @params[key]
    @params[key] = value
    if old != value
      log_change(key, value)
      @sequencer.launch(event, @params.dup)
    end
  end

  def log_change(key, value)
    puts "  OSC← /#{key} #{value}" if @do_log
  end
end
