# Demo 22: Multi-Phase Composition
#
# Demuestra:
# - Fases con estado independiente
# - Series que se reinician por fase
# - Flags de transición
# - Articulaciones como series
# - Estado complejo con contadores

module TheScore
  def score
    # ========================================================================
    # Estado global de la composición
    # ========================================================================

    @state = {
      current_phase: nil,
      phase1_episodes: 0,
      phase2_episodes: 0,
      phase3_episodes: 0,
      total_notes: 0
    }

    # ========================================================================
    # Series por fase (se reinician al entrar en cada fase)
    # ========================================================================

    # Phase 1: Series simples (duraciones 4x comprimidas)
    def phase1_series
      {
        pitches: S(0, 2, 4, 5, 7, 5, 4, 2).repeat(3),
        durations: S(1/16r, 1/16r, 1/32r, 1/32r, 1/8r, 1/16r, 1/16r, 1/8r).repeat(3),
        velocities: S(70, 75, 80, 75, 85, 75, 70, 65).repeat(3)
      }
    end

    # Phase 2: Series más complejas con automatización
    def phase2_series(episode)
      amplitude = SIN(steps: 17, center: 70, amplitude: 30)
      {
        pitches: (FIBO().max_size(8) + FIBO().max_size(8).reverse)
          .eval { |n| (n - 1) % 8 + (episode * 2) },
        durations: FIBO().max_size(8)
          .eval { |n| Rational(n, 64) }
          .repeat(2),
        velocities: amplitude.repeat(2)
      }
    end

    # Phase 3: Variación de Phase 1 con transposición
    def phase3_series
      {
        pitches: S(0, 2, 4, 5, 7, 5, 4, 2).reverse.eval { |g| g + 5 }.repeat(2),
        durations: S(1/16r, 1/16r, 1/32r, 1/32r, 1/8r, 1/16r, 1/16r, 1/8r).repeat(2),
        velocities: S(60, 65, 70, 65, 75, 65, 60, 55).repeat(2)
      }
    end

    # Coda: Series decreciente
    def coda_series
      {
        pitches: S(7, 5, 4, 2, 0),
        durations: S(1/8r, 1/8r, 1/4r, 1/4r, 1/2r),
        velocities: S(60, 55, 50, 45, 40)
      }
    end

    # ========================================================================
    # Articulaciones como series
    # ========================================================================

    def articulation_series
      S(
        { legato: true },
        { staccato: true },
        { legato: true },
        { accent: true }
      ).repeat
    end

    # ========================================================================
    # Phase 1: Exposición
    # ========================================================================

    on :phase1_start do
      puts "\n" + "=" * 50
      puts "[PHASE 1] Exposición"
      puts "=" * 50

      @state[:current_phase] = :phase1
      @state[:phase1_episodes] = 0

      launch :phase1_episode
    end

    on :phase1_episode do
      @state[:phase1_episodes] += 1
      episode = @state[:phase1_episodes]

      puts "  [Phase 1] Episodio #{episode}"

      if episode > 3
        launch :transition, :phase2
        next
      end

      # Crear series para este episodio
      series = phase1_series
      melody = H(
        grade: series[:pitches].instance,
        duration: series[:durations].instance,
        velocity: series[:velocities].instance
      ).instance

      art = articulation_series.instance

      control = play melody do |note|
        if note
          articulation = art.next_value || {}
          dur_factor = articulation[:staccato] ? 0.5 : 0.9

          pitch = scale[note[:grade]].pitch
          v1.note(
            pitch: pitch,
            duration: note[:duration] * dur_factor,
            velocity: note[:velocity].to_i.clamp(1, 127)
          )
          @state[:total_notes] += 1
        end
      end

      control.after do
        wait 1/8r do
          launch :phase1_episode
        end
      end
    end

    # ========================================================================
    # Phase 2: Desarrollo
    # ========================================================================

    on :phase2_start do
      puts "\n" + "=" * 50
      puts "[PHASE 2] Desarrollo"
      puts "=" * 50

      @state[:current_phase] = :phase2
      @state[:phase2_episodes] = 0

      launch :phase2_episode
    end

    on :phase2_episode do
      @state[:phase2_episodes] += 1
      episode = @state[:phase2_episodes]

      puts "  [Phase 2] Episodio #{episode}"

      if episode > 4
        launch :transition, :phase3
        next
      end

      # Series complejas con Fibonacci
      series = phase2_series(episode)
      melody = H(
        grade: series[:pitches].instance,
        duration: series[:durations].instance,
        velocity: series[:velocities].instance
      ).instance

      # Segunda voz en canon (si episodio > 2)
      if episode > 2
        melody2 = H(
          grade: series[:pitches].shift(4).instance,
          duration: series[:durations].instance,
          velocity: series[:velocities].eval { |v| v.to_i - 10 }.instance
        ).instance

        wait 1/2r do
          play melody2 do |note|
            if note
              pitch = scale[note[:grade] + 7].pitch  # Quinta arriba
              v2.note(
                pitch: pitch,
                duration: note[:duration],
                velocity: note[:velocity].to_i.clamp(1, 127)
              )
            end
          end
        end
      end

      control = play melody do |note|
        if note
          pitch = scale[note[:grade]].pitch
          v1.note(
            pitch: pitch,
            duration: note[:duration],
            velocity: note[:velocity].to_i.clamp(1, 127)
          )
          @state[:total_notes] += 1
        end
      end

      control.after do
        wait 1/4r do
          launch :phase2_episode
        end
      end
    end

    # ========================================================================
    # Phase 3: Recapitulación
    # ========================================================================

    on :phase3_start do
      puts "\n" + "=" * 50
      puts "[PHASE 3] Recapitulación"
      puts "=" * 50

      @state[:current_phase] = :phase3
      @state[:phase3_episodes] = 0

      launch :phase3_episode
    end

    on :phase3_episode do
      @state[:phase3_episodes] += 1
      episode = @state[:phase3_episodes]

      puts "  [Phase 3] Episodio #{episode}"

      if episode > 2
        launch :transition, :coda
        next
      end

      series = phase3_series
      melody = H(
        grade: series[:pitches].instance,
        duration: series[:durations].instance,
        velocity: series[:velocities].instance
      ).instance

      control = play melody do |note|
        if note
          pitch = scale[note[:grade]].pitch
          v1.note(
            pitch: pitch,
            duration: note[:duration],
            velocity: note[:velocity].to_i.clamp(1, 127)
          )
          @state[:total_notes] += 1
        end
      end

      control.after do
        wait 1/8r do
          launch :phase3_episode
        end
      end
    end

    # ========================================================================
    # Coda
    # ========================================================================

    on :coda_start do
      puts "\n" + "=" * 50
      puts "[CODA] Final"
      puts "=" * 50

      @state[:current_phase] = :coda

      series = coda_series
      melody = H(
        grade: series[:pitches],
        duration: series[:durations],
        velocity: series[:velocities]
      ).instance

      control = play melody do |note|
        if note
          pitch = scale[note[:grade]].pitch
          v1.note(
            pitch: pitch,
            duration: note[:duration],
            velocity: note[:velocity].to_i.clamp(1, 127)
          )
          @state[:total_notes] += 1
        end
      end

      control.after do
        launch :finish
      end
    end

    # ========================================================================
    # Transiciones
    # ========================================================================

    on :transition do |next_phase|
      puts "\n>>> Transición a #{next_phase}"

      wait 1/4r do
        case next_phase
        when :phase1 then launch :phase1_start
        when :phase2 then launch :phase2_start
        when :phase3 then launch :phase3_start
        when :coda then launch :coda_start
        end
      end
    end

    # ========================================================================
    # Fin
    # ========================================================================

    on :finish do
      puts "\n" + "=" * 50
      puts "COMPOSICIÓN COMPLETADA"
      puts "=" * 50
      puts "Estado final:"
      puts "  Phase 1 episodios: #{@state[:phase1_episodes]}"
      puts "  Phase 2 episodios: #{@state[:phase2_episodes]}"
      puts "  Phase 3 episodios: #{@state[:phase3_episodes]}"
      puts "  Total notas: #{@state[:total_notes]}"
      puts

      wait 1/2r do
        puts "\n¡Demo de Multi-Phase Composition terminada!"
        transport.stop
      end
    end

    # ========================================================================
    # Iniciar
    # ========================================================================

    at 1 do
      launch :phase1_start
    end
  end
end
