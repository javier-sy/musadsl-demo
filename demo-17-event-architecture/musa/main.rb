# Demo 17: Event Architecture - Sistema launch/on
#
# Demuestra el sistema de eventos para composiciones estructuradas
# por fases con transiciones automáticas.
#
# Inspirado en Estudio para clave nº1 (2019) y Piezoreflections (2017)
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
puts "Demo 17: Event Architecture - Sistema launch/on"
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

clock = TimerClock.new(bpm: 90, ticks_per_beat: 24)
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
  channels: [0]  # Canal 1
)

# ============================================================================
# Composición con Eventos
# ============================================================================

transport.sequencer.with(scale: scale, transport: transport, voices: voices) do |scale:, transport:, voices:|
  @scale = scale
  @transport = transport
  @voices = voices

  def scale = @scale
  def voice = @voices.voices[0]
  def stop_transport = @transport.stop

  load 'score.rb'
  extend TheScore
  score
end

# ============================================================================
# Iniciar
# ============================================================================

puts "Sistema de eventos:"
puts "  - on :event - registra handler"
puts "  - launch :event - dispara evento"
puts "  - control.after { } - callback al terminar"
puts
puts "Fases de la composición:"
puts "  1. Introducción (evento :intro)"
puts "  2. Desarrollo (evento :development)"
puts "  3. Clímax (evento :climax)"
puts "  4. Coda (evento :coda)"
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
