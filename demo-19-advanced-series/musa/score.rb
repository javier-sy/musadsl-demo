# Demo 19: Advanced Series Operations - Composición (4x)
#
# Demuestra:
# - H() para series hash
# - .eval() para transformaciones
# - .duplicate(), .reverse(), .shift()
# - Series anidadas con arrays de Ruby
# - FIBO().max_size()

module TheScore
  def score
    # ========================================================================
    # Sección 1: H() - Series Hash básico
    # ========================================================================

    at 1 do
      puts "\n[Sección 1] H() - Series Hash"

      # Series individuales
      pitches = S(0, 2, 4, 5, 7, 5, 4, 2)
      durations = S(1/16r, 1/16r, 1/32r, 1/32r, 1/8r, 1/16r, 1/16r, 1/8r)
      velocities = S(80, 75, 70, 65, 90, 70, 65, 60)

      # H() las combina: cada next_value devuelve un hash
      melody = H(
        grade: pitches,
        duration: durations,
        velocity: velocities
      ).instance

      puts "  H() combina pitch, duration, velocity en un hash"

      # Reproducir con spacing fijo (las duraciones varían independientemente)
      8.times do |i|
        at 1 + i * (1/16r) do
          note = melody.next_value
          if note
            pitch = scale[note[:grade]].pitch
            v1.note(
              pitch: pitch,
              duration: note[:duration],
              velocity: note[:velocity].to_i
            )
            puts "  #{note}"
          end
        end
      end
    end

    # ========================================================================
    # Sección 2: .eval() - Transformaciones
    # ========================================================================

    at 2 do
      puts "\n[Sección 2] .eval() - Transformaciones"

      # Serie base
      base = S(1, 2, 3, 5, 8, 13, 21, 34)

      # Transformar a pitch (agregar offset)
      pitches = base.eval { |n| 48 + (n % 12) }

      # Transformar a duración (convertir a Rational, 4x)
      durations = base.eval { |n| Rational(n, 64) }

      # Transformar a velocity (normalizar)
      velocities = base.eval { |n| 40 + (n / 34.0 * 60).to_i }

      puts "  base.eval { |n| transform(n) }"

      melody = H(
        pitch: pitches,
        duration: durations,
        velocity: velocities
      ).instance

      8.times do |i|
        at 2 + i * (1/16r) do
          note = melody.next_value
          if note
            v1.note(
              pitch: note[:pitch].to_i,
              duration: note[:duration],
              velocity: note[:velocity].to_i
            )
            puts "  Pitch: #{note[:pitch]}, Dur: #{note[:duration]}, Vel: #{note[:velocity]}"
          end
        end
      end
    end

    # ========================================================================
    # Sección 3: FIBO().max_size() - Fibonacci limitado
    # ========================================================================

    at 3 do
      puts "\n[Sección 3] FIBO().max_size() - Fibonacci"

      # Secuencia Fibonacci limitada a 8 elementos
      fib_values = FIBO().max_size(8).instance.to_a  # [1, 1, 2, 3, 5, 8, 13, 21]

      puts "  FIBO(): #{fib_values.join(', ')}"

      # Transformar a duraciones (4x) y pitches
      fib_dur = FIBO().max_size(8).eval { |n| Rational(n, 32) }.instance
      fib_pitch = FIBO().max_size(8).eval { |n| 48 + (n % 24) }.instance

      # Posiciones precomputadas desde los valores Fibonacci
      pos = 0r
      8.times do |i|
        at 3 + pos do
          pitch = fib_pitch.next_value
          dur = fib_dur.next_value

          if pitch && dur
            v1.note(pitch: pitch.to_i, duration: dur, velocity: 75)
            puts "  Fib nota #{i}: pitch=#{pitch}, dur=#{dur}"
          end
        end
        pos += Rational(fib_values[i], 32)
      end
    end

    # ========================================================================
    # Sección 4: .duplicate() y .reverse() - Ida y vuelta
    # ========================================================================

    at 5 do
      puts "\n[Sección 4] .duplicate() y .reverse()"

      # Serie original
      original = S(0, 2, 4, 5, 7)

      # Ida y vuelta: original + reverse
      ida_vuelta = original + original.reverse

      puts "  Original: #{original.instance.to_a.join(', ')}"
      puts "  + Reverse: #{original.reverse.instance.to_a.join(', ')}"
      puts "  = Ida-vuelta: #{ida_vuelta.instance.to_a.join(', ')}"

      melody = ida_vuelta.instance

      10.times do |i|
        at 5 + i * (1/16r) do
          grade = melody.next_value
          if grade
            pitch = scale[grade].pitch
            v1.note(pitch: pitch, duration: 1/16r, velocity: 80)
          end
        end
      end
    end

    # ========================================================================
    # Sección 5: .shift() - Rotación de elementos
    # ========================================================================

    at 6 do
      puts "\n[Sección 5] .shift() - Rotación"

      # Serie original
      original = S(0, 2, 4, 5, 7)

      puts "  Original: #{original.instance.to_a.join(', ')}"
      puts "  .shift(1):  #{original.shift(1).instance.to_a.join(', ')}"
      puts "  .shift(2):  #{original.shift(2).instance.to_a.join(', ')}"
      puts "  .shift(-1): #{original.shift(-1).instance.to_a.join(', ')}"

      # Canon con shift
      # Voz 1: original
      v1_melody = original.repeat(3).instance

      # Voz 2: shifted by 2, misma secuencia rotada
      v2_melody = original.shift(2).repeat(3).instance

      15.times do |i|
        at 6 + i * (1/16r) do
          g1 = v1_melody.next_value
          if g1
            v1.note(pitch: scale[g1].pitch, duration: 1/16r, velocity: 75)
          end
        end

        # Voz 2 entra 2 beats después
        if i >= 2
          at 6 + i * (1/16r) do
            g2 = v2_melody.next_value
            if g2
              v2.note(pitch: scale[g2 + 7].pitch, duration: 1/16r, velocity: 65)
            end
          end
        end
      end
    end

    # ========================================================================
    # Sección 6: Series Anidadas (patrón manual)
    # ========================================================================

    at 7 do
      puts "\n[Sección 6] Series Anidadas"

      # Crear grupos de series con tamaños crecientes
      # Usando arrays de Ruby para agrupar series

      puts "  Arrays de series para estructuras jerárquicas"

      series_of_series = [
        S(0, 2),                    # 2 notas
        S(0, 2, 4),                 # 3 notas
        S(0, 2, 4, 5),              # 4 notas
        S(0, 2, 4, 5, 7)            # 5 notas
      ]

      pos = 0r
      series_of_series.each_with_index do |sub_series, group|
        sub_inst = sub_series.instance
        notes = sub_inst.to_a

        puts "  Grupo #{group + 1}: #{notes.join(', ')}"

        notes.each_with_index do |grade, i|
          at 7 + pos + i * (1/32r) do
            pitch = scale[grade + group * 2].pitch  # Transponer por grupo
            v1.note(pitch: pitch, duration: 1/32r, velocity: 70 + group * 5)
          end
        end

        pos += notes.size * (1/32r) + 1/16r  # Pausa entre grupos
      end
    end

    # ========================================================================
    # Sección 7: Combinación completa - Patrón Fibonacci
    # ========================================================================

    at 8 do
      puts "\n[Sección 7] Combinación completa"

      # Fibonacci + reverse + eval
      fib = FIBO().max_size(8)
      pattern = fib + fib.reverse

      # Precomputar duraciones (4x) para scheduling
      fib_vals = FIBO().max_size(8).instance.to_a
      dur_vals = (fib_vals + fib_vals.reverse).map { |n| Rational(n, 64) }

      # Transformar con eval
      p_series = pattern.eval { |n| (n - 1) % 8 }         # Grados
      d_series = pattern.eval { |n| Rational(n, 64) }      # Duraciones
      v_series = pattern.eval { |n| 40 + (n * 4).clamp(0, 87) }  # Velocities

      melody = H(
        grade: p_series,
        duration: d_series,
        velocity: v_series
      ).instance

      puts "  FIBO() + FIBO().reverse"
      puts "  .eval() para pitch, duration, velocity"
      puts "  H() para combinarlos"

      pos = 0r
      16.times do |i|
        at 8 + pos do
          note = melody.next_value
          if note
            pitch = scale[note[:grade]].pitch
            dur = note[:duration]
            vel = note[:velocity].to_i.clamp(1, 127)

            v1.note(pitch: pitch, duration: dur, velocity: vel)
            puts "  #{i}: g=#{note[:grade]}, d=#{dur}, v=#{vel}"
          end
        end
        pos += dur_vals[i]
      end
    end

    # ========================================================================
    # Fin
    # ========================================================================

    at 11 do
      puts "\n[Final] Demo de Advanced Series completada"
      puts "\n¡Demo de Advanced Series terminada!"
      transport.stop
    end
  end
end
