# Demo 10: Grammar - Composición
#
# Genera patrones musicales usando gramáticas formales
#
# GRAMÁTICAS GENERATIVAS (GenerativeGrammar)
# ==========================================
#
# Sistema basado en gramáticas formales (como las de Chomsky) para
# generar todas las combinaciones posibles de símbolos terminales.
#
# Conceptos clave:
#   N(contenido, **atributos)  → Nodo terminal (hoja del árbol)
#   PN()                       → Nodo proxy para gramáticas recursivas
#
# Operadores de combinación:
#   a | b     → Alternación (a O b)
#   a + b     → Secuencia (a SEGUIDO DE b)
#
# Modificadores:
#   .repeat(n)           → Repetir exactamente n veces
#   .repeat(min:, max:)  → Repetir entre min y max veces
#   .repeat              → Repetir indefinidamente (usar con .limit)
#   .limit { |o| ... }   → Filtrar opciones por condición
#
# Generación:
#   grammar.options              → Array de arrays de contenido
#   grammar.options(raw: true)   → Array de OptionElement (con atributos)
#   grammar.options(content: :join) → Concatenar contenido como string
#
# Aplicaciones musicales:
#   - Generar variaciones melódicas sistemáticas
#   - Crear patrones rítmicos con restricciones
#   - Producir progresiones armónicas válidas
#   - Explorar el espacio combinatorio de un motivo
#
# ESTRUCTURA:
# - Fase 1: Generación de material (fuera de temporización)
# - Fase 2: Reproducción con Series y eventos

module TheScore
  include Musa::GenerativeGrammar

  def score
    melody_voice = v(0)
    chord_voice = v(1)

    # ========================================================================
    # FASE 1: GENERACIÓN DE MATERIAL (antes de la temporización)
    # ========================================================================

    puts "\n=== GENERANDO MATERIAL CON GRAMÁTICAS ==="

    # ------------------------------------------------------------------------
    # Material 1: Operadores básicos - Alternación, Secuencia, Repetición
    # ------------------------------------------------------------------------

    puts "\n[Generando] Sección 1: Alternación, secuencia, repetición..."

    motif_up = N(0, dur: 1/8r) + N(2, dur: 1/8r)      # Do-Mi (ascendente)
    motif_down = N(4, dur: 1/8r) + N(2, dur: 1/8r)    # Sol-Mi (descendente)
    motif_leap = N(0, dur: 1/8r) + N(4, dur: 1/8r)    # Do-Sol (salto)

    grammar_1 = (motif_up | motif_down | motif_leap).repeat(3)
    all_options_1 = grammar_1.options(raw: true)
    puts "  Combinaciones posibles: #{all_options_1.size}"

    selected_1 = all_options_1.sample(4)
    section_1_series = selected_1.map do |option|
      gdvs = option.map do |e|
        { grade: e.content, duration: e.attributes[:dur], velocity: 0 }.extend(Musa::Datasets::GDV)
      end
      S(*gdvs)
    end

    puts "  Seleccionadas: #{selected_1.map { |o| o.map(&:content) }}"

    # ------------------------------------------------------------------------
    # Material 2: Restricciones con .limit - Patrones rítmicos
    # ------------------------------------------------------------------------

    puts "\n[Generando] Sección 2: Restricciones con .limit..."

    quarter = N(:q, size: 1/8r)
    eighth = N(:e, size: 1/16r)
    half = N(:h, size: 1/4r)

    grammar_2 = (quarter | eighth | half).repeat(max: 8).limit { |o|
      o.collect { |e| e.attributes[:size] }.sum == 1/2r
    }

    all_options_2 = grammar_2.options(raw: true)
    puts "  Patrones rítmicos que suman 1/2 compás: #{all_options_2.size}"

    selected_2 = all_options_2.sample(4)
    melody_pool = [0, 2, 4, 5, 4, 2, 0, 2, 4, 2, 0, 4]

    section_2_series = selected_2.each_with_index.map do |option, pattern_idx|
      option.each_with_index.map do |e, i|
        base_idx = selected_2[0...pattern_idx].sum { |o| o.size }
        grade = melody_pool[(base_idx + i) % melody_pool.size]
        { grade: grade, duration: e.attributes[:size], velocity: -2 }.extend(Musa::Datasets::GDV)
      end
    end

    puts "  Seleccionados: #{selected_2.map { |o| o.map { |e| e.attributes[:size].to_f } }}"

    # ------------------------------------------------------------------------
    # Material 3: Contenido dinámico con bloques
    # ------------------------------------------------------------------------

    puts "\n[Generando] Sección 3: Contenido dinámico..."

    low_note = N(range: :low, dur: 1/8r) { rand(0..2) }
    mid_note = N(range: :mid, dur: 1/8r) { rand(3..4) }
    high_note = N(range: :high, dur: 1/8r) { rand(5..7) }

    grammar_3 = low_note + mid_note + high_note + mid_note + low_note

    # Pre-generar 3 melodías (cada llamada a .options genera valores aleatorios nuevos)
    section_3_melodies = 3.times.map do
      melody_option = grammar_3.options(raw: true).first
      gdvs = melody_option.map do |e|
        { grade: e.content, duration: e.attributes[:dur], velocity: 1 }.extend(Musa::Datasets::GDV)
      end
      { grades: melody_option.map(&:content), serie: S(*gdvs) }
    end

    puts "  Contorno: bajo -> medio -> alto -> medio -> bajo"
    puts "  Melodías generadas: #{section_3_melodies.map { |m| m[:grades] }}"

    # ------------------------------------------------------------------------
    # Material 4: Gramática recursiva con PN() - Modulaciones armónicas
    # ------------------------------------------------------------------------

    puts "\n[Generando] Sección 4: Gramática recursiva (PN)..."

    phrase = PN()

    tonic = N(:tonic)
    subdominant = N(:subdominant)
    dominant = N(:dominant, character: :seventh)

    subdominant_phrase = N(:modulate) + subdominant + phrase + N(:demodulate)
    dominant_phrase = N(:modulate) + dominant + phrase + N(:demodulate)

    t = tonic
    s = subdominant | subdominant_phrase
    d = dominant | dominant_phrase

    phrase.node = t + s + d + t

    opciones_4 = phrase.options(raw: true) { |o| o.count { |el| el.content == :modulate } <= 3 }

    puts "  Opciones con profundidad <= 3: #{opciones_4.size}"
    opciones_4.each_with_index do |opt, i|
      depth = opt.count { |el| el.content == :modulate }
      puts "    #{i + 1}. (prof #{depth}) #{opt.map(&:content).inspect}"
    end

    # Pre-procesar: transformar elementos a acordes, procesando modulaciones
    section_4_series = opciones_4.map do |option_elements|
      scale_stack = [scale]

      chords = option_elements.filter_map do |element|
        content = element.content
        attrs = element.attributes

        case content
        when :modulate
          scale_stack.push(scale_stack.last.dominant.major)
          nil
        when :demodulate
          scale_stack.pop if scale_stack.size > 1
          nil
        else
          current_scale = scale_stack.last
          chord = attrs[:character] ?
                  current_scale.send(content).chord(attrs[:character]) :
                  current_scale.send(content).chord

          { pitches: chord.pitches,
            bass: chord.root.pitch - 12,
            function: content,
            character: attrs[:character],
            scale_pitch: current_scale.tonic.pitch,
            duration: 1/2r }
        end
      end

      S(*chords)
    end

    puts "\n=== MATERIAL GENERADO, INICIANDO REPRODUCCIÓN ===\n"

    # ========================================================================
    # FASE 2: REPRODUCCIÓN (usando Series con play y eventos)
    # ========================================================================

    # ------------------------------------------------------------------------
    # Sección 1: Operadores básicos
    # ------------------------------------------------------------------------

    on :section_1 do
      puts "\n[Sección 1] Operadores: alternación (|), secuencia (+), repetición"
      launch :play_section_1, 0
    end

    on :play_section_1 do |index|
      if index < section_1_series.size
        puts "  Secuencia #{index + 1}: #{selected_1[index].map(&:content)}"

        control = play section_1_series[index] do |gdv|
          melody_voice.note(**gdv.to_pdv(scale).merge(velocity: 72))
        end

        control.after(1/4r) { launch :play_section_1, index + 1 }
      else
        launch :section_2
      end
    end

    # ------------------------------------------------------------------------
    # Sección 2: Restricciones con .limit
    # ------------------------------------------------------------------------

    on :section_2 do
      puts "\n[Sección 2] Restricciones con .limit - patrones rítmicos"
      launch :play_section_2, 0
    end

    on :play_section_2 do |index|
      if index < section_2_series.size
        durations = selected_2[index].map { |e| e.attributes[:size] }
        puts "  Ritmo #{index + 1}: #{durations.map(&:to_f)}"

        control = play S(*section_2_series[index]) do |gdv|
          melody_voice.note(**gdv.to_pdv(scale).merge(velocity: 70))
        end

        control.after(1/8r) { launch :play_section_2, index + 1 }
      else
        launch :section_3
      end
    end

    # ------------------------------------------------------------------------
    # Sección 3: Contenido dinámico
    # ------------------------------------------------------------------------

    on :section_3 do
      puts "\n[Sección 3] Contenido dinámico - bloques que generan valores"
      puts "  Contorno: bajo -> medio -> alto -> medio -> bajo"
      launch :play_section_3, 0
    end

    on :play_section_3 do |index|
      if index < section_3_melodies.size
        melody_data = section_3_melodies[index]
        puts "  Melodía #{index + 1}: #{melody_data[:grades]}"

        control = play melody_data[:serie] do |gdv|
          melody_voice.note(**gdv.to_pdv(scale).merge(velocity: 75))
        end

        control.after(1/4r) { launch :play_section_3, index + 1 }
      else
        launch :section_4
      end
    end

    # ------------------------------------------------------------------------
    # Sección 4: Gramática recursiva con PN()
    # ------------------------------------------------------------------------

    on :section_4 do
      puts "\n[Sección 4] Gramática recursiva (PN) - progresiones con modulación"
      launch :play_section_4, 0
    end

    on :play_section_4 do |index|
      if index < [section_4_series.size, 3].min
        puts "\n  Progresión #{index + 1}:"

        control = play section_4_series[index] do |chord_data|
          chord_name = chord_data[:character] ? "#{chord_data[:function].upcase}7" : chord_data[:function].upcase.to_s
          puts "    #{chord_name} en #{chord_data[:scale_pitch]}: #{chord_data[:pitches]}"

          melody_voice.note(chord_data[:bass], velocity: 70, duration: chord_data[:duration])
          chord_voice.note(chord_data[:pitches], velocity: 65, duration: 3/8r)
        end

        control.after(1/2r) { launch :play_section_4, index + 1 }
      else
        launch :finish
      end
    end

    # ------------------------------------------------------------------------
    # Final
    # ------------------------------------------------------------------------

    on :finish do
      puts "\n=== Demo de GenerativeGrammar terminada! ==="
      transport.stop
    end

    # ========================================================================
    # Inicio
    # ========================================================================

    at 1 do
      launch :section_1
    end
  end
end
