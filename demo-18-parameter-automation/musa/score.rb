# Demo 18: Parameter Automation - Composición (4x)
#
# Demuestra:
# - SIN() para envolventes sinusoidales de velocity
# - move para rampas de CC (pedal, modulation)
# - Primes para períodos no repetitivos
# - Combinación de múltiples automatizaciones

module TheScore
  def score
    # ========================================================================
    # Sección 1: SIN() básico para velocity
    # ========================================================================

    at 1 do
      puts "\n[Sección 1] SIN() básico - envolvente de velocity"

      # Envolvente sinusoidal de 16 pasos
      # center: 70, amplitude: 50 → oscila entre 20 y 120
      vel_envelope = SIN(
        steps: 16,
        center: 70,
        amplitude: 50,
        start_value: 70
      ).instance

      # Melodía simple con velocity automatizada
      melody = S(0, 2, 4, 5, 7, 5, 4, 2, 0, -2, -4, -2, 0, 2, 4, 7).instance
      dur = 1/16r

      16.times do |i|
        at 1 + i * dur do
          grade = melody.next_value
          vel = vel_envelope.next_value
          pitch = scale[grade].pitch

          v1.note(
            pitch: pitch,
            duration: dur,
            velocity: vel.to_i.clamp(1, 127)
          )
          puts "  Nota: #{pitch}, Velocity: #{vel.to_i}"
        end
      end
    end

    # ========================================================================
    # Sección 2: SIN() con primes para períodos no repetitivos
    # ========================================================================

    at 3 do
      puts "\n[Sección 2] SIN() con primes - períodos no repetitivos"

      # Múltiples SIN() con períodos primos diferentes
      # Nunca se sincronizan exactamente
      vel_env = SIN(steps: PRIMES[7], center: 70, amplitude: 40).instance   # 19 pasos
      dur_env = SIN(steps: PRIMES[5], center: 8, amplitude: 4).instance     # 13 pasos

      # 20 notas con automatización doble
      20.times do |i|
        at 3 + i * (1/16r) do
          vel = vel_env.next_value
          dur_mult = dur_env.next_value

          pitch = scale[i % 8].pitch
          duration = Rational(dur_mult.to_i.clamp(4, 12), 128)

          v1.note(
            pitch: pitch,
            duration: duration,
            velocity: vel.to_i.clamp(1, 127)
          )

          puts "  Nota #{i}: vel=#{vel.to_i}, dur=#{duration}"
        end
      end
    end

    # ========================================================================
    # Sección 3: move para fade in/out de CC
    # ========================================================================

    at 5 do
      puts "\n[Sección 3] move - fade in de modulation wheel"

      # Fade in de CC1 (modulation wheel)
      move from: 0, to: 127, duration: 1 do |value|
        v1.controller[1] = value.to_i
        puts "  CC1 (mod): #{value.to_i}"
      end
    end

    at 6 do
      puts "\n  move - fade out de modulation wheel"

      # Fade out
      move from: 127, to: 0, duration: 1 do |value|
        v1.controller[1] = value.to_i
      end
    end

    # Notas durante el fade
    16.times do |i|
      at 5 + i * (1/8r) do
        pitch = scale[i % 5].pitch
        v1.note(pitch: pitch, duration: 1/16r, velocity: 80)
      end
    end

    # ========================================================================
    # Sección 4: move con step para pitch ramp
    # ========================================================================

    at 7 do
      puts "\n[Sección 4] move con step - glissando de notas"

      # Glissando ascendente
      move from: 48, to: 72, step: 1, duration: 1/2r do |pitch|
        v1.note(pitch: pitch.to_i, duration: 1/64r, velocity: 60)
      end
    end

    at 8 do
      # Glissando descendente
      move from: 84, to: 60, step: -2, duration: 1/2r do |pitch|
        v2.note(pitch: pitch.to_i, duration: 1/64r, velocity: 70)
      end
    end

    # ========================================================================
    # Sección 5: Combinación de múltiples automatizaciones
    # ========================================================================

    at 9 do
      puts "\n[Sección 5] Combinación de automatizaciones"

      # Voz 1: SIN() con prime grande
      vel1 = SIN(steps: PRIMES[10], center: 75, amplitude: 45).instance  # 31 pasos

      # Voz 2: SIN() con prime diferente
      vel2 = SIN(steps: PRIMES[8], center: 65, amplitude: 35).instance   # 23 pasos

      # Fade in general de pedal
      move from: 0, to: 100, duration: 1 do |ped|
        v1.controller[64] = (ped > 64 ? 127 : 0)  # Sustain pedal on/off
      end

      # Canon con automatización independiente
      32.times do |i|
        # Voz 1
        at 9 + i * (1/16r) do
          vel = vel1.next_value || 70
          pitch = scale[i % 7].pitch
          v1.note(pitch: pitch, duration: 1/16r, velocity: vel.to_i.clamp(1, 127))
        end

        # Voz 2 (canon a medio beat)
        if i >= 8
          at 9 + i * (1/16r) do
            vel = vel2.next_value || 60
            pitch = scale[(i - 8) % 7].pitch + 12
            v2.note(pitch: pitch, duration: 1/16r, velocity: vel.to_i.clamp(1, 127))
          end
        end
      end
    end

    # ========================================================================
    # Sección 6: Series de SIN() (ida y vuelta)
    # ========================================================================

    at 12 do
      puts "\n[Sección 6] SIN() con repeat (ida y vuelta)"

      # .repeat(2) crea un ciclo completo de ida y vuelta
      vel_ida_vuelta = SIN(
        steps: PRIMES[6],  # 17 pasos
        center: 70,
        amplitude: 50
      ).repeat(2).instance  # 34 pasos: sube y baja

      34.times do |i|
        at 12 + i * (1/32r) do
          vel = vel_ida_vuelta.next_value
          if vel
            pitch = scale[i % 5].pitch
            v1.note(pitch: pitch, duration: 1/32r, velocity: vel.to_i.clamp(1, 127))
            puts "  Nota #{i}: vel=#{vel.to_i}"
          end
        end
      end
    end

    # ========================================================================
    # Fin
    # ========================================================================

    at 14 do
      puts "\n[Final] Automatización completada"

      # Fade out final de todo
      move from: 127, to: 0, duration: 1/2r do |val|
        v1.controller[1] = val.to_i   # Mod wheel
        v1.controller[64] = 0 if val < 64  # Release pedal
      end
    end

    at 15 do
      puts "\n¡Demo de Parameter Automation terminada!"
      transport.stop
    end
  end
end
