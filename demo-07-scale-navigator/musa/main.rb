# Demo 07: Scale Navigator - Navegación Armónica
#
# Demuestra el sistema de escalas de musa-dsl: 40+ tipos de escalas,
# navegación entre grados, construcción de acordes y modulación.
#
# Ejecutar: ruby main.rb

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
# Configuración MIDI
# ============================================================================

output = MIDICommunications::Output.gets

# ============================================================================
# Clock y Transport (Master Clock)
# ============================================================================

clock = TimerClock.new(bpm: 80, ticks_per_beat: 24)
transport = Transport.new(clock, 4, 24, do_log: true)

# TimerClock requiere inicio explícito
transport.before_begin do
  Thread.new do
    sleep 0.1
    clock.start
  end
end

# ============================================================================
# Escalas disponibles en musa-dsl
# ============================================================================

puts "Escalas disponibles en musa-dsl:"
puts "  Mayor, menor natural, armónica, melódica"
puts "  Modos: dórico, frigio, lidio, mixolidio, locrio"
puts "  Pentatónicas, blues, bebop, whole-tone, chromatic"
puts "  Escalas exóticas: húngara, bizantina, japonesa..."
puts

# ============================================================================
# Escala inicial y Voces
# ============================================================================

# Escala base: Do mayor a partir de C4 (MIDI 60)
scale = Scales.et12[440.0].major[60]

voices = MIDIVoices.new(
  sequencer: transport.sequencer,
  output: output,
  channels: [0, 1, 2],  # Melodía, acordes, bajo
  do_log: false
)

# ============================================================================
# Composición
# ============================================================================

transport.sequencer.with scale: scale, voices: voices, transport: transport do |scale:, voices:, transport:|
  @scale = scale
  @voices = voices
  @transport = transport

  def scale = @scale
  def voices = @voices
  def transport = @transport
  def v(n) = @voices.voices[n]

  load 'score.rb'
  extend TheScore
  score
end

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

# ============================================================================
# Iniciar
# ============================================================================

puts "Iniciando Demo 07: Scale Navigator"
puts "Explorando el sistema de escalas y navegación armónica"
puts "Presiona Ctrl+C para detener"
puts

transport.start

# ============================================================================
# Cleanup (cuando transport.start retorna)
# ============================================================================

output&.close
puts "Dispositivo MIDI cerrado."
