require 'musa-dsl'
require 'midi-communications'

include Musa::All

using Musa::Extension::Neumas

puts "MusaDSL #{Musa::VERSION}"

# MIDI setup

clock_input = MIDICommunications::Input.find_by_name('Clock')
output = MIDICommunications::Output.find_by_name('Main')

puts "Clock:  #{clock_input&.name || 'NOT FOUND'}"
puts "Output: #{output&.name || 'NOT FOUND'}"

# Transport: 4 beats/bar, 24 ticks/beat
clock = InputMidiClock.new(clock_input)
transport = Transport.new(clock, 4, 24, do_log: true)

# Scale
scale = Scales.et12[440.0].major[60]

# Transcriptor and decoder for neuma processing (if using GDV decorators in neumalang)
processor = Transcriptor.new(
  [FromGDV::ToMIDI::Trill.new(duration_factor: 1/8r),
   FromGDV::ToMIDI::Mordent.new(duration_factor: 1/8r),
   FromGDV::ToMIDI::Turn.new,
   FromGDV::Base.new,
   FromGDV::ToMIDI::Appogiatura.new],
  base_duration: 1/4r,
  tick_duration: 1/96r
)

decoder = Decoders::NeumaDecoder.new(scale, transcriptor: processor, base_duration: 1/4r)

# MIDI voices
voices = MIDIVoices.new(
  sequencer: transport.sequencer,
  output: output,
  channels: [0, 1, 2, 3]
)

transport.after_stop do
  voices.panic
  transport.logger.debug('main') { "Voices reset" }
end

# Sequencer context
transport.sequencer.with(
  voices: voices,
  scale: scale,
  decoder: decoder) do |voices:, scale:, decoder:|

  @voices = voices
  @scale = scale
  @decoder = decoder

  def v(n) = @voices.voices[n]
  def scale = @scale
  def decoder = @decoder

  # Helper para tocar neumas en una voz
  def neuma(serie, voice:)
    play(serie, mode: :neumalang, decoder: @decoder) do |note|
      voice.note(**note.to_pdv(@scale)) if note.is_a?(GDV)
    end
  end

  def reload
    puts 'Loading score.rb...'
    load 'score.rb'
    puts 'Score loaded.'
    extend TheScore
    score
  end

  transport.on_start do
    reload
  end
end

transport.start
