# Demo 03: Canon a Dos Voces
#
# Demuestra el sistema buffered de series para crear un canon clásico
# donde la segunda voz entra retrasada ejecutando la misma melodía.
#
# Ejecutar: ruby main.rb

require 'musa-dsl'
require 'midi-communications'

include Musa::All

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
# Escala y Voces MIDI
# ============================================================================

scale = Scales.et12[440.0].major[60]

voices = MIDIVoices.new(
  sequencer: transport.sequencer,
  output: output,
  channels: [0, 1],  # 2 canales para las 2 voces del canon
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
  def v(n) = @voices.voices[n]
  def transport = @transport

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

puts "Iniciando Demo 03: Canon a Dos Voces"
puts "La segunda voz entra 2 compases después"
puts "Presiona Ctrl+C para detener"
puts

transport.start

# ============================================================================
# Cleanup (cuando transport.start retorna)
# ============================================================================

output&.close
puts "Dispositivo MIDI cerrado."
