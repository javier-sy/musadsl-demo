# Demo 05: Markov - Composición
#
# Tres estilos de melodías generadas por cadenas de Markov
# Usa sistema de eventos (on/launch) para encadenar secciones
#
# CADENAS DE MARKOV
# =================
# Un modelo probabilístico donde el siguiente estado depende
# SOLO del estado actual (sin memoria de estados anteriores).
#
# En música: cada nota determina probabilísticamente la siguiente.
# Las transiciones son un hash:
#   { nota_actual => { nota_siguiente => probabilidad, ... } }
#
# Ejemplo: { 0 => { 1 => 0.4, 2 => 0.3 } }
#   Desde grado 0: 40% de ir a grado 1, 30% de ir a grado 2
#
# finish: nil → sin estado final, la serie es infinita
# finish: X   → termina cuando alcanza estado X

module TheScore
  def score
    v_diatonic = v(0)  # Estilo diatónico (clásico)
    v_jazzy = v(1)     # Estilo cromático (jazz)
    v_minimal = v(2)   # Estilo repetitivo (minimalista)

    # ========================================================================
    # Estilo 1: Diatónico (Clásico)
    # ========================================================================
    # Movimiento por grados conjuntos, con tendencia a resolver

    markov_diatonic = Markov.new(
      start: 0,  # Comienza en tónica
      finish: nil,  # Sin estado final (continuo)
      transitions: {
        0 => { 1 => 0.4, 2 => 0.3, 4 => 0.2, -1 => 0.1 },  # Do tiende a subir
        1 => { 0 => 0.3, 2 => 0.5, 3 => 0.2 },              # Re tiende a Mi
        2 => { 1 => 0.3, 3 => 0.3, 4 => 0.3, 0 => 0.1 },    # Mi equilibrado
        3 => { 2 => 0.3, 4 => 0.5, 5 => 0.2 },              # Fa tiende a Sol
        4 => { 3 => 0.2, 5 => 0.3, 2 => 0.2, 0 => 0.3 },    # Sol resuelve a Do
        5 => { 4 => 0.4, 6 => 0.3, 3 => 0.3 },              # La baja
        6 => { 5 => 0.4, 7 => 0.3, 4 => 0.3 },              # Si sube o baja
        7 => { 0 => 0.5, 6 => 0.3, 5 => 0.2 },              # Do' resuelve
        -1 => { 0 => 0.7, 1 => 0.3 }                         # Si bajo resuelve
      }
    )

    # Duraciones diatónicas: fluidas, tendencia a corcheas y negras
    markov_dur_diatonic = Markov.new(
      start: 1/4r,
      transitions: {
        1/8r => { 1/8r => 0.3, 1/4r => 0.5, 1/2r => 0.2 },
        1/4r => { 1/8r => 0.3, 1/4r => 0.4, 1/2r => 0.3 },
        1/2r => { 1/8r => 0.4, 1/4r => 0.5, 1/2r => 0.1 }
      }
    )

    on :diatonic do
      puts "\n[Estilo Diatónico] Movimiento por grados conjuntos"

      grades = markov_diatonic.max_size(24)
      durations = markov_dur_diatonic.max_size(24)
      velocities = S(75).repeat(24)

      melody = H(grade: grades, duration: durations, velocity: velocities)

      control = play melody do |note|
        pitch = scale[note[:grade]].pitch
        v_diatonic.note(pitch: pitch, velocity: note[:velocity], duration: note[:duration])
      end

      control.after(1/2r) { launch :jazzy }
    end

    # ========================================================================
    # Estilo 2: Cromático (Jazz)
    # ========================================================================
    # Saltos más grandes, notas de paso cromáticas

    markov_jazzy = Markov.new(
      start: 0,
      transitions: {
        0 => { 2 => 0.25, 4 => 0.25, 6 => 0.25, -3 => 0.25 },  # Arpegios
        2 => { 4 => 0.3, 0 => 0.2, 5 => 0.3, -1 => 0.2 },
        4 => { 7 => 0.3, 2 => 0.2, 0 => 0.3, 6 => 0.2 },
        5 => { 4 => 0.3, 7 => 0.3, 2 => 0.2, 0 => 0.2 },
        6 => { 7 => 0.4, 4 => 0.3, 2 => 0.3 },
        7 => { 4 => 0.3, 0 => 0.4, 5 => 0.3 },
        -1 => { 0 => 0.5, 2 => 0.3, 4 => 0.2 },
        -3 => { 0 => 0.5, -1 => 0.3, 2 => 0.2 }
      }
    )

    # Duraciones jazz: swing, semicorcheas y fusas con síncopas
    markov_dur_jazzy = Markov.new(
      start: 3/16r,
      transitions: {
        1/16r => { 3/16r => 0.6, 1/8r => 0.3, 1/16r => 0.1 },  # Corta → larga
        1/8r  => { 1/16r => 0.4, 3/16r => 0.4, 1/8r => 0.2 },
        3/16r => { 1/16r => 0.7, 1/8r => 0.2, 3/16r => 0.1 }   # Larga → corta (swing)
      }
    )

    on :jazzy do
      puts "\n[Estilo Jazz] Saltos y arpegios"

      grades = markov_jazzy.max_size(24)
      durations = markov_dur_jazzy.max_size(24)
      velocities = S(85).repeat(24)

      melody = H(grade: grades, duration: durations, velocity: velocities)

      control = play melody do |note|
        pitch = scale[note[:grade]].pitch
        v_jazzy.note(pitch: pitch, velocity: note[:velocity], duration: note[:duration])
      end

      control.after(1/2r) { launch :minimal }
    end

    # ========================================================================
    # Estilo 3: Minimalista
    # ========================================================================
    # Alta probabilidad de repetir la misma nota

    markov_minimal = Markov.new(
      start: 0,
      transitions: {
        0 => { 0 => 0.6, 2 => 0.2, 4 => 0.2 },   # 60% repetición
        2 => { 2 => 0.6, 0 => 0.2, 4 => 0.2 },
        4 => { 4 => 0.6, 0 => 0.2, 2 => 0.2 }
      }
    )

    # Duraciones minimalistas: alta repetición, cambios sutiles
    markov_dur_minimal = Markov.new(
      start: 1/8r,
      transitions: {
        1/16r => { 1/16r => 0.5, 1/8r => 0.4, 1/4r => 0.1 },
        1/8r  => { 1/8r => 0.7, 1/16r => 0.2, 1/4r => 0.1 },  # 70% repetición
        1/4r  => { 1/8r => 0.5, 1/16r => 0.3, 1/4r => 0.2 }
      }
    )

    on :minimal do
      puts "\n[Estilo Minimalista] Repeticiones con variación gradual"

      grades = markov_minimal.max_size(32)
      durations = markov_dur_minimal.max_size(32)
      velocities = S(65).repeat(32)

      melody = H(grade: grades, duration: durations, velocity: velocities)

      control = play melody do |note|
        pitch = scale[note[:grade]].pitch
        v_minimal.note(pitch: pitch, velocity: note[:velocity], duration: note[:duration])
      end

      control.after(1/2r) do
        puts "\n¡Demo de Markov terminada!"
        transport.stop
      end
    end

    # Inicio de la cadena
    at 1 do
      launch :diatonic
    end
  end
end
