# Demo 11: Matrix - Composición
#
# Crea y manipula gestos musicales usando matrices multidimensionales
# y los reproduce usando P sequences con play_timed.
#
# FLUJO DE MATRIX:
# 1. Matrix[[time, pitch, ...], ...] - crear matriz de puntos
# 2. matrix.to_p(time_dimension: 0) - convertir a P sequences
# 3. p.to_timed_serie() - convertir P a serie temporizada
# 4. play_timed(serie) - reproducir con timing absoluto
#
# P FORMAT:
# [value1, duration1, value2, duration2, ..., valueN].extend(P)
# Donde cada value es un array extendido con V module

# IMPORTANTE: Los refinements son de ámbito de archivo en Ruby.
# Debe declararse en cada archivo que use to_p()
using Musa::Extension::Matrix

module TheScore
  def score
    melody_voice = v(0)
    chord_voice = v(1)

    # ========================================================================
    # Sección 1: Matriz 2D básica (tiempo, pitch) → P → play_timed
    # ========================================================================

    on :section_1 do
      puts "\n[Sección 1] Matriz 2D: tiempo y pitch"

      # Crear matriz: [tiempo, pitch_midi]
      # Tiempos en fracciones exactas para evitar warnings de cuantización
      gesture = Matrix[
        [0r, 60],     # tiempo 0, Do4
        [1/4r, 62],   # tiempo 0.25, Re4
        [1/2r, 64],   # tiempo 0.5, Mi4
        [3/4r, 65],   # tiempo 0.75, Fa4
        [1r, 67],     # tiempo 1, Sol4
        [5/4r, 65],   # tiempo 1.25, Fa4
        [3/2r, 64],   # tiempo 1.5, Mi4
        [7/4r, 62],   # tiempo 1.75, Re4
        [2r, 60]      # tiempo 2, Do4
      ]

      puts "  Matriz: #{gesture.row_count} puntos, 2 dimensiones"

      # Convertir a P sequences
      p_sequences = gesture.to_p(time_dimension: 0)
      puts "  to_p() → #{p_sequences.size} P sequence(s)"

      p_seq = p_sequences.first
      puts "  P: #{p_seq.size} elementos"

      # Convertir a timed serie
      timed_serie = p_seq.to_timed_serie(base_duration: 1r)

      # Reproducir con play_timed
      # Duración = tiempo hasta siguiente nota (1/2 beat)
      control = play_timed timed_serie do |pitches, time:, started_ago:, control:|
        puts "    t=#{time.to_f.round(2)}: pitches #{pitches}"
        melody_voice.note(pitches, velocity: 75, duration: 1/4r)
      end

      control.after(1/2r) { launch :section_2 }
    end

    # ========================================================================
    # Sección 2: Matriz 3D (tiempo, pitch, velocity)
    # ========================================================================

    on :section_2 do
      puts "\n[Sección 2] Matriz 3D: tiempo, pitch y velocidad"

      gesture_3d = Matrix[
        [0r, 60, 20],
        [1/4r, 62, 40],
        [1/2r, 64, 80],
        [3/4r, 67, 90],
        [1r, 72, 100],
        [5/4r, 67, 90],
        [3/2r, 64, 40],
        [7/4r, 62, 30],
        [2r, 60, 20]
      ]

      puts "  Gesto 3D con dinámica: crescendo -> ff -> decrescendo"

      p_seq = gesture_3d.to_p(time_dimension: 0).first
      timed_serie = p_seq.to_timed_serie(base_duration: 1r)

      control = play_timed timed_serie do |value, time:, started_ago:, control:|
        pitch, velocity = value[0].to_i, value[1].to_i
        puts "    t=#{time.to_f.round(2)}: pitch #{pitch}, vel #{velocity}"
        melody_voice.note(pitch, velocity: velocity, duration: 1/4r)
      end

      control.after(1/2r) { launch :section_3 }
    end

    # ========================================================================
    # Sección 3: Transformación - Transposición matricial
    # ========================================================================

    on :section_3 do
      puts "\n[Sección 3] Transformación: transposición matricial"

      original = Matrix[
        [0r, 60],
        [1/4r, 64],
        [1/2r, 67],
        [3/4r, 64],
        [1r, 60]
      ]

      puts "  Original: Do-Mi-Sol-Mi-Do"

      p_orig = original.to_p(time_dimension: 0).first
      timed_orig = p_orig.to_timed_serie(base_duration: 1r)

      control = play_timed timed_orig do |pitches, time:, started_ago:, control:|
        melody_voice.note(pitches, velocity: 70, duration: 1/4r)
      end

      control.after(1/2r) do
        transposed = original + Matrix[*[[0, 4]] * 5]
        puts "  Transportado +4 (tercera mayor): Mi-Sol#-Si-Sol#-Mi"

        p_trans = transposed.to_p(time_dimension: 0).first
        timed_trans = p_trans.to_timed_serie(base_duration: 1r)

        control2 = play_timed timed_trans do |pitches, time:, started_ago:, control:|
          melody_voice.note(pitches, velocity: 70, duration: 1/4r)
        end

        control2.after(1/2r) { launch :section_4 }
      end
    end

    # ========================================================================
    # Sección 4: Escalado temporal (augmentación/disminución)
    # ========================================================================

    on :section_4 do
      puts "\n[Sección 4] Escalado temporal"

      motif = Matrix[
        [0r, 60],
        [1/8r, 62],
        [1/4r, 64],
        [3/8r, 62],
        [1/2r, 60]
      ]

      puts "  Motivo original (1/2 beat)"

      p_motif = motif.to_p(time_dimension: 0).first
      timed_motif = p_motif.to_timed_serie(base_duration: 1r)

      control = play_timed timed_motif do |value, time:, started_ago:, control:|
        pitch = value.first.to_i
        melody_voice.note(pitch, velocity: 72, duration: 1/8r)
      end

      control.after do
        # Producto Hadamard: multiplicar tiempo x2, pitch x1
        augmented = motif.hadamard_product(Matrix[*[[2, 1]] * motif.row_count])

        puts "  Augmentado x2 (1 beat)"

        p_aug = augmented.to_p(time_dimension: 0).first
        timed_aug = p_aug.to_timed_serie(base_duration: 1r)

        control2 = play_timed timed_aug do |value, time:, started_ago:, control:|
          pitch = value.first.to_i
          melody_voice.note(pitch, velocity: 72, duration: 1/4r)
        end

        control2.after do
          # Producto Hadamard: multiplicar tiempo x1/2, pitch x1
          diminished = motif.hadamard_product(Matrix[*[[1/2r, 1]] * motif.row_count])

          puts "  Disminuido x0.5 (1/4 beat)"

          p_dim = diminished.to_p(time_dimension: 0).first
          timed_dim = p_dim.to_timed_serie(base_duration: 1r)

          control3 = play_timed timed_dim do |value, time:, started_ago:, control:|
            pitch = value.first.to_i
            melody_voice.note(pitch, velocity: 72, duration: 1/16r)
          end

          control3.after(1/2r) { launch :section_5 }
        end
      end
    end

    # ========================================================================
    # Sección 5: Inversión melódica (espejo)
    # ========================================================================

    on :section_5 do
      puts "\n[Sección 5] Inversión melódica (espejo)"

      original = Matrix[
        [0r, 60],
        [1/4r, 64],
        [1/2r, 67],
        [3/4r, 72],
        [1r, 67]
      ]

      puts "  Original: Do Mi Sol Do' Sol"

      p_orig = original.to_p(time_dimension: 0).first
      timed_orig = p_orig.to_timed_serie(base_duration: 1r)

      control = play_timed timed_orig do |value, time:, started_ago:, control:|
        pitch = value.first.to_i
        melody_voice.note(pitch, velocity: 70, duration: 1/4r)
      end

      control.after do
        # Inversión: pitch_nuevo = eje - (pitch - eje) = 2*eje - pitch
        # Usando suma matricial: [0, 2*60] + [1, -1] * original (pero necesitamos Hadamard)
        axis = 60
        # Reflejar pitch alrededor del eje: new_pitch = 2*axis - old_pitch
        inverted = Matrix[*[[0, 2 * axis]] * original.row_count] +
                   original.hadamard_product(Matrix[*[[1, -1]] * original.row_count])

        puts "  Invertido (eje Do): Do Lab Mib Lab' Mib"

        p_inv = inverted.to_p(time_dimension: 0).first
        timed_inv = p_inv.to_timed_serie(base_duration: 1r)

        control2 = play_timed timed_inv do |value, time:, started_ago:, control:|
          pitch = value.first.to_i
          melody_voice.note(pitch, velocity: 70, duration: 1/4r)
        end

        control2.after(1/2r) { launch :section_6 }
      end
    end

    # ========================================================================
    # Sección 6: Espiral 2D → polifonía emergente
    # ========================================================================

    on :section_6 do
      puts "\n[Sección 6] Espiral 2D: polifonía emergente"

      # Generar espiral de Arquímedes en 2D (x, y)
      # x = r * cos(theta), y = r * sin(theta), donde r crece con theta
      num_points = 48
      num_turns = 2.5
      base_pitch = 72
      duration = 6
      pitch_range = 24  # 2 octavas

      points = num_points.times.map do |i|
        theta = i * (num_turns * 2 * Math::PI) / num_points
        r = 1 + theta / (2 * Math::PI)  # radio crece con cada vuelta

        x = r * Math.cos(theta)
        y = r * Math.sin(theta)

        # Normalizar x al rango temporal [0, 2] beats
        # Normalizar y al rango de pitch [base_pitch, base_pitch + pitch_range]
        [x, y]
      end

      # Normalizar a rangos útiles
      x_values = points.map(&:first)
      y_values = points.map(&:last)
      x_min, x_max = x_values.min, x_values.max
      y_min, y_max = y_values.min, y_values.max

      normalized_points = points.map do |x, y|
        time = Rational((duration * (x - x_min) / (x_max - x_min)).round(4))  # 0 a 2 beats
        pitch = base_pitch + (pitch_range * (y - y_min) / (y_max - y_min)).round
        [time, pitch]
      end

      spiral = Matrix[*normalized_points]
      puts "  Espiral de Arquímedes: #{num_points} puntos, #{num_turns} vueltas"
      puts "  Eje X = tiempo (0-#{duration} beats), Eje Y = pitch (#{base_pitch}-#{base_pitch + pitch_range})"

      # to_p genera múltiples líneas P cuando la espiral "retrocede" en X
      p_sequences = spiral.to_p(time_dimension: 0)
      puts "  to_p genera #{p_sequences.size} líneas P (fragmentos hacia adelante)"

      # Reproducir todas las líneas P en paralelo
      controls = p_sequences.map do |p_seq|
        timed_serie = p_seq.to_timed_serie(base_duration: 1r)

        play_timed timed_serie do |pitches, time:, started_ago:, control:|
          melody_voice.note(pitches, velocity: 75, duration: 1/16r)
        end
      end

      puts "  Reproduciendo #{controls.size} voces en paralelo"

      # Esperar a que terminen TODAS las líneas (no solo la última del array)
      pending = controls.size
      controls.each do |control|
        control.after do
          pending -= 1
          if pending == 0
            wait(1/2r) { launch :section_7 }
          end
        end
      end
    end

    # ========================================================================
    # Sección 7: Condensación de matrices conectadas
    # ========================================================================

    on :section_7 do
      puts "\n[Sección 7] Condensación de matrices conectadas"

      phrase1 = Matrix[[0r, 60], [1/2r, 64]]
      phrase2 = Matrix[[1/2r, 64], [1r, 67], [3/2r, 72]]

      puts "  phrase1: [0,60] -> [1/2,64]"
      puts "  phrase2: [1/2,64] -> [1,67] -> [3/2,72]"

      # [array_of_matrices].to_p() retorna [[P_sequence]], necesita .first.first
      condensed_ps = [phrase1, phrase2].to_p(time_dimension: 0)
      puts "  Condensadas: #{condensed_ps.size} P sequence (fusionadas)"

      p_condensed = condensed_ps.first.first  # Doble .first por la estructura anidada
      timed_condensed = p_condensed.to_timed_serie(base_duration: 1r)

      control = play_timed timed_condensed do |value, time:, started_ago:, control:|
        pitch = value.first.to_i
        puts "    t=#{time.to_f}: pitch #{pitch}"
        melody_voice.note(pitch, velocity: 80, duration: 1/2r)
      end

      control.after { launch :final }
    end

    # ========================================================================
    # Final
    # ========================================================================

    on :final do
      wait 1r do
        puts "\n¡Demo de Matrix terminada!"
        transport.stop
      end
    end

    # ========================================================================
    # Inicio
    # ========================================================================

    at 1 do
      launch :section_1
    end
  end
end
