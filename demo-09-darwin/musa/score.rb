# Demo 09: Darwin - Composición
#
# Genera poblaciones de motivos y selecciona los mejores
# usando criterios de fitness evolutivos
#
# DARWIN: SELECCIÓN EVOLUTIVA
# ===========================
#
# Darwin evalúa candidatos según múltiples dimensiones:
#
# dimension :nombre, valor
#   - Valor POSITIVO → maximizar (más es mejor)
#   - Valor NEGATIVO → minimizar (menos es mejor)
#
# feature :nombre, condición
#   - Booleano que indica presencia de característica
#
# die
#   - Descarta el candidato inmediatamente (no pasa filtro)
#
# weight nombre: X
#   - Importancia relativa (2.0 = doble peso que 1.0)
#
# .select(n) → retorna los n mejores candidatos
#
# Velocidades simbólicas (GDV):
#   -3=ppp, -2=pp, -1=p, 0=mp, 1=mf, 2=f, 3=ff, 4=fff
#
# ESTRUCTURA:
# - Fase 1: Generación de material (fuera de temporización)
# - Fase 2: Reproducción con Series y PDV

module TheScore
  def score
    melody_voice = v(0)
    chord_voice = v(1)

    # ========================================================================
    # FASE 1: GENERACIÓN DE MATERIAL (antes de la temporización)
    # ========================================================================

    puts "\n=== GENERANDO MATERIAL CON DARWIN ==="

    # ------------------------------------------------------------------------
    # Material 1: Selección de melodías por contorno
    # ------------------------------------------------------------------------

    puts "\n[Generando] Melodías con contorno suave..."

    melody_population = 50.times.map do
      {
        notes: 8.times.map { rand(0..7) },
        id: rand(1000)
      }
    end

    melody_darwin = Darwin.new do
      measures do |melody|
        notes = melody[:notes]

        total_jumps = notes.each_cons(2).sum { |a, b| (a - b).abs }
        direction_changes = notes.each_cons(3).count do |a, b, c|
          (b - a) * (c - b) < 0
        end

        dimension :smoothness, -total_jumps.to_f
        dimension :direction_changes, -direction_changes.to_f

        feature :starts_on_tonic if notes.first == 0
        feature :ends_on_tonic if notes.last == 0
        feature :has_climax if notes.include?(7)

        die if notes.each_cons(2).any? { |a, b| (a - b).abs > 4 }
      end

      weight smoothness: 3.0,
             direction_changes: 1.0,
             starts_on_tonic: 2.0,
             ends_on_tonic: 2.5,
             has_climax: 1.5
    end

    selected_melodies = melody_darwin.select(melody_population)
    puts "  Población: #{melody_population.size} -> Supervivientes: #{selected_melodies.size}"

    # Convertir las 3 mejores melodías a GDV
    melody_gdvs = selected_melodies.first(3).map do |melody|
      melody[:notes].map do |grade|
        { grade: grade, duration: 1/4r, velocity: 1 }.extend(Musa::Datasets::GDV)  # mf
      end
    end

    puts "  Mejores melodías: #{selected_melodies.first(3).map { |m| m[:notes] }}"

    # ------------------------------------------------------------------------
    # Material 2: Selección de ritmos
    # ------------------------------------------------------------------------

    puts "\n[Generando] Patrones rítmicos..."

    durations = [1/8r, 1/16r, 1/4r, 1/32r]
    rhythm_population = 40.times.map do
      pattern = []
      remaining = 1r

      while remaining > 0
        dur = durations.sample
        if dur <= remaining
          pattern << dur
          remaining -= dur
        end
      end

      { pattern: pattern, id: rand(1000) }
    end

    rhythm_darwin = Darwin.new do
      measures do |rhythm|
        pattern = rhythm[:pattern]

        quarters = pattern.count { |d| d == 1/8r }
        eighths = pattern.count { |d| d == 1/16r }
        sixteenths = pattern.count { |d| d == 1/32r }

        variety = [quarters, eighths, sixteenths].count { |c| c > 0 }

        dimension :variety, variety.to_f
        dimension :note_count, pattern.size.to_f

        feature :strong_start if pattern.first >= 1/8r

        die if sixteenths > 4
      end

      weight variety: 2.0,
             note_count: -0.5,
             strong_start: 1.5
    end

    selected_rhythms = rhythm_darwin.select(rhythm_population)
    puts "  Población: #{rhythm_population.size} -> Supervivientes: #{selected_rhythms.size}"

    # Convertir los 2 mejores ritmos a GDV con melodía fija
    fixed_melody = [0, 2, 4, 5, 4, 2, 0, 2]
    rhythm_gdvs = selected_rhythms.first(2).map do |rhythm|
      rhythm[:pattern].each_with_index.map do |dur, i|
        { grade: fixed_melody[i % fixed_melody.size], duration: dur, velocity: 0 }.extend(Musa::Datasets::GDV)  # mp
      end
    end

    puts "  Mejores ritmos: #{selected_rhythms.first(2).map { |r| r[:pattern].map(&:to_f) }}"

    # ------------------------------------------------------------------------
    # Material 3: Selección de progresiones armónicas
    # ------------------------------------------------------------------------

    puts "\n[Generando] Progresiones armónicas..."

    chord_symbols = [:I, :II, :IV, :V, :VI]

    chord_population = 30.times.map do
      {
        progression: [:I] + 3.times.map { chord_symbols.sample } + [:I],
        id: rand(1000)
      }
    end

    chord_darwin = Darwin.new do
      measures do |prog|
        chords = prog[:progression]

        dominants = chords.count { |c| c == :V }
        has_cadence = chords.each_cons(2).any? { |a, b| a == :V && b == :I }
        unique_chords = chords.uniq.size

        dimension :variety, unique_chords.to_f
        dimension :dominant_use, dominants.to_f

        feature :authentic_cadence if has_cadence
        feature :uses_II if chords.include?(:II)
        feature :uses_VI if chords.include?(:VI)

        die if chords.each_cons(2).any? { |a, b| a == b }
      end

      weight variety: 2.0,
             dominant_use: 1.0,
             authentic_cadence: 3.0,
             uses_II: 1.5,
             uses_VI: 1.0
    end

    selected_progressions = chord_darwin.select(chord_population)
    puts "  Población: #{chord_population.size} -> Supervivientes: #{selected_progressions.size}"

    # Convertir la mejor progresión a steps AbsD (bajo GDV + acorde)
    best_progression = selected_progressions.first
    progression_steps = best_progression[:progression].map do |chord_sym|
      chord = scale[chord_sym].chord
      {
        duration: 1,
        symbol: chord_sym,
        bass: { grade: chord.root.grade, octave: -1, duration: 1, velocity: 0 }.extend(Musa::Datasets::GDV),
        chord: chord,
        chord_duration: 7/8r,
        chord_velocity: -1  # p
      }.extend(Musa::Datasets::AbsD)
    end

    puts "  Mejor progresión: #{best_progression[:progression].join(' - ')}"

    # ------------------------------------------------------------------------
    # Material 4: Darwin + Variatio
    # ------------------------------------------------------------------------

    puts "\n[Generando] Variaciones con Darwin + Variatio..."

    motif_variatio = Variatio.new :motif do
      field :transpose, [0, 2, 4, 7]
      field :rhythm_type, [:uniform, :long_short, :syncopated]
      field :articulation, [:legato, :staccato]

      constructor do |transpose:, rhythm_type:, articulation:|
        rhythm = case rhythm_type
                 when :uniform then [1/8r, 1/8r, 1/8r, 1/8r]
                 when :long_short then [1/4r, 1/8r, 1/8r]
                 when :syncopated then [1/16r, 3/16r, 1/8r, 1/8r]
                 end

        {
          transpose: transpose,
          rhythm: rhythm,
          rhythm_type: rhythm_type,
          articulation: articulation,
          note_factor: articulation == :staccato ? 0.5 : 0.9
        }
      end
    end

    all_variations = motif_variatio.run
    puts "  Variatio generó #{all_variations.size} variaciones"

    variation_darwin = Darwin.new do
      measures do |var|
        dimension :transpose_balance, -(var[:transpose] - 4).abs.to_f

        feature :is_legato if var[:articulation] == :legato
        feature :is_syncopated if var[:rhythm_type] == :syncopated
        feature :moderate_transpose if var[:transpose] == 2 || var[:transpose] == 4
      end

      weight transpose_balance: 1.0,
             is_legato: 2.0,
             is_syncopated: 1.5,
             moderate_transpose: 1.0
    end

    selected_variations = variation_darwin.select(all_variations)
    puts "  Darwin seleccionó: #{selected_variations.size} variaciones viables"

    # Convertir las 2 mejores variaciones a GDV
    base_motif = [0, 2, 4, 2]
    variation_gdvs = selected_variations.first(2).map do |var|
      transposed = base_motif.map { |g| g + var[:transpose] }
      transposed.zip(var[:rhythm]).map do |grade, dur|
        { grade: grade, duration: dur, note_duration: dur * var[:note_factor], velocity: 1 }.extend(Musa::Datasets::GDV)  # mf
      end
    end

    puts "  Mejores variaciones: #{selected_variations.first(2).map { |v| "#{v[:rhythm_type]}/#{v[:articulation]}" }}"

    puts "\n=== MATERIAL GENERADO, INICIANDO REPRODUCCIÓN ===\n"

    # ========================================================================
    # FASE 2: REPRODUCCIÓN (usando Series con play y eventos)
    # ========================================================================

    # ------------------------------------------------------------------------
    # Sección 1: Melodías seleccionadas
    # ------------------------------------------------------------------------

    on :play_melodies do |index = 0|
      if index == 0
        puts "\n[Sección 1] Reproduciendo melodías seleccionadas"
      end

      if index < melody_gdvs.size
        puts "  Melodía ##{index + 1}"
        serie = S(*melody_gdvs[index])

        control = play serie do |gdv|
          melody_voice.note(**gdv.to_pdv(scale))
        end

        control.after(1/2r) { launch :play_melodies, index + 1 }
      else
        launch :play_rhythms, 0
      end
    end

    # ------------------------------------------------------------------------
    # Sección 2: Ritmos seleccionados
    # ------------------------------------------------------------------------

    on :play_rhythms do |index = 0|
      if index == 0
        puts "\n[Sección 2] Reproduciendo patrones rítmicos"
      end

      if index < rhythm_gdvs.size
        puts "  Ritmo ##{index + 1}"
        serie = S(*rhythm_gdvs[index])

        control = play serie do |gdv|
          melody_voice.note(**gdv.to_pdv(scale))
        end

        control.after(1/2r) { launch :play_rhythms, index + 1 }
      else
        launch :play_progression
      end
    end

    # ------------------------------------------------------------------------
    # Sección 3: Progresión armónica
    # ------------------------------------------------------------------------

    on :play_progression do
      puts "\n[Sección 3] Reproduciendo progresión armónica"
      puts "  #{best_progression[:progression].join(' - ')}"

      progression_serie = S(*progression_steps)

      control = play progression_serie do |step|
        puts "    #{step[:symbol]}"
        # Bajo: convertir GDV a PDV
        melody_voice.note(**step[:bass].to_pdv(scale))
        # Acorde: usar API de chords
        chord_voice.note(pitch: step[:chord].pitches, duration: step[:chord_duration], velocity: 49)
      end

      control.after do
        launch :play_variations, 0
      end
    end

    # ------------------------------------------------------------------------
    # Sección 4: Variaciones
    # ------------------------------------------------------------------------

    on :play_variations do |index = 0|
      if index == 0
        puts "\n[Sección 4] Reproduciendo variaciones Darwin + Variatio"
      end

      if index < variation_gdvs.size
        var = selected_variations[index]
        puts "  Variación ##{index + 1}: #{var[:rhythm_type]}/#{var[:articulation]}"
        serie = S(*variation_gdvs[index])

        control = play serie do |gdv|
          melody_voice.note(**gdv.to_pdv(scale))
        end

        control.after(1/2r) { launch :play_variations, index + 1 }
      else
        launch :finish
      end
    end

    # ------------------------------------------------------------------------
    # Final
    # ------------------------------------------------------------------------

    on :finish do
      puts "\n=== Demo de Darwin terminada! ==="
      transport.stop
    end

    # ------------------------------------------------------------------------
    # Inicio
    # ------------------------------------------------------------------------

    at 1 do
      launch :play_melodies, 0
    end
  end
end
