# Demo 18: Parameter Automation - SIN() y move
#
# Demuestra automatización de parámetros usando:
# - SIN() para envolventes sinusoidales
# - move para rampas lineales
# - Números primos para períodos no repetitivos
#
# Inspirado en Estudio para piano nº3 (2019)
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

require_relative 'primes'

# ============================================================================
# Banner
# ============================================================================

puts "=" * 60
puts "Demo 18: Parameter Automation - SIN() y move"
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
# Escala y Voces MIDI
# ============================================================================

scale = Scales.et12[440.0].major[60]  # Do Mayor desde C4

voices = MIDIVoices.new(
  sequencer: transport.sequencer,
  output: midi_output,
  channels: [0, 1]  # 2 canales
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

puts "Funciones de automatización:"
puts "  - SIN(steps:, center:, amplitude:) - envolvente sinusoidal"
puts "  - move(from:, to:, duration:) - rampa lineal"
puts "  - PRIMES[] - períodos no repetitivos"
puts
puts "Secciones:"
puts "  1. SIN() básico para velocity"
puts "  2. SIN() con primes para períodos no repetitivos"
puts "  3. move para fade in/out de CC"
puts "  4. move con step (glissando)"
puts "  5. Combinación de múltiples automatizaciones"
puts "  6. SIN().repeat() ida y vuelta"
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
