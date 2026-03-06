# Demo 14: Clock Modes - MASTER MODE
#
# En este modo, musa-dsl controla el tempo usando TimerClock.
# El DAW debe sincronizarse recibiendo MIDI Clock de musa-dsl.
#
# Características:
# - El tempo se define en el código (BPM)
# - musa-dsl inicia inmediatamente al ejecutar
# - El DAW sigue el tempo de musa-dsl
#
# Ejecutar: ruby main_master.rb

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
puts "Demo 14: Clock Modes - MASTER MODE"
puts "=" * 60
puts
puts "En este modo, musa-dsl CONTROLA el tempo."
puts "El DAW debe recibir MIDI Clock de musa-dsl."
puts

# ============================================================================
# Configuración MIDI
# ============================================================================

puts "Selecciona el puerto MIDI de salida (notas y clock hacia el DAW):"
output = MIDICommunications::Output.gets

# ============================================================================
# Clock MASTER (TimerClock) - musa-dsl controla el tempo
# ============================================================================

BPM = 110  # ← Cambia este valor para modificar el tempo

clock = TimerClock.new(bpm: BPM, ticks_per_beat: 24)

puts "Clock: TimerClock (MASTER)"
puts "Tempo: #{BPM} BPM"
puts

# ============================================================================
# Transport
# ============================================================================

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
  channels: [0, 1],
  do_log: false
)

# ============================================================================
# Composición (compartida con slave mode)
# ============================================================================

transport.sequencer.with scale: scale, voices: voices do |scale:, voices:|
  @scale = scale
  @voices = voices

  def scale = @scale
  def voices = @voices
  def v(n) = @voices.voices[n]

  load 'score.rb'
  extend TheScore
  score

  on :finished do
    puts "¡Demo completada!"
    transport.stop
  end
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

puts "Configuración del DAW para modo MASTER:"
puts "  1. Configurar DAW para recibir MIDI Clock externo"
puts "  2. Seleccionar el puerto de salida de musa-dsl como fuente de clock"
puts "  3. El DAW debe estar en modo 'External Sync' o similar"
puts
puts "Iniciando en modo MASTER..."
puts "Presiona Ctrl+C para detener"
puts

transport.start

# ============================================================================
# Cleanup (cuando transport.start retorna)
# ============================================================================

output&.close
puts "Dispositivo MIDI cerrado."
