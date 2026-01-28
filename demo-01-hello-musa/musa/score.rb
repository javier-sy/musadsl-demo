# Demo 01: Hello Musa - Composición
#
# Una melodía simple de 9 notas en Do Mayor
# Demuestra: scheduling con at(), acceso a grados de escala, notas MIDI
#
# NOTA: Para melodías más complejas, ver demo-02 que introduce
# el patrón idiomático con series y play()

module TheScore
  def score
    # Referencia a la voz MIDI
    voice = v(0)

    # Melodía: Do Re Mi Fa Sol Fa Mi Re Do
    # Grados:   0  1  2  3  4   3  2  1  0
    melody = [0, 1, 2, 3, 4, 3, 2, 1, 0]

    # Programar cada nota (cada 1/2 beat)
    melody.each_with_index do |grade, index|
      at 1 + index * 1/2r do
        pitch = scale[grade].pitch
        voice.note(pitch, velocity: 80, duration: 3/8r)
        puts "Beat #{position}: Grado #{grade} -> MIDI #{pitch}"
      end
    end

    # Acorde final (después de 9 notas a 1/2 beat = 4.5 beats, última nota en 5)
    at 6 do
      chord_pitches = [0, 2, 4].map { |g| scale[g].pitch }
      voice.note(chord_pitches, velocity: 100, duration: 1)
      puts "Beat #{position}: Acorde final Do Mayor"

      wait 1 do |_|
        puts "\n¡Composición terminada!"
        transport.stop
      end
    end
  end
end
