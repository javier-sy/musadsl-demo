# Demo 08: Voice Leading - Composición
#
# Genera voicings SATB para una progresión con modulación.
#
# ARQUITECTURA: Rules + control externo
#
# Un solo Rules con grows (inversión, duplicación) y cuts (locales +
# conducción de voces). Un bucle externo recorre la progresión acorde
# por acorde, pasando el contexto (voicings anteriores) como parámetros.
#
# Para cada acorde de la progresión:
#   1. El bucle llama a Rules con el acorde + prev_pitches + prev2_pitches
#   2. Rules genera variantes (3 inversiones × 3 duplicaciones, o ×1 si séptima)
#   3. Los cuts locales filtran por rango y separación
#   4. Los cuts de conducción filtran por movimiento, paralelas, dirección
#   5. Los voicings supervivientes extienden las secuencias acumuladas
#
# PROGRESIÓN: C: I - IV - V → G: IV - V → C: IV - V - I

module TheScore
  def score
    soprano = v(0)
    alto = v(1)
    tenor = v(2)
    bajo = v(3)

    # ========================================================================
    # Reglas de voicing: generación + todos los constraints
    # ========================================================================

    voicing_rules = Rules.new do

      # --- Grows: generan variantes del acorde ---

      grow 'inversión' do |chord|
        branch chord                                # Posición fundamental
        branch chord.with_move(root: 1)             # 1ª inversión (3ª en bajo)
        branch chord.with_move(root: 1, third: 1)   # 2ª inversión (5ª en bajo)
      end

      grow 'duplicación' do |chord|
        if chord.pitches.size < 4
          branch chord.with_duplicate(root: 1)      # Doblar fundamental arriba
          branch chord.with_duplicate(root: -1)     # Doblar fundamental abajo
          branch chord.with_duplicate(fifth: 1)     # Doblar quinta arriba
        else
          branch chord                              # Ya tiene 4+ notas (séptima)
        end
      end

      # --- Cuts locales (no dependen de contexto) ---

      cut 'rango SATB' do |chord, prev_pitches: nil, prev2_pitches: nil|
        pitches = chord.pitches
        if pitches.size >= 4
          prune if pitches[0] < 40 || pitches[0] > 60  # Bajo:    E2–C4
          prune if pitches[1] < 48 || pitches[1] > 67  # Tenor:   C3–G4
          prune if pitches[2] < 55 || pitches[2] > 74  # Alto:    G3–D5
          prune if pitches[3] < 60 || pitches[3] > 81  # Soprano: C4–A5
        end
      end

      cut 'separación voces' do |chord, prev_pitches: nil, prev2_pitches: nil|
        pitches = chord.pitches
        if pitches.size >= 4
          (0...pitches.size - 1).each do |i|
            prune if pitches[i + 1] - pitches[i] > 12
          end
        end
      end

      # --- Cuts de conducción (usan contexto de pasos anteriores) ---

      cut 'movimiento máximo' do |chord, prev_pitches: nil, prev2_pitches: nil|
        if prev_pitches
          pitches = chord.pitches
          if pitches.size >= 4
            total = pitches.zip(prev_pitches).sum { |c, p| (c - p).abs }
            prune if total > 24
          end
        end
      end

      cut 'quintas paralelas' do |chord, prev_pitches: nil, prev2_pitches: nil|
        if prev_pitches
          pitches = chord.pitches
          if pitches.size >= 4
            (0..3).to_a.combination(2).each do |i, j|
              curr = (pitches[j] - pitches[i]) % 12
              prev = (prev_pitches[j] - prev_pitches[i]) % 12
              if curr == 7 && prev == 7
                dir_i = pitches[i] <=> prev_pitches[i]
                dir_j = pitches[j] <=> prev_pitches[j]
                prune if dir_i == dir_j && dir_i != 0
              end
            end
          end
        end
      end

      # Si una voz bajó, debe subir o mantenerse; si subió, debe bajar o mantenerse
      cut 'movimiento contrario' do |chord, prev_pitches: nil, prev2_pitches: nil|
        if prev_pitches && prev2_pitches
          pitches = chord.pitches
          if pitches.size >= 4
            (0..3).each do |i|
              prev_dir = prev_pitches[i] <=> prev2_pitches[i]
              curr_dir = pitches[i] <=> prev_pitches[i]
              prune if prev_dir == -1 && curr_dir == -1  # bajó dos veces
              prune if prev_dir == 1 && curr_dir == 1    # subió dos veces
            end
          end
        end
      end

      cut 'octavas paralelas' do |chord, prev_pitches: nil, prev2_pitches: nil|
        if prev_pitches
          pitches = chord.pitches
          if pitches.size >= 4
            (0..3).to_a.combination(2).each do |i, j|
              curr = (pitches[j] - pitches[i]) % 12
              prev = (prev_pitches[j] - prev_pitches[i]) % 12
              if curr == 0 && prev == 0
                dir_i = pitches[i] <=> prev_pitches[i]
                dir_j = pitches[j] <=> prev_pitches[j]
                prune if dir_i == dir_j && dir_i != 0
              end
            end
          end
        end
      end
    end

    # ========================================================================
    # Progresión con modulación: C mayor → G mayor → C mayor
    # ========================================================================

    tuning = Scales.et12[440.0]
    c_major = tuning.major[48]   # C3 — tríadas en registro medio-bajo
    g_major = tuning.major[43]   # G2 — para que IV(C3) y V(D3) queden en rango

    progression_steps = [
      { scale: c_major, func: :tonic,       label: "C: I" },
      { scale: c_major, func: :subdominant, label: "C: IV" },
      { scale: c_major, func: :dominant,    label: "C: V7", quality: :seventh },
      # Modulación a G mayor (V de C = I de G, acorde pivote)
      { scale: g_major, func: :subdominant, label: "G: IV" },
      { scale: g_major, func: :dominant,    label: "G: V7", quality: :seventh },
      # Vuelta a C mayor
      { scale: c_major, func: :subdominant, label: "C: IV" },
      { scale: c_major, func: :dominant,    label: "C: V7", quality: :seventh },
      { scale: c_major, func: :tonic,       label: "C: I" },
    ]

    # ========================================================================
    # Control externo: acumula secuencias válidas paso a paso
    # ========================================================================

    puts "\n=== GENERANDO VOICINGS ==="

    sequences = [[]]  # Una secuencia vacía inicial

    progression_steps.each_with_index do |step, step_i|
      root = step[:scale].send(step[:func])
      chord = step[:quality] ? root.chord(step[:quality]) : root.chord
      new_sequences = []

      sequences.each do |seq|
        prev_pitches = seq[-1] if seq.size >= 1
        prev2_pitches = seq[-2] if seq.size >= 2

        tree = voicing_rules.apply([chord],
                                   prev_pitches: prev_pitches,
                                   prev2_pitches: prev2_pitches)
        voicings = tree.combinations.map(&:last)

        voicings.each do |v|
          new_sequences << seq + [v.pitches]
        end
      end

      sequences = new_sequences
      puts "  Paso #{step_i + 1} #{step[:label]}: " \
           "#{chord.pitches} (#{chord.pitches.size} notas) → #{sequences.size} secuencias supervivientes"
    end

    puts "\n  #{sequences.size} progresiones completas con conducción válida"

    if sequences.any?
      to_play = sequences.first(3)
      step_labels = progression_steps.map { |s| s[:label] }

      to_play.each_with_index do |selected, vi|
        puts "\n  Progresión #{vi + 1} de #{sequences.size}:"
        selected.each_with_index do |pitches, i|
          puts "    #{step_labels[i]}: B:#{pitches[0]} T:#{pitches[1]} A:#{pitches[2]} S:#{pitches[3]}"
        end
      end

      # ========================================================================
      # Reproducción de las 3 primeras progresiones
      # ========================================================================

      puts "\n=== INICIANDO REPRODUCCIÓN (#{to_play.size} progresiones) ===\n"

      at 1 do
        remaining = to_play.dup

        on :play_next do
          if remaining.any?
            selected = remaining.shift
            voicing_num = to_play.size - remaining.size

            puts "\n--- Progresión #{voicing_num} de #{to_play.size} ---"

            steps = selected.each_with_index.map do |pitches, i|
              {
                duration: 1/2r,
                label: step_labels[i],
                bajo:    { pitch: pitches[0], velocity: 70, duration: 1/2r },
                tenor:   { pitch: pitches[1], velocity: 65, duration: 3/8r },
                alto:    { pitch: pitches[2], velocity: 65, duration: 3/8r },
                soprano: { pitch: pitches[3], velocity: 70, duration: 3/8r }
              }.extend(Musa::Datasets::AbsD)
            end

            serie = S(*steps)

            control = play serie do |step|
              puts "  #{step[:label]}: B:#{step[:bajo][:pitch]} T:#{step[:tenor][:pitch]} " \
                   "A:#{step[:alto][:pitch]} S:#{step[:soprano][:pitch]}"
              bajo.note(**step[:bajo])
              tenor.note(**step[:tenor])
              alto.note(**step[:alto])
              soprano.note(**step[:soprano])
            end

            control.after do
              wait(1/2r) { launch :play_next }
            end
          else
            puts "\n=== Demo de Voice Leading terminada! ==="
            transport.stop
          end
        end

        launch :play_next
      end
    else
      puts "\n  ⚠ No se encontraron progresiones válidas"
      at 1 do
        puts "Sin material para reproducir"
        transport.stop
      end
    end
  end
end
