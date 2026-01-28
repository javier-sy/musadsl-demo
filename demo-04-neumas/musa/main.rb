# Demo 04: Neumas - Notación Musical Textual
#
# Demuestra el sistema de notación Neuma de musa-dsl:
# - Grados de escala (absolutos y relativos)
# - Duraciones y dinámicas
# - Silencios
# - Adornos (trino, mordente, staccato)
# - Sistema de eventos para encadenar secciones
#
# Ejecutar: ruby main.rb

require 'musa-dsl'
require 'midi-communications'

include Musa::All
using Musa::Extension::Neumas

# ============================================================================
# Configuración MIDI
# ============================================================================

output = MIDICommunications::Output.gets

# ============================================================================
# Clock y Transport (Master Clock)
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
# Escala y Voces
# ============================================================================

scale = Scales.et12[440.0].major[60]

voices = MIDIVoices.new(
  sequencer: transport.sequencer,
  output: output,
  channels: [0],
  do_log: false
)

# ============================================================================
# Transcriptor y Decoder para Neumas
# ============================================================================
# El transcriptor expande adornos (tr, mor, st) a notas reales
# El decoder convierte GDVD (diferencial) a GDV (absoluto)

transcriptor = Musa::Transcription::Transcriptor.new(
  Musa::Transcriptors::FromGDV::ToMIDI.transcription_set(duration_factor: 1/4r),
  base_duration: 1/4r,
  tick_duration: 1/96r
)

decoder = Musa::Neumas::Decoders::NeumaDecoder.new(
  scale,
  base_duration: 1/4r,
  transcriptor: transcriptor
)

# ============================================================================
# Composición
# ============================================================================

transport.sequencer.with scale: scale, voices: voices, transport: transport, decoder: decoder do |scale:, voices:, transport:, decoder:|
  @scale = scale
  @voices = voices
  @transport = transport
  @decoder = decoder

  def scale = @scale
  def transport = @transport
  def decoder = @decoder
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

puts "Iniciando Demo 04: Neumas"
puts "Notación musical textual"
puts "Presiona Ctrl+C para detener"
puts

transport.start

# ============================================================================
# Cleanup (cuando transport.start retorna)
# ============================================================================

output&.close
puts "Dispositivo MIDI cerrado."
