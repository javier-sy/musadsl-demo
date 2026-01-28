# Demo 08: Voice Leading - Composición
#
# Genera progresiones de acordes usando el sistema de Rules
# con reglas de conducción de voces estilo coral
# Usa sistema de eventos para encadenar secciones
#
# MODELO CORRECTO DE RULES:
# - Estado = array acumulativo (la melodía/progresión completa hasta ahora)
# - Cada grow rule = UN paso de transformación
# - Para N niveles de profundidad, se necesitan N grow rules
# - combinations retorna PATHS completos con estados intermedios
#
# IMPORTANTE: Toda la generación de material se realiza ANTES de at 1,
# para no afectar la temporización durante la ejecución.

module TheScore
  def score
    soprano = v(0)
    alto = v(1)
    tenor = v(2)
    bajo = v(3)

    # ========================================================================
    # FASE 1: GENERACIÓN DE MATERIAL (antes de la temporización)
    # ========================================================================

    puts "\n=== GENERANDO MATERIAL ==="

    # ------------------------------------------------------------------------
    # Material 1: Melodía con reglas de rango y saltos
    # ------------------------------------------------------------------------

    puts "\n[Generando] Melodías con reglas de rango y saltos..."

    melody_rules = Rules.new do
      7.times do
        grow 'next note' do |melody, max_interval:|
          last_pitch = melody.last
          (-max_interval..max_interval).each do |interval|
            next if interval.zero?
            branch melody + [last_pitch + interval]
          end
        end
      end

      cut 'range limit' do |melody|
        prune if melody.last < 60 || melody.last > 79
      end

      cut 'no immediate repeat' do |melody|
        prune if melody.size >= 2 && melody[-1] == melody[-2]
      end

      cut 'no consecutive leaps' do |melody|
        if melody.size >= 3
          prev_interval = (melody[-2] - melody[-3]).abs
          curr_interval = (melody[-1] - melody[-2]).abs
          prune if prev_interval > 4 && curr_interval > 4
        end
      end

      ended_when do |melody|
        melody.size == 8
      end
    end

    initial_pitch = scale.tonic.pitch
    tree = melody_rules.apply([[initial_pitch]], max_interval: 3)
    all_melodies = tree.combinations.map(&:last)
    selected_melody = all_melodies.sample

    puts "  #{all_melodies.size} melodías válidas"
    puts "  Seleccionada: #{selected_melody}" if selected_melody

    # ------------------------------------------------------------------------
    # Material 2: Progresión de acordes con funciones armónicas
    # ------------------------------------------------------------------------

    puts "\n[Generando] Progresiones armónicas..."

    chord_rules = Rules.new do
      5.times do
        grow 'chord progression' do |progression|
          last_chord = progression.last
          next_chords = case last_chord
            when :I then [:ii, :IV, :V, :vi]
            when :ii then [:V, :vii]
            when :IV then [:I, :V, :ii]
            when :V then [:I, :vi]
            when :vi then [:ii, :IV]
            when :vii then [:I]
            else []
          end
          next_chords.each { |chord| branch progression + [chord] }
        end
      end

      cut 'no immediate repeat' do |progression|
        prune if progression.size >= 2 && progression[-1] == progression[-2]
      end

      cut 'no consecutive dominants' do |progression|
        if progression.size >= 2
          dominant_chords = [:V, :vii]
          prune if dominant_chords.include?(progression[-1]) &&
                   dominant_chords.include?(progression[-2])
        end
      end

      ended_when do |progression|
        progression.size >= 4 && progression.last == :I
      end
    end

    tree = chord_rules.apply([[:I]])
    all_progressions = tree.combinations.map(&:last).select { |p| p.size >= 4 && p.size <= 6 }
    selected_progression = all_progressions.sample

    puts "  #{all_progressions.size} progresiones válidas"
    puts "  Seleccionada: #{selected_progression&.join(' - ')}" if selected_progression

    # Mapeo de símbolos a funciones armónicas
    symbol_to_function = {
      I: :tonic,
      ii: :supertonic,
      IV: :subdominant,
      V: :dominant,
      vi: :submediant,
      vii: :leading
    }

    # ------------------------------------------------------------------------
    # Material 3: Conducción de voces con movimiento mínimo
    # ------------------------------------------------------------------------

    puts "\n[Generando] Conducciones de voces..."

    vl_scale = Scales.et12[440.0].major[60]
    chord_sequence = [:tonic, :supertonic, :subdominant, :dominant, :tonic]
    progression_chords = chord_sequence.map { |func| vl_scale.send(func).chord.pitches }

    puts "  Progresión base:"
    chord_sequence.each_with_index do |func, i|
      puts "    #{i}: #{func} -> #{progression_chords[i]}"
    end

    voice_leading_rules = Rules.new do
      4.times do |step|
        grow "voicing step #{step}" do |states|
          last_state = states.last
          next_chord_index = last_state[:chord_index] + 1

          if next_chord_index < progression_chords.size
            target_pitches = progression_chords[next_chord_index]

            [0, 12].each do |offset|
              new_pitches = target_pitches.map { |p| p + offset }
              branch states + [{ pitches: new_pitches, chord_index: next_chord_index }]
            end
          end
        end
      end

      cut 'max voice movement' do |states|
        if states.size >= 2
          current_pitches = states[-1][:pitches]
          prev_pitches = states[-2][:pitches]

          total_movement = current_pitches.zip(prev_pitches).sum do |curr, prev|
            (curr - prev).abs
          end

          prune if total_movement > 24
        end
      end

      ended_when do |states|
        states.size == 5
      end
    end

    initial_state = [{ pitches: progression_chords[0], chord_index: 0 }]
    tree = voice_leading_rules.apply([initial_state])
    all_voicings = tree.combinations.map(&:last)
    selected_voicing = all_voicings.sample

    puts "  #{all_voicings.size} conducciones válidas"
    if selected_voicing
      puts "  Seleccionada:"
      selected_voicing.each_with_index { |s, i| puts "    #{i}: #{s[:pitches]}" }
    end

    # ------------------------------------------------------------------------
    # Material 4: Contrapunto simple a dos voces
    # ------------------------------------------------------------------------

    puts "\n[Generando] Contrapuntos..."

    cp_scale = Scales.et12[440.0].major[60]
    cantus_grades = [0, 1, 2, 3, 4, 3, 2, 1, 0]
    cantus = cantus_grades.map { |g| cp_scale[g].pitch }

    puts "  Cantus firmus (grados #{cantus_grades}): #{cantus}"

    counterpoint_rules = Rules.new do
      8.times do
        grow 'add counterpoint note' do |cp_notes|
          current_index = cp_notes.size
          cf_pitch = cantus[current_index]
          prev_cp = cp_notes.last

          consonant_intervals = [3, 4, 7, 8, 9, 12]
          consonant_intervals.each do |interval|
            new_pitch = cf_pitch + interval
            if (new_pitch - prev_cp).abs <= 7
              branch cp_notes + [new_pitch]
            end

            new_pitch = cf_pitch - interval
            if new_pitch >= 48 && (new_pitch - prev_cp).abs <= 7
              branch cp_notes + [new_pitch]
            end
          end
        end
      end

      cut 'no parallel fifths' do |cp_notes|
        if cp_notes.size >= 2
          curr_index = cp_notes.size - 1
          prev_index = curr_index - 1

          cf_current = cantus[curr_index]
          cf_prev = cantus[prev_index]
          cp_current = cp_notes[curr_index]
          cp_prev = cp_notes[prev_index]

          interval_curr = (cp_current - cf_current) % 12
          interval_prev = (cp_prev - cf_prev) % 12

          prune if interval_curr == 7 && interval_prev == 7
        end
      end

      ended_when do |cp_notes|
        cp_notes.size == cantus.size
      end
    end

    initial_cp_pitch = cp_scale[2].pitch
    tree = counterpoint_rules.apply([[initial_cp_pitch]])
    all_counterpoints = tree.combinations.map(&:last)
    selected_counterpoint = all_counterpoints.sample

    puts "  #{all_counterpoints.size} contrapuntos válidos"
    puts "  Seleccionado: #{selected_counterpoint}" if selected_counterpoint

    # ------------------------------------------------------------------------
    # Preparar Series (PDV individuales y Steps AbsD para contenedores)
    # ------------------------------------------------------------------------

    # Melodía: serie de PDV para soprano
    melody_pdvs = selected_melody.map do |pitch|
      { pitch: pitch, velocity: 75, duration: 1/8r }
    end

    # Progresión: cada acorde genera 4 PDVs (bajo, tenor, alto, soprano)
    progression_steps = selected_progression.map do |chord_symbol|
      func_name = symbol_to_function[chord_symbol]
      root_note = scale.send(func_name)
      pitches = root_note.chord.pitches
      {
        duration: 1/2r,  # duración del paso armónico
        symbol: chord_symbol,
        func_name: func_name,
        bajo:    { pitch: root_note.pitch - 12, velocity: 70, duration: 1/2r },
        tenor:   { pitch: pitches[0], velocity: 65, duration: 3/8r },
        alto:    { pitch: pitches[1], velocity: 65, duration: 3/8r },
        soprano: { pitch: pitches[2], velocity: 70, duration: 3/8r }
      }.extend(Musa::Datasets::AbsD)
    end

    # Conducción de voces: cada estado genera 4 PDVs
    voicing_steps = selected_voicing.map do |state|
      pitches = state[:pitches]
      {
        duration: 1/2r,  # duración del paso
        bajo:    { pitch: pitches[0] - 12, velocity: 70, duration: 1/2r },
        tenor:   { pitch: pitches[0], velocity: 65, duration: 3/8r },
        alto:    { pitch: pitches[1], velocity: 65, duration: 3/8r },
        soprano: { pitch: pitches[2], velocity: 70, duration: 3/8r }
      }.extend(Musa::Datasets::AbsD)
    end

    # Contrapunto: pares de PDV (cantus firmus + contrapunto)
    counterpoint_steps = cantus.zip(selected_counterpoint).map do |cf_pitch, cp_pitch|
      {
        duration: 1/4r,  # duración del paso
        cf: { pitch: cf_pitch, velocity: 70, duration: 1/4r },
        cp: { pitch: cp_pitch, velocity: 75, duration: 1/4r }
      }.extend(Musa::Datasets::AbsD)
    end

    puts "\n=== MATERIAL GENERADO, INICIANDO REPRODUCCIÓN ===\n"

    # ========================================================================
    # FASE 2: REPRODUCCIÓN (usando Series con play)
    # ========================================================================

    # ------------------------------------------------------------------------
    # Sección 1: Melodía
    # ------------------------------------------------------------------------

    on :play_melody do
      melody_serie = S(*melody_pdvs)

      control = play melody_serie do |pdv|
        soprano.note(**pdv)
      end

      control.after do
        wait 1/8r do
          puts "\n[Sección 2] Progresión armónica"
          launch :play_progression
        end
      end
    end

    # ------------------------------------------------------------------------
    # Sección 2: Progresión armónica
    # ------------------------------------------------------------------------

    on :play_progression do
      progression_serie = S(*progression_steps)

      control = play progression_serie do |chord|
        puts "  #{chord[:symbol]} (#{chord[:func_name]})"

        bajo.note(**chord[:bajo])
        tenor.note(**chord[:tenor])
        alto.note(**chord[:alto])
        soprano.note(**chord[:soprano])
      end

      control.after do
        wait 1/2r do
          puts "\n[Sección 3] Conducción de voces"
          launch :play_voicing
        end
      end
    end

    # ------------------------------------------------------------------------
    # Sección 3: Conducción de voces
    # ------------------------------------------------------------------------

    on :play_voicing do
      voicing_serie = S(*voicing_steps)

      control = play voicing_serie do |voices|
        bajo.note(**voices[:bajo])
        tenor.note(**voices[:tenor])
        alto.note(**voices[:alto])
        soprano.note(**voices[:soprano])
      end

      control.after do
        wait 1/2r do
          puts "\n[Sección 4] Contrapunto"
          launch :play_counterpoint
        end
      end
    end

    # ------------------------------------------------------------------------
    # Sección 4: Contrapunto
    # ------------------------------------------------------------------------

    on :play_counterpoint do
      counterpoint_serie = S(*counterpoint_steps)

      control = play counterpoint_serie do |pair|
        bajo.note(**pair[:cf])
        soprano.note(**pair[:cp])
      end

      control.after do
        wait 1/4r do
          puts "\n=== Demo de Voice Leading terminada! ==="
          transport.stop
        end
      end
    end

    # ------------------------------------------------------------------------
    # Inicio
    # ------------------------------------------------------------------------

    at 1 do
      puts "\n[Sección 1] Melodía"
      launch :play_melody
    end
  end
end
