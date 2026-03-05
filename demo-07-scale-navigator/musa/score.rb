# Demo 07: Scale Navigator - Composición
#
# Explora el sistema de escalas: modos, escalas exóticas, acordes, índices
#
# APIS DE ESCALA
# ==============
#
# Construcción:
#   Scales.et12[440.0].major[60]     → Do Mayor (MIDI 60)
#   Scales.et12[440.0].send(:dorian) → Acceso dinámico por símbolo
#
# Grados:
#   scale[n]                         → Nota en grado n (soporta negativos)
#   scale.tonic, .dominant, etc.     → Por función armónica
#
# Acordes:
#   nota.chord                       → Tríada básica
#   nota.chord(:seventh)             → Acorde de séptima

module TheScore
  def score
    melody = v(0)
    chords = v(1)
    bass = v(2)

    tuning = Scales.et12[440.0]

    # ==== Helper: tocar grados de una escala ====

    def play_grades(voice, the_scale, grades, duration: 1/8r, velocity: 75, &after_block)
      series = H(
        grade: S(*grades),
        duration: S(duration).repeat(grades.size)
      )

      control = play series do |note|
        voice.note(the_scale[note[:grade]].pitch, velocity: velocity, duration: note[:duration])
      end

      control.after(&after_block) if after_block
      control
    end

    # ==== Helper: iterar items con eventos ====

    def play_items(event_name, items, next_event:, &block)
      on event_name do |index|
        if index < items.size
          block.call(items[index], index)
        else
          wait(1/4r) { launch next_event, 0 }
        end
      end
    end

    # ========================================================================
    # Sección 1: Escalas y modos
    # ========================================================================

    scales_to_explore = [
      [:major,          "Mayor (Jónico) ★"],
      [:dorian,         "Dórico"],
      [:phrygian,       "Frigio"],
      [:lydian,         "Lidio"],
      [:mixolydian,     "Mixolidio"],
      [:minor,          "Menor (Eólico) ★"],
      [:locrian,        "Locrio"],
      [:hungarian_minor, "Húngara menor"],
      [:whole_tone,      "Tonos enteros"]
    ]

    play_items :scales, scales_to_explore, next_event: :harmonic_progression do |item, index|
      scale_name, description = item

      if index == 0
        puts "\n[Sección 1] Escalas y modos"
        base = tuning.major[60]
        puts "  Grados: #{base.kind.class.grades} | Tónica: #{base.tonic.pitch} | Dominante: #{base.dominant.pitch}"
      end

      current_scale = tuning.send(scale_name)[60]
      num_grades = current_scale.kind.class.grades
      puts "\n  #{description} (#{num_grades} grados)"

      play_grades(melody, current_scale, (0..num_grades).to_a, velocity: 75) do
        # Acorde tónica del modo
        tonic_chord = current_scale.tonic.chord
        puts "    Acorde tónica: #{tonic_chord.pitches}"
        chords.note(tonic_chord.pitches, velocity: 65, duration: 1/2r)

        wait(1/2r) { launch :scales, index + 1 }
      end
    end

    # ========================================================================
    # Sección 2: Progresión armónica I - IV - V7 - I
    # ========================================================================

    progression = [
      [:tonic,       "I (Tónica)"],
      [:subdominant, "IV (Subdominante)"],
      [:dominant,    "V7 (Dominante)"],
      [:tonic,       "I (Tónica)"]
    ]

    play_items :harmonic_progression, progression, next_event: :extended_navigation do |item, index|
      func_name, name = item
      chord_scale = tuning.major[60]

      puts "\n[Sección 2] Progresión I - IV - V7 - I" if index == 0

      root_note = chord_scale.send(func_name)

      # V7 lleva séptima, el resto tríada
      chord = func_name == :dominant ?
                root_note.chord(:seventh, allow_chromatic: false) :
                root_note.chord

      puts "  #{name}: #{chord.pitches}"

      bass.note(root_note.pitch - 12, velocity: 75, duration: 1r)
      chords.note(chord.pitches, velocity: 70, duration: 7/8r)

      wait(7/8r) do
        melody.note(chord.pitches.last + 12, velocity: 80, duration: 1/8r)
        wait(1/8r) { launch :harmonic_progression, index + 1 }
      end
    end

    # ========================================================================
    # Sección 3: Índices negativos y extendidos
    # ========================================================================

    on :extended_navigation do
      puts "\n[Sección 3] Índices de escala extendidos"

      nav_scale = tuning.major[60]
      extended_grades = (-2..9).to_a

      puts "  Grados: #{extended_grades}"
      puts "  Pitches: #{extended_grades.map { |g| nav_scale[g].pitch }}"

      play_grades(melody, nav_scale, extended_grades,
                  velocity: 75) do
        wait(1/4r) do
          puts "\n¡Demo de Scale Navigator terminada!"
          transport.stop
        end
      end
    end

    # ========================================================================
    # Inicio
    # ========================================================================

    at 1 do
      launch :scales, 0
    end
  end
end
