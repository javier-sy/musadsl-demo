# Demo 05: Markov Melodies - Cadenas Probabilísticas
#
# Demuestra el sistema de cadenas de Markov para generar
# melodías donde cada nota determina probabilísticamente la siguiente.
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
include Musa::Markov
include Musa::MIDIVoices

# ============================================================================
# Configuración MIDI
# ============================================================================

output = MIDICommunications::Output.gets

# ============================================================================
# Clock y Transport (Master Clock)
# ============================================================================

clock = TimerClock.new(bpm: 110, ticks_per_beat: 24)
transport = Transport.new(clock, 4, 24, do_log: true)

# TimerClock requiere inicio explícito
transport.before_begin do
  Thread.new do
    sleep 0.1
    clock.start
  end
end

# ============================================================================
# Escala y Voces
# ============================================================================

scale = Scales.et12[440.0].major[60]

voices = MIDIVoices.new(
  sequencer: transport.sequencer,
  output: output,
  channels: [0, 1, 2],  # 3 estilos diferentes
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

puts "Iniciando Demo 05: Markov Melodies"
puts "3 estilos de cadenas de Markov"
puts "Presiona Ctrl+C para detener"
puts

transport.start

# ============================================================================
# Cleanup (cuando transport.start retorna)
# ============================================================================

output&.close
puts "Dispositivo MIDI cerrado."
