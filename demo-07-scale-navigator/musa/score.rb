# Demo 07: Scale Navigator - Composición
#
# Explora el sistema de escalas: modos, escalas exóticas, acordes, índices
# Usa sistema de eventos para encadenar secciones
#
# APIS DE ESCALA
# ==============
#
# Construcción de escalas:
#   Scales.et12[440.0].major[60]     → Do Mayor (MIDI 60)
#   Scales.et12[440.0].dorian[62]    → Re Dórico
#   Scales.et12[440.0].send(:minor)  → Acceso dinámico por símbolo
#
# Propiedades de escala:
#   scale.kind.class.grades          → Número de grados (7 para diatónicas)
#   scale[n]                         → Nota en grado n (soporta negativos)
#
# Funciones armónicas:
#   .tonic, .supertonic, .mediant, .subdominant,
#   .dominant, .submediant, .leading
#
# API de acordes:
#   nota.chord                       → Tríada básica
#   nota.chord(:seventh)             → Acorde de séptima
#   nota.chord(:seventh, allow_chromatic: false) → Sin alteraciones

module TheScore
  def score
    melody = v(0)
    chords = v(1)
    bass = v(2)

    # ========================================================================
    # Sección 1: Modos griegos (incluye Mayor y Menor)
    # ========================================================================

    modes = [
      [:major, "Jónico (MAYOR)", true],      # Destacar
      [:dorian, "Dórico", false],
      [:phrygian, "Frigio", false],
      [:lydian, "Lidio", false],
      [:mixolydian, "Mixolidio", false],
      [:minor, "Eólico (MENOR)", true],      # Destacar
      [:locrian, "Locrio", false]
    ]

    on :greek_modes do |index|
      if index == 0
        puts "\n[Sección 1] Modos griegos"
        puts "  Mayor (Jónico) y Menor (Eólico) son los más comunes"

        # Mostrar información de la escala base
        base_scale = Scales.et12[440.0].major[60]
        num_grades = base_scale.kind.class.grades
        puts "  Grados por escala: #{num_grades}"
        puts "  Funciones: tónica=#{base_scale.tonic.pitch}, dominante=#{base_scale.dominant.pitch}"
      end

      if index < modes.size
        mode_name, description, is_common = modes[index]
        mode_scale = Scales.et12[440.0].send(mode_name)[60]

        marker = is_common ? " ★" : ""
        puts "\n  #{description}#{marker}"

        # Escala completa (8 notas: grados 0-7 incluyendo octava)
        grades = S(*(0..7).to_a)
        durations = S(1/8r).repeat(8)
        mode_melody = H(grade: grades, duration: durations)

        control = play mode_melody do |note|
          pitch = mode_scale[note[:grade]].pitch
          vel = is_common ? 80 : 70
          melody.note(pitch, velocity: vel, duration: note[:duration])
        end

        control.after do
          # Acorde tónica del modo
          tonic_chord = mode_scale.tonic.chord
          puts "    Acorde tónica: #{tonic_chord.pitches}"
          chords.note(tonic_chord.pitches, velocity: 65, duration: 1/2r)

          wait 1/2r do |_|
            launch :greek_modes, index + 1
          end
        end
      else
        wait 1/4r do |_|
          launch :exotic_scales, 0
        end
      end
    end

    # ========================================================================
    # Sección 2: Escalas exóticas
    # ========================================================================

    exotic = [
      [:hungarian_minor, "Húngara menor"],
      [:whole_tone, "Tonos enteros"],
      [:diminished_hw, "Disminuida (half-whole)"]
    ]

    on :exotic_scales do |index|
      if index == 0
        puts "\n[Sección 2] Escalas exóticas"
      end

      if index < exotic.size
        scale_name, description = exotic[index]

        begin
          exotic_scale = Scales.et12[440.0].send(scale_name)[60]
          puts "  #{description}"

          grades = S(0, 1, 2, 3, 4, 3, 2, 1)
          durations = S(1/8r).repeat(8)
          pattern = H(grade: grades, duration: durations)

          bass.note(exotic_scale[0].pitch - 12, velocity: 70, duration: 1)

          control = play pattern do |note|
            pitch = exotic_scale[note[:grade]].pitch
            melody.note(pitch, velocity: 72, duration: note[:duration])
          end

          control.after { launch :exotic_scales, index + 1 }
        rescue
          puts "  #{description} (no disponible)"
          launch :exotic_scales, index + 1
        end
      else
        wait 1/4r do |_|
          launch :harmonic_progression, 0
        end
      end
    end

    # ========================================================================
    # Sección 3: Progresión armónica I - IV - V7 - I
    # ========================================================================

    progression = [
      [:tonic, "I (Tónica)", false],
      [:subdominant, "IV (Subdominante)", false],
      [:dominant, "V7 (Dominante)", true],   # Con séptima
      [:tonic, "I (Tónica)", false]
    ]

    on :harmonic_progression do |index|
      if index == 0
        puts "\n[Sección 3] Progresión I - IV - V7 - I (cadencia perfecta)"
      end

      chord_scale = Scales.et12[440.0].major[60]

      if index < progression.size
        func_name, name, use_seventh = progression[index]
        root_note = chord_scale.send(func_name)

        # Construir acorde (con o sin séptima)
        chord = use_seventh ?
                root_note.chord(:seventh, allow_chromatic: false) :
                root_note.chord
        chord_pitches = chord.pitches

        puts "  #{name}: #{chord_pitches}"

        bass_pitch = root_note.pitch - 12
        is_final = (index == progression.size - 1)

        # Duraciones: más largas para el acorde final
        bass_dur = is_final ? 3/2r : 1
        chord_dur = is_final ? 3/2r : 7/8r

        bass.note(bass_pitch, velocity: is_final ? 80 : 75, duration: bass_dur)
        chords.note(chord_pitches, velocity: is_final ? 85 : 70, duration: chord_dur)

        if is_final
          # Melodía en la tónica superior para cerrar
          melody.note(chord_pitches.last + 12, velocity: 90, duration: 3/2r)

          wait 2 do |_|
            launch :extended_navigation
          end
        else
          wait(7/8r) do |_|
            melody.note(chord_pitches.last + 12, velocity: 80, duration: 1/8r)
            wait(1/8r) { launch :harmonic_progression, index + 1 }
          end
        end
      end
    end

    # ========================================================================
    # Sección 4: Índices negativos y extendidos
    # ========================================================================

    on :extended_navigation do
      puts "\n[Sección 4] Índices de escala extendidos"

      nav_scale = Scales.et12[440.0].major[60]

      # scale[n] soporta cualquier entero:
      # negativos → octavas inferiores
      # >6 → octavas superiores
      extended_grades = [-2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
      puts "  Grados: #{extended_grades}"
      puts "  Pitches: #{extended_grades.map { |g| nav_scale[g].pitch }}"

      grades = S(*extended_grades)
      durations = S(1/8r).repeat(extended_grades.size)
      velocities = S(*extended_grades.map { |g| g >= 0 && g <= 6 ? 80 : 60 })
      extended = H(grade: grades, duration: durations, velocity: velocities)

      control = play extended do |note|
        pitch = nav_scale[note[:grade]].pitch
        melody.note(pitch, velocity: note[:velocity], duration: note[:duration])
      end

      control.after do
        wait 1/4r do |_|
          puts "\n¡Demo de Scale Navigator terminada!"
          transport.stop
        end
      end
    end

    # ========================================================================
    # Inicio
    # ========================================================================

    at 1 do
      launch :greek_modes, 0
    end
  end
end
