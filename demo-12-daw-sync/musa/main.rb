# Demo 12: DAW Sync - Sincronización con DAW (Slave Clock)
#
# En este modo, el DAW (Bitwig, Ableton, etc.) es el MASTER del tempo.
# musa-dsl espera recibir MIDI Clock del DAW y sincroniza sus eventos.
#
# IMPORTANTE: Este script se bloquea esperando MIDI Start del DAW.
# Debes presionar PLAY en tu DAW para que comience la música.
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

puts "=" * 60
puts "Demo 12: DAW Sync - Modo Slave Clock"
puts "=" * 60
puts

puts "Selecciona el puerto MIDI de entrada (Clock desde el DAW):"
clock_input = MIDICommunications::Input.gets
puts
puts "Selecciona el puerto MIDI de salida (notas hacia el DAW):"
output = MIDICommunications::Output.gets

# ============================================================================
# Clock SLAVE (InputMidiClock) - El DAW controla el tempo
# ============================================================================

clock = InputMidiClock.new(clock_input)

# ============================================================================
# Transport
# ============================================================================

transport = Transport.new(clock, 4, 24, do_log: true)

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
# Callbacks del Transport
# ============================================================================

transport.on_start do
  puts "\n>>> DAW envió MIDI Start - ¡Comenzando!"
  puts "    El tempo está controlado por el DAW"
end

transport.after_stop do
  puts "\n>>> DAW envió MIDI Stop - Deteniendo"
  voices.panic  # Enviar note-off a todas las notas
end

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

  # En modo slave, cada Play del DAW re-carga el score fresco.
  # Esto permite editar score.rb entre stop/play sin reiniciar el script.
  transport.on_start do
    load 'score.rb'
    extend TheScore
    score
  end
end

# ============================================================================
# Iniciar (ESPERA al DAW)
# ============================================================================

puts
puts "=" * 60
puts "ESPERANDO MIDI START DEL DAW..."
puts "Presiona PLAY en tu DAW (Bitwig, Ableton, etc.)"
puts "El script se bloqueará hasta recibir MIDI Start"
puts "=" * 60
puts
puts "Configuración del DAW requerida:"
puts "  1. Habilitar MIDI Clock Output hacia musa-dsl"
puts "  2. Habilitar envío de Start/Stop/Continue"
puts "  3. Asegurarse que el puerto MIDI correcto está seleccionado"
puts
puts "Presiona Ctrl+C para cancelar"
puts

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

transport.start
