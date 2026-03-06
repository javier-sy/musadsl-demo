# Demo 14: Clock Modes - Score (compartido)
#
# Esta composición funciona tanto en modo Master como Slave.
# La diferencia está en quién controla el tempo, no en la música.
#
# Estructura: 4 secciones encadenadas con on/launch

module TheScore
  def score
    melody = v(0)
    chords = v(1)

    puts "\n=== Composición iniciada ==="
    puts "Esta misma música suena igual en ambos modos."
    puts "La diferencia es QUIÉN controla el tempo.\n"

    # ========================================================================
    # Sección 1: Melodía ascendente
    # ========================================================================

    on :melodia do
      puts "[Sección 1] Melodía ascendente"

      serie = H(grade: S(0, 2, 4, 5, 7, 5, 4, 2),
                duration: S(1/4r).repeat)

      control = play serie do |grade:, duration:|
        melody.note(scale[grade].pitch, velocity: 75, duration: 3/16r)
      end

      control.after { launch :acordes }
    end

    # ========================================================================
    # Sección 2: Progresión I - V - vi - IV
    # ========================================================================

    chord_roots = [0, 4, 5, 3]

    on :acordes do
      puts "[Sección 2] Progresión I - V - vi - IV"

      serie = H(root: S(*chord_roots),
                duration: S(1/2r).repeat)

      control = play serie do |root:, duration:|
        chord = scale[root].chord
        melody.note(chord.root.pitch - 12, velocity: 70, duration: 3/8r)
        chords.note(chord.pitches, velocity: 65, duration: 3/8r)
      end

      control.after { launch :patron }
    end

    # ========================================================================
    # Sección 3: Patrón rítmico + acordes de fondo
    # ========================================================================

    on :patron do
      puts "[Sección 3] Patrón rítmico"
      puts "            (sensible a cambios de tempo en modo Slave)"

      # Acordes de fondo: un acorde cada compás
      chord_i = 0
      bg = every 1r do
        chord = scale[chord_roots[chord_i % chord_roots.size]].chord
        chords.note(chord.pitches, velocity: 55, duration: 7/8r)
        chord_i += 1
      end

      # Patrón de semicorcheas encima
      grades = [0, 4, 2, 5, 4, 7, 5, 4]
      velocities = 32.times.map { |i| 65 + (i % 4) * 8 }

      serie = H(grade: S(*grades).repeat.max_size(32),
                velocity: S(*velocities),
                duration: S(1/8r).repeat)

      control = play serie do |grade:, velocity:, duration:|
        melody.note(scale[grade].pitch, velocity: velocity, duration: 1/16r)
      end

      control.after do
        bg.stop
        launch :finale
      end
    end

    # ========================================================================
    # Sección 4: Finale
    # ========================================================================

    on :finale do
      puts "[Sección 4] Finale"

      # Melodía descendente
      serie = H(grade: S(7, 5, 4, 2, 0),
                duration: S(1/4r).repeat)

      control = play serie do |grade:, duration:|
        melody.note(scale[grade].pitch, velocity: 78, duration: 3/16r)
      end

      # Cadencia V → I
      control.after do
        puts "  Cadencia V - I"
        chord_v = scale[4].chord
        melody.note(chord_v.root.pitch - 12, velocity: 75, duration: 1r)
        chords.note(chord_v.pitches, velocity: 70, duration: 7/8r)

        wait 1r do
          chord_i = scale[0].chord(:seventh)
          melody.note(chord_i.root.pitch - 12, velocity: 80, duration: 2r)
          chords.note(chord_i.pitches, velocity: 85, duration: 2r)

          wait 2r do
            puts "\n=== Composición terminada ==="
            launch :finished
          end
        end
      end
    end

    # ========================================================================
    # Inicio
    # ========================================================================

    at 1 do
      launch :melodia
    end
  end
end
