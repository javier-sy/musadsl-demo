# Demo 20: Neuma Files & Transcriptor
#
# Demuestra:
# - Archivos .neu externos con variables
# - Transcriptor completo con ornamentos
# - Pipeline: Neuma → GDV → PDV → MIDI
#
# Ejecutar: ruby main.rb

require 'musa-dsl'
require 'midi-communications'

include Musa::Logger
include Musa::Clock
include Musa::Transport
include Musa::Sequencer
include Musa::Neumalang
include Musa::Neumas
include Musa::Scales
include Musa::MIDIVoices
include Musa::Datasets
include Musa::Transcription

using Musa::Extension::Neumas

# ============================================================================
# Banner
# ============================================================================

puts "=" * 60
puts "Demo 20: Neuma Files & Transcriptor"
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
# Escala
# ============================================================================

scale = Scales.et12[440.0].major[60]  # Do Mayor desde C4

# ============================================================================
# Transcriptor con ornamentos
# ============================================================================

# Pipeline de transcripción: usa el set completo de ornamentos
processor = Transcriptor.new(
  Musa::Transcriptors::FromGDV::ToMIDI.transcription_set(duration_factor: 1/8r),
  base_duration: 1/4r,
  tick_duration: 1/96r
)

# Decoder que usa el transcriptor
decoder = Musa::Neumas::Decoders::NeumaDecoder.new(
  scale,
  transcriptor: processor,
  base_duration: 1/4r
)

puts "Transcriptor configurado con ornamentos:"
puts "  - Trill (tr)"
puts "  - Mordent (mor)"
puts "  - Turn (turn)"
puts "  - Appogiatura (app)"
puts

# ============================================================================
# Voz MIDI
# ============================================================================

voices = MIDIVoices.new(
  sequencer: transport.sequencer,
  output: midi_output,
  channels: [0]
)

# ============================================================================
# Composición
# ============================================================================

transport.sequencer.with(scale: scale, transport: transport, voices: voices, decoder: decoder) do |scale:, transport:, voices:, decoder:|
  @scale = scale
  @transport = transport
  @voices = voices
  @decoder = decoder

  def scale = @scale
  def transport = @transport
  def voice = @voices.voices[0]
  def decoder = @decoder

  load 'score.rb'
  extend TheScore
  score
end

# ============================================================================
# Iniciar
# ============================================================================

puts "Archivo .neu: melody.neu"
puts "  - Variables: @motif, @motif_tr, @motif_up, @var1, @phrase, @parallel_demo"
puts "  - Operaciones: .reverse, ||"
puts "  - Ornamentos: tr (trino), mor (mordente)"
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
