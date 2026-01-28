# Demo 06: Variatio - Composición
#
# Genera y reproduce variaciones combinatorias de un motivo
# Usa sistema de eventos para encadenar variaciones

module TheScore
  # Convierte una variación a serie H() para reproducir con play
  def variation_to_series(base_motif, variation, speed_factor)
    transposed = base_motif.map { |g| g + variation[:transpose] }

    # Aplicar dirección
    transposed = transposed.reverse if variation[:direction] == :reverse

    # Ajustar ritmo si tiene menos notas que el motivo
    rhythm = variation[:rhythm]
    if rhythm.size < transposed.size
      rhythm = rhythm + [rhythm.last] * (transposed.size - rhythm.size)
    elsif rhythm.size > transposed.size
      rhythm = rhythm.first(transposed.size)
    end

    # También invertir el ritmo si la dirección es reverse
    rhythm = rhythm.reverse if variation[:direction] == :reverse

    # Aplicar factor de velocidad
    rhythm = rhythm.map { |d| d * speed_factor }

    grades = S(*transposed)
    durations = S(*rhythm)
    velocities = S(80).repeat(transposed.size)

    H(grade: grades, duration: durations, velocity: velocities)
  end

  def score
    voice = v(0)

    # ========================================================================
    # Definición del Variatio
    # ========================================================================
    #
    # SERIES: S() vs H()
    # ==================
    # S(*valores)  → Serie de valores individuales (notas, números)
    # H(key: serie, ...) → Serie de HASHES combinando series por clave
    #
    # H() es esencial para play() porque necesita hashes con
    # claves específicas (:grade, :duration, :velocity para GDV)
    #
    # Variatio genera el producto cartesiano de todas las opciones

    motif_variatio = Variatio.new :motif do
      # Transposiciones: tónica, tercera, quinta, octava
      field :transpose, [0, 2, 4, 7]

      # Patrones rítmicos
      field :rhythm, [
        [1/4r, 1/4r, 1/4r, 1/4r],           # Negras uniformes
        [1/2r, 1/4r, 1/4r],                  # Larga-corta-corta
        [1/8r, 1/8r, 1/4r, 1/2r],           # Aceleración
        [1/4r, 1/8r, 1/8r, 1/2r]            # Síncopa
      ]

      # Dirección: normal o invertido
      field :direction, [:normal, :reverse]

      # Constructor: crea el objeto de variación
      constructor do |transpose:, rhythm:, direction:|
        {
          transpose: transpose,
          rhythm: rhythm,
          direction: direction
        }
      end
    end

    # ========================================================================
    # Generar todas las variaciones
    # ========================================================================

    all_variations = motif_variatio.run
    puts "Variatio generó #{all_variations.size} variaciones (reproduciendo todas)"
    # 4 transposiciones × 4 ritmos × 2 direcciones = 32 variaciones

    # Factor de velocidad: 1/2 = el doble de rápido
    speed_factor = 1/2r

    # Motivo base: 4 notas (Do Re Mi Re)
    base_motif = [0, 2, 4, 2]

    # ========================================================================
    # Sistema de eventos para reproducir variaciones
    # ========================================================================

    on :play_variation do |index|
      if index < all_variations.size
        variation = all_variations[index]
        puts "\n[Variación #{index + 1}/#{all_variations.size}] " \
             "transpose: #{variation[:transpose]}, " \
             "rhythm: #{variation[:rhythm].map { |r| r.to_f.round(3) }}, " \
             "direction: #{variation[:direction]}"

        melody = variation_to_series(base_motif, variation, speed_factor)

        control = play melody do |note|
          pitch = scale[note[:grade]].pitch
          voice.note(pitch, velocity: note[:velocity], duration: note[:duration] * 0.9)
        end

        control.after { launch :play_variation, index + 1 }
      else
        puts "\n¡Demo de Variatio terminada!"
        transport.stop
      end
    end

    # ========================================================================
    # Inicio
    # ========================================================================

    at 1 do
      launch :play_variation, 0
    end
  end
end
