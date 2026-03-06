# Demo 14: Clock Modes - SLAVE MODE
#
# En este modo, el DAW controla el tempo usando InputMidiClock.
# musa-dsl espera recibir MIDI Clock del DAW.
#
# Características:
# - El tempo se define en el DAW
# - musa-dsl espera MIDI Start del DAW para comenzar
# - Cambios de tempo en el DAW se reflejan automáticamente
#
# Ejecutar: ruby main_slave.rb

require 'musa-dsl'
require 'midi-communications'

include Musa::Logger
include Musa::Clock
include Musa::Transport
include Musa::Sequencer
include Musa::Series
include Musa::Scales
include Musa::MIDIVoices

# ============================================================================
# Banner
# ============================================================================

puts "=" * 60
puts "Demo 14: Clock Modes - SLAVE MODE"
puts "=" * 60
puts
puts "En este modo, el DAW CONTROLA el tempo."
puts "musa-dsl espera MIDI Clock del DAW."
puts

# ============================================================================
# Configuración MIDI
# ============================================================================

puts "Selecciona el puerto MIDI de entrada (Clock desde el DAW):"
clock_input = MIDICommunications::Input.gets
puts
puts "Selecciona el puerto MIDI de salida (notas hacia el DAW):"
output = MIDICommunications::Output.gets

# ============================================================================
# Clock SLAVE (InputMidiClock) - El DAW controla el tempo
# ============================================================================

clock = InputMidiClock.new(clock_input)

puts "Clock: InputMidiClock (SLAVE)"
puts "Tempo: Controlado por el DAW"
puts

# ============================================================================
# Transport
# ============================================================================

transport = Transport.new(clock, 4, 24, do_log: true)

# ============================================================================
# Escala y Voces
# ============================================================================

scale = Scales.et12[440.0].major[60]

voices = MIDIVoices.new(
  sequencer: transport.sequencer,
  output: output,
  channels: [0, 1],
  do_log: false
)

# ============================================================================
# Callbacks
# ============================================================================

transport.after_stop do
  puts "\n>>> DAW envió MIDI Stop"
  voices.panic
end

# ============================================================================
# Composición (compartida con master mode)
# Hot-reload: cada MIDI Start recarga score.rb
# ============================================================================

transport.sequencer.with scale: scale, voices: voices, transport: transport do |scale:, voices:, transport:|
  @scale = scale
  @voices = voices
  @transport = transport

  def scale = @scale
  def voices = @voices
  def transport = @transport
  def v(n) = @voices.voices[n]

  transport.on_start do
    puts "\n>>> DAW envió MIDI Start (cargando score)"
    load 'score.rb'
    extend TheScore
    score
  end

  on :finished do
    puts "¡Demo completada!"
  end
end

# ============================================================================
# Iniciar
# ============================================================================

puts "Configuración del DAW para modo SLAVE:"
puts "  1. Habilitar MIDI Clock Output hacia musa-dsl"
puts "  2. Habilitar envío de Start/Stop/Continue"
puts "  3. Seleccionar el puerto correcto"
puts
puts "ESPERANDO MIDI START DEL DAW..."
puts "Presiona PLAY en tu DAW para comenzar"
puts
puts "Prueba a cambiar el tempo en el DAW mientras suena"
puts "musa-dsl seguirá automáticamente"
puts
puts "Presiona Ctrl+C para cancelar"
puts

# ============================================================================
# Manejo de Ctrl+C para cierre limpio
# ============================================================================

Signal.trap('INT') do
  puts "\n\nInterrumpido por usuario"
  voices.panic
  transport.stop
  output&.close
  exit 0
end

transport.start
