# Demo 12: DAW Sync - Composición
#
# Esta composición se sincroniza con el tempo del DAW.
# Cuando cambias el tempo en el DAW, musa-dsl sigue automáticamente.
#
# Estructura: 4 secciones encadenadas con on/launch

module TheScore
  def score
    melody = v(0)
    chords = v(1)

    # ========================================================================
    # El tempo viene del DAW - musa-dsl solo genera las notas
    # ========================================================================

    puts "\n[score.rb] Programando eventos sincronizados con DAW"

    # ========================================================================
    # Compases 1-2: Arpegio ascendente/descendente
    # ========================================================================

    on :arpegio do
      puts "[Compás 1] Arpegio ascendente/descendente"

      chord = scale[0].chord(:seventh)
      pitches = chord.pitches

      arp = H(pitch: S(*pitches, *pitches.reverse),
              duration: S(1/4r).repeat)

      control = play arp do |pitch:, duration:|
        melody.note(pitch, velocity: 75, duration: duration)
      end

      control.after { launch :acordes }
    end

    # ========================================================================
    # Compases 3-6: Progresión de acordes I-IV-V-I (1 compás cada uno)
    # ========================================================================

    on :acordes do
      puts "[Compás 3] Progresión de acordes I-IV-V-I"

      progression = H(grade: S(0, 3, 4, 0),
                      duration: S(1r).repeat)

      control = play progression do |grade:, duration:|
        chord = scale[grade].chord
        puts "  Acorde grado #{grade}: #{chord.chord_definition.name}"
        chords.note(chord.pitches, velocity: 70, duration: duration)
        melody.note(scale[grade].pitch - 12, velocity: 72, duration: duration)
      end

      control.after { launch :patron }
    end

    # ========================================================================
    # Compases 7-8: Patrón repetitivo (para probar cambios de tempo)
    # ========================================================================

    on :patron do
      puts "[Compás 7] Patrón repetitivo - ¡Prueba a cambiar el tempo en el DAW!"

      pattern = H(grade: S(0, 2, 4, 2).repeat.max_size(16),
                  velocity: S(65, 70, 75, 80).repeat,
                  duration: S(1/8r).repeat)

      control = play pattern do |grade:, velocity:, duration:|
        melody.note(scale[grade].pitch, velocity: velocity, duration: duration)
      end

      control.after { launch :final }
    end

    # ========================================================================
    # Compases 9-12: Melodía final y acorde conclusivo
    # ========================================================================

    on :final do
      puts "[Compás 9] Melodía final"

      mel = H(grade: S(4, 5, 7, 5, 4, 2, 0),
              duration: S(1/4r).repeat)

      control = play mel do |grade:, duration:|
        melody.note(scale[grade].pitch, velocity: 78, duration: duration)
      end

      # Acorde final (compás 11)
      control.after do
        puts "\n[Compás 11] Acorde final"
        chord = scale[0].chord(:seventh)
        chords.note(chord.pitches, velocity: 85, duration: 2r)
        melody.note(scale[0].pitch - 12, velocity: 80, duration: 2r)

        wait 2r do
          puts "\nComposición terminada - Presiona STOP en el DAW"
        end
      end
    end

    # ========================================================================
    # Inicio
    # ========================================================================

    at 1 do
      launch :arpegio
    end
  end
end
