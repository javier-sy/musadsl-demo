# Demo 08: Voice Leading - Composición
#
# Genera voicings SATB para una progresión con modulación usando
# dos niveles de Rules.
#
# ARQUITECTURA DE DOS NIVELES:
#
# Nivel 1 (local): genera voicings para UN acorde
#   - grow 'inversión': posición del acorde (fundamental, 1ª, 2ª)
#   - grow 'duplicación': qué nota se dobla para 4 voces SATB
#   - cut: rango SATB, separación entre voces
#
# Nivel 2 (progresión): genera secuencias completas de voicings
#   - Un grow por paso (cada uno semánticamente distinto)
#   - cut: movimiento máximo, quintas/octavas paralelas, movimiento contrario
#   - Objeto acumulativo: array que crece con cada paso
#
# PROGRESIÓN: C: I - IV - V → G: I - IV - V → C: IV - V - I
# El V de C es el I de G (acorde pivote para la modulación)

module TheScore
  def score
    soprano = v(0)
    alto = v(1)
    tenor = v(2)
    bajo = v(3)

    # ========================================================================
    # Nivel 1: Reglas locales de voicing (inversión × duplicación)
    # ========================================================================

    voicing_rules = Rules.new do
      grow 'inversión' do |chord|
        branch chord                                # Posición fundamental
        branch chord.with_move(root: 1)             # 1ª inversión (3ª en bajo)
        branch chord.with_move(root: 1, third: 1)   # 2ª inversión (5ª en bajo)
      end

      grow 'duplicación' do |chord|
        branch chord.with_duplicate(root: 1)        # Doblar fundamental arriba
        branch chord.with_duplicate(root: -1)       # Doblar fundamental abajo
        branch chord.with_duplicate(fifth: 1)       # Doblar quinta arriba
      end

      cut 'rango SATB' do |chord|
        pitches = chord.pitches
        if pitches.size >= 4
          prune if pitches[0] < 40 || pitches[0] > 60  # Bajo:    E2–C4
          prune if pitches[1] < 48 || pitches[1] > 67  # Tenor:   C3–G4
          prune if pitches[2] < 55 || pitches[2] > 74  # Alto:    G3–D5
          prune if pitches[3] < 60 || pitches[3] > 81  # Soprano: C4–A5
        end
      end

      cut 'separación voces' do |chord|
        pitches = chord.pitches
        if pitches.size >= 4
          (0...pitches.size - 1).each do |i|
            prune if pitches[i + 1] - pitches[i] > 12
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
      # C mayor: establecer tonalidad
      { scale: c_major, func: :tonic,       label: "C: I" },
      { scale: c_major, func: :subdominant, label: "C: IV" },
      { scale: c_major, func: :dominant,    label: "C: V" },
      # Modulación a G mayor (V de C = I de G, acorde pivote)
      { scale: g_major, func: :subdominant, label: "G: IV" },
      { scale: g_major, func: :dominant,    label: "G: V" },
      # Vuelta a C mayor
      { scale: c_major, func: :subdominant, label: "C: IV" },
      { scale: c_major, func: :dominant,    label: "C: V" },
      { scale: c_major, func: :tonic,       label: "C: I" },
    ]

    # ========================================================================
    # Pre-generar voicings candidatos por paso (Nivel 1)
    # ========================================================================

    puts "\n=== NIVEL 1: VOICINGS LOCALES ==="

    step_voicings = progression_steps.map do |step|
      chord = step[:scale].send(step[:func]).chord
      tree = voicing_rules.apply([chord])
      voicings = tree.combinations.map(&:last)

      puts "\n  #{step[:label]} (#{step[:func]}): tríada #{chord.pitches}"
      puts "    #{voicings.size} voicings pasan filtros locales (de 9 candidatos)"
      voicings.each_with_index do |v, vi|
        p = v.pitches
        puts "    [#{vi + 1}] B:#{p[0]} T:#{p[1]} A:#{p[2]} S:#{p[3]}"
      end

      voicings
    end

    step_labels = progression_steps.map { |s| s[:label] }

    # ========================================================================
    # Nivel 2: Reglas de conducción entre acordes (objeto acumulativo)
    # ========================================================================

    puts "\n=== NIVEL 2: CONDUCCIÓN DE VOCES ==="

    progression_rules = Rules.new do
      # Un grow por paso — cada uno semánticamente distinto
      step_labels.each_with_index do |label, i|
        voicings = step_voicings[i]

        grow "voicing #{label}" do |sequence|
          voicings.each do |chord|
            branch sequence + [chord.pitches]
          end
        end
      end

      # Cuts sobre el objeto acumulativo

      cut 'movimiento máximo' do |sequence|
        if sequence.size >= 2
          curr = sequence[-1]
          prev = sequence[-2]
          total = curr.zip(prev).sum { |c, p| (c - p).abs }
          prune if total > 24
        end
      end

      cut 'quintas paralelas' do |sequence|
        if sequence.size >= 2
          curr = sequence[-1]
          prev = sequence[-2]
          (0..3).to_a.combination(2).each do |i, j|
            curr_int = (curr[j] - curr[i]) % 12
            prev_int = (prev[j] - prev[i]) % 12
            if curr_int == 7 && prev_int == 7
              dir_i = curr[i] <=> prev[i]
              dir_j = curr[j] <=> prev[j]
              prune if dir_i == dir_j && dir_i != 0
            end
          end
        end
      end

      # Si una voz bajó, debe subir o mantenerse; si subió, debe bajar o mantenerse
      cut 'movimiento contrario' do |sequence|
        if sequence.size >= 3
          curr = sequence[-1]
          prev = sequence[-2]
          prev2 = sequence[-3]
          (0..3).each do |i|
            prev_dir = prev[i] <=> prev2[i]
            curr_dir = curr[i] <=> prev[i]
            prune if prev_dir == -1 && curr_dir == -1  # bajó dos veces
            prune if prev_dir == 1 && curr_dir == 1    # subió dos veces
          end
        end
      end

      cut 'octavas paralelas' do |sequence|
        if sequence.size >= 2
          curr = sequence[-1]
          prev = sequence[-2]
          (0..3).to_a.combination(2).each do |i, j|
            curr_int = (curr[j] - curr[i]) % 12
            prev_int = (prev[j] - prev[i]) % 12
            if curr_int == 0 && prev_int == 0
              dir_i = curr[i] <=> prev[i]
              dir_j = curr[j] <=> prev[j]
              prune if dir_i == dir_j && dir_i != 0
            end
          end
        end
      end
    end

    tree = progression_rules.apply([[]])
    progressions = tree.combinations.map(&:last)

    puts "\n  #{progressions.size} progresiones completas con conducción válida"

    if progressions.any?
      puts "\n  Progresión elegida (1 de #{progressions.size}):"
      selected = progressions.first
      selected.each_with_index do |pitches, i|
        puts "    #{step_labels[i]}: B:#{pitches[0]} T:#{pitches[1]} A:#{pitches[2]} S:#{pitches[3]}"
      end

      # ========================================================================
      # Reproducción
      # ========================================================================

      puts "\n=== INICIANDO REPRODUCCIÓN ===\n"

      steps = selected.each_with_index.map do |pitches, i|
        {
          duration: 1r,
          label: step_labels[i],
          bajo:    { pitch: pitches[0], velocity: 70, duration: 1r },
          tenor:   { pitch: pitches[1], velocity: 65, duration: 3/4r },
          alto:    { pitch: pitches[2], velocity: 65, duration: 3/4r },
          soprano: { pitch: pitches[3], velocity: 70, duration: 3/4r }
        }.extend(Musa::Datasets::AbsD)
      end

      at 1 do
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
          wait 1r do
            puts "\n=== Demo de Voice Leading terminada! ==="
            transport.stop
          end
        end
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
