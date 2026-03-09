# Demo 21: Fibonacci Episodes
#
# Estructura de composición basada en episodios donde cada
# episodio tiene un número Fibonacci de hilos/voces concurrentes.
#
# Episodio 1: 1 thread
# Episodio 2: 1 thread
# Episodio 3: 2 threads
# Episodio 4: 3 threads
# Episodio 5: 5 threads
# Episodio 6: 8 threads
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
puts "Demo 21: Fibonacci Episodes"
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

scale = Scales.et12[440.0].major[60]

voices = MIDIVoices.new(
  sequencer: transport.sequencer,
  output: midi_output,
  channels: [0]
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
  def voice = @voices.voices[0]

  load 'score.rb'
  extend TheScore
  score
end

# ============================================================================
# Iniciar
# ============================================================================

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
