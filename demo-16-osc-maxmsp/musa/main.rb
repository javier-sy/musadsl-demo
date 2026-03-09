# Demo 16: OSC Max/MSP - Secuenciador Reactivo
#
# musa-dsl genera notas algorítmicamente y las envía a Max/MSP via OSC.
# Max/MSP envía parámetros de control (root, mode, density, register)
# que modifican la generación en tiempo real.
#
# Arquitectura push: InputHandler recibe OSC y lanza eventos en el sequencer.
# OscOutput envía notas generadas a Max.
#
# PUERTOS:
#   musa-dsl escucha en 8000 (recibe params de Max)
#   musa-dsl envía a   8001 (envía notas a Max)
#
# Ejecutar: ruby main.rb

require 'musa-dsl'

require_relative 'input_handler'
require_relative 'osc_output'

include Musa::Clock
include Musa::Transport
include Musa::Sequencer
include Musa::Scales

# ============================================================================
# Banner
# ============================================================================

puts "=" * 60
puts "Demo 16: OSC Max/MSP - Secuenciador Reactivo"
puts "=" * 60
puts

# ============================================================================
# Clock y Transport (Master)
# ============================================================================

BPM = 120

clock = TimerClock.new(bpm: BPM, ticks_per_beat: 24)
transport = Transport.new(clock, 4, 24, do_log: false)

transport.before_begin do
  Thread.new do
    sleep 0.1
    clock.start
  end
end

puts "Clock: TimerClock (Master) a #{BPM} BPM"
puts

# ============================================================================
# Configuración OSC
# ============================================================================

OSC_IN_PORT = 8000   # Recibe params de Max
OSC_OUT_HOST = 'localhost'
OSC_OUT_PORT = 8001  # Envía notas a Max

input = InputHandler.new(
  port: OSC_IN_PORT,
  sequencer: transport.sequencer,
  do_log: true
)

osc_out = OscOutput.new(host: OSC_OUT_HOST, port: OSC_OUT_PORT)

puts "  Recibe de Max: puerto #{OSC_IN_PORT}"
puts "  Envía a Max:   #{OSC_OUT_HOST}:#{OSC_OUT_PORT}"
puts

# ============================================================================
# Iniciar servidor OSC
# ============================================================================

input.start

# ============================================================================
# Composición
# ============================================================================

transport.sequencer.with input: input, osc_out: osc_out, bpm: BPM do |input:, osc_out:, bpm:|
  @input = input
  @osc_out = osc_out
  @bpm = bpm

  def input = @input
  def osc_out = @osc_out
  def bpm = @bpm

  load 'score.rb'
  extend TheScore
  score
end

# ============================================================================
# Manejo de Ctrl+C para cierre limpio
# ============================================================================

Signal.trap('INT') do
  puts "\n\nInterrumpido por usuario"
  input.stop
  transport.stop
  exit 0
end

# ============================================================================
# Iniciar
# ============================================================================

puts "Asegúrate de que Max/MSP está ejecutando con el patch."
puts "  - Max envía params a puerto #{OSC_IN_PORT}"
puts "  - Max recibe notas en puerto #{OSC_OUT_PORT}"
puts
puts "Presiona Ctrl+C para detener"
puts

transport.start

# ============================================================================
# Cleanup
# ============================================================================

input.stop
puts "Conexión OSC cerrada."
