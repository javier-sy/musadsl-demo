# Demo 01: Hello Musa - Primera secuencia musical
#
# Esta demo introduce los conceptos fundamentales de musa-dsl:
# - Escalas musicales
# - TimerClock (musa-dsl como master clock)
# - Transport y Sequencer
# - Scheduling de eventos con at()
# - MIDIVoices para salida MIDI
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
# Configuración del Clock y Transport
# ============================================================================

# TimerClock: musa-dsl controla el tempo (Master Clock)
# NOTA: TimerClock empieza pausado y requiere clock.start para comenzar
clock = TimerClock.new(bpm: 120, ticks_per_beat: 24)

# Transport conecta el clock con el sequencer
# Parámetros: clock, beats_per_bar, ticks_per_beat
transport = Transport.new(clock, 4, 24, do_log: true)

# Con TimerClock, necesitamos iniciar el clock explícitamente
# Lo hacemos en before_begin con un pequeño delay para que clock.run esté activo
transport.before_begin do
  Thread.new do
    sleep 0.1
    clock.start
  end
end

# ============================================================================
# Configuración de la Escala
# ============================================================================

# Sistema de escalas: 12-TET (temperamento igual), La = 440 Hz
# .major[60] = escala mayor comenzando en MIDI note 60 (Do central)
scale = Scales.et12[440.0].major[60]

puts "Escala: Do Mayor"
puts "Notas: #{(0..7).map { |g| scale[g].pitch }}"
puts

# ============================================================================
# Configuración de Voces MIDI
# ============================================================================

# MIDIVoices gestiona voces polifónicas sincronizadas con el sequencer
voices = MIDIVoices.new(
  sequencer: transport.sequencer,
  output: output,
  channels: [0],  # Canal MIDI 1 (0-indexed)
  do_log: true
)

# ============================================================================
# Programación de la Composición
# ============================================================================

transport.sequencer.with voices: voices, scale: scale, transport: transport do |voices:, scale:, transport:|
  @voices = voices
  @scale = scale
  @transport = transport

  def v(n) = @voices.voices[n]
  def scale = @scale
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

puts "Iniciando reproducción..."
puts "Presiona Ctrl+C para detener"
puts

transport.start  # Esto bloquea hasta que se llame transport.stop

# ============================================================================
# Cleanup (cuando transport.start retorna)
# ============================================================================

output&.close
puts "Dispositivo MIDI cerrado."
