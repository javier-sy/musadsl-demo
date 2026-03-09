# Demo 19: Advanced Series Operations
#
# Demuestra operaciones avanzadas con series:
# - H() para series hash (pitch, duration, velocity combinados)
# - .eval() para transformaciones
# - .duplicate(), .reverse(), .shift()
# - Series anidadas con arrays de Ruby
# - FIBO().max_size() para patrones Fibonacci
#
# Inspirado en Estudio Fibonacci para piano (2018)
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
include Musa::Datasets

# ============================================================================
# Banner
# ============================================================================

puts "=" * 60
puts "Demo 19: Advanced Series Operations"
puts "=" * 60
puts

# ============================================================================
# Configuración MIDI
# ============================================================================

puts "Selecciona el puerto MIDI de salida (notas hacia el DAW):"
midi_output = MIDICommunications::Output.gets

# ============================================================================
# Clock y Transport
# ============================================================================

clock = TimerClock.new(bpm: 72, ticks_per_beat: 24)
transport = Transport.new(clock, 4, 24, do_log: true)

# TimerClock requiere inicio explícito
transport.before_begin do
  Thread.new do
    sleep 0.1
    clock.start
  end
end

# ============================================================================
# Escala y Voces MIDI
# ============================================================================

scale = Scales.et12[440.0].major[60]  # Do Mayor desde C4

voices = MIDIVoices.new(
  sequencer: transport.sequencer,
  output: midi_output,
  channels: [0, 1]
)

# ============================================================================
# Composición
# ============================================================================

transport.sequencer.with(scale: scale, transport: transport, voices: voices) do |scale:, transport:, voices:|
  @scale = scale
  @transport = transport
  @voices = voices

  def scale = @scale
  def transport = @transport
  def v1 = @voices.voices[0]
  def v2 = @voices.voices[1]

  load 'score.rb'
  extend TheScore
  score
end

# ============================================================================
# Iniciar
# ============================================================================

puts "Operaciones avanzadas con series:"
puts "  - H() - combina series en hash"
puts "  - .eval() - transforma valores"
puts "  - .duplicate() - copia independiente"
puts "  - .reverse() - retrograde"
puts "  - .shift() - rotación"
puts "  - Series anidadas con arrays de Ruby"
puts "  - FIBO().max_size() - Fibonacci limitado"
puts
puts "Presiona Ctrl+C para detener"
puts

# ============================================================================
# Manejo de Ctrl+C para cierre limpio
# ============================================================================

Signal.trap('INT') do
  puts "\n\nInterrumpido por usuario"
  voices.panic
  transport.stop
  midi_output&.close
  exit 0
end

transport.start

# ============================================================================
# Cleanup (cuando transport.start retorna)
# ============================================================================

midi_output&.close
puts "Dispositivo MIDI cerrado."
