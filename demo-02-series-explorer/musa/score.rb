# Demo 02: Series Explorer - Composición
#
# Demuestra 4 tipos de constructores de series simultáneamente
# NOTA: play() requiere series de hashes creadas con H()
# Usa v(n) para acceder a las voces MIDI (definido en main.rb)

module TheScore
  def score
    # ========================================================================
    # Voz 1: S() - Serie de valores literales
    # ========================================================================
    # S() crea una serie con valores explícitos
    # Perfecto para melodías definidas

    melody_grades = S(0, 2, 4, 5, 7, 5, 4, 2).repeat(4)  # 32 notas
    melody_dur = S(1/2r).repeat   # Infinito - H() termina con grades
    melody_vel = S(80).repeat     # Infinito

    # H() combina las series en una serie de hashes
    melody_s = H(grade: melody_grades, duration: melody_dur, velocity: melody_vel)

    at 1 do
      puts "\n[Voz 1] S() - Melodía literal: Do Re Mi Fa Sol Fa Mi Re"

      play melody_s do |note|
        pitch = scale[note[:grade]].pitch
        v(0).note(pitch: pitch, velocity: note[:velocity], duration: note[:duration])
      end
    end

    # ========================================================================
    # Voz 2: FOR() - Secuencia numérica
    # ========================================================================
    # FOR() genera secuencias con from, to, step
    # Perfecto para escalas ascendentes/descendentes

    scale_up = FOR(from: 0, to: 7)        # 0, 1, 2, 3, 4, 5, 6, 7
    scale_down = FOR(from: 7, to: 0)      # 7, 6, 5, 4, 3, 2, 1, 0
    scale_grades = MERGE(scale_up, scale_down).repeat(2)  # 32 notas
    scale_dur = S(1/4r).repeat   # Infinito
    scale_vel = S(70).repeat     # Infinito

    scale_pattern = H(grade: scale_grades, duration: scale_dur, velocity: scale_vel)

    at 3 do
      puts "\n[Voz 2] FOR() - Escala arriba y abajo"

      play scale_pattern do |note|
        pitch = scale[note[:grade]].pitch
        v(1).note(pitch: pitch, velocity: note[:velocity], duration: note[:duration])
      end
    end

    # ========================================================================
    # Voz 3: RND() - Valores aleatorios
    # ========================================================================
    # RND() selecciona aleatoriamente de los valores dados
    # Perfecto para melodías generativas impredecibles

    random_grades = RND(0, 2, 4, 5, 7).repeat.max_size(32)
    random_dur = S(1/8r).repeat   # Infinito - H() termina con max_size de grades
    random_vel = S(60).repeat     # Infinito

    random_melody = H(grade: random_grades, duration: random_dur, velocity: random_vel)

    at 5 do
      puts "\n[Voz 3] RND() - Melodía aleatoria pentatónica"

      play random_melody do |note|
        pitch = scale[note[:grade]].pitch
        v(2).note(pitch: pitch, velocity: note[:velocity], duration: note[:duration])
      end
    end

    # ========================================================================
    # Voz 4: FIBO() con H() - Fibonacci + Hash de series
    # ========================================================================
    # FIBO() genera secuencia Fibonacci
    # H() combina múltiples series en un hash

    # Usamos Fibonacci para duraciones (módulo para mantener en rango)
    fibo_durations = FIBO().map { |n| ((n % 4) + 1) / 8r }.max_size(16)  # 16 notas
    fixed_pitches = S(0, 4, 7, 4).repeat  # Infinito
    fibo_vel = S(75).repeat               # Infinito

    # H() combina series: cada next_value devuelve un hash
    combined = H(grade: fixed_pitches, duration: fibo_durations, velocity: fibo_vel)

    at 10 do
      puts "\n[Voz 4] H() + FIBO() - Arpegio con ritmos Fibonacci"

      play combined do |note|
        pitch = scale[note[:grade]].pitch
        v(3).note(pitch: pitch, velocity: note[:velocity], duration: note[:duration])
      end
    end

    # ========================================================================
    # Demostración de operaciones: map, select, reverse
    # ========================================================================

    at 15 do
      puts "\n[Todas] Operaciones de series: map, reverse"

      # Transponer una octava arriba con map
      transposed_grades = S(0, 2, 4, 5, 7).map { |g| g + 7 }  # 5 notas
      transposed_dur = S(1/2r).repeat  # Infinito
      transposed_vel = S(90).repeat    # Infinito

      transposed = H(grade: transposed_grades, duration: transposed_dur, velocity: transposed_vel)

      control = play transposed do |note|
        # Tocar en todas las voces como acorde
        pitch = scale[note[:grade]].pitch
        4.times do |i|
          v(i).note(pitch: pitch + (i * 12), velocity: note[:velocity], duration: note[:duration])
        end
      end

      # Esta sección termina en 17.5, Voz 1 termina en 17
      # Esperar un poco y terminar
      control.after(1/2r) do
        puts "\n¡Demo terminada!"
        transport.stop
      end
    end
  end
end
