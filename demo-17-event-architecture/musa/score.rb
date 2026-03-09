# Demo 17: Event Architecture - Composición por fases
#
# Demuestra:
# - on :event para definir handlers
# - launch :event para disparar eventos
# - Parámetros en eventos
# - Callbacks con .after
# - Transiciones de fase con estado

module TheScore
  def play_phase(grades, durations, velocities, transpose: 0)
    melody = H(
      grade: grades.instance,
      duration: durations.instance,
      velocity: velocities.instance
    )

    control = play melody do |note|
      pitch = scale[note[:grade] + transpose].pitch
      voice.note(
        pitch: pitch,
        duration: note[:duration],
        velocity: note[:velocity].to_i
      )
    end

    @playing_controls << control
    control.on_stop { @playing_controls.delete(control) }

    control
  end

  def score
    # ========================================================================
    # Estado de la composición
    # ========================================================================

    @phase = :intro
    @episode = 0
    @playing_controls = []

    # ========================================================================
    # Materiales musicales
    # ========================================================================

    # Melodías en grados
    intro_melody = S(0, 2, 4, 5, 7, 5, 4, 2)
    dev_melody = S(0, 1, 2, 3, 4, 5, 6, 7, 6, 5, 4, 3, 2, 1)
    climax_melody = S(7, 6, 5, 4, 3, 2, 1, 0, 1, 2, 3, 4, 5, 6, 7, 8)
    coda_melody = S(4, 2, 0, -1, 0)

    # Duraciones (4x)
    intro_dur = S(1/8r, 1/16r, 1/16r, 1/8r, 1/4r, 1/16r, 1/16r, 1/8r)
    dev_dur = S(1/16r).repeat(14)
    climax_dur = S(1/32r).repeat(16)
    coda_dur = S(1/8r, 1/8r, 1/8r, 1/8r, 1/2r)

    # Velocidades
    intro_vel = S(60, 65, 70, 75, 80, 75, 70, 65)
    dev_vel = FOR(from: 50, to: 90, step: 40.0/14)
    climax_vel = S(100).repeat(16)
    coda_vel = S(70, 60, 50, 40, 30)

    # ========================================================================
    # INTRO: Primera fase
    # ========================================================================

    on :intro do
      puts "\n[INTRO] Comenzando introducción"
      @phase = :intro

      control = play_phase(intro_melody, intro_dur, intro_vel)

      control.after do
        puts "[INTRO] Introducción completada"
        launch :transition, :development
      end
    end

    # ========================================================================
    # DEVELOPMENT: Segunda fase con múltiples episodios
    # ========================================================================

    on :development do |episode|
      @phase = :development
      @episode = episode

      puts "\n[DEVELOPMENT] Episodio #{episode}"

      if episode > 3
        launch :transition, :climax
      else
        transpose = (episode - 1) * 2

        control = play_phase(dev_melody, dev_dur, dev_vel, transpose: transpose)

        control.after do
          puts "[DEVELOPMENT] Episodio #{episode} completado"
          wait 1/8r do
            launch :development, episode + 1
          end
        end
      end
    end

    # ========================================================================
    # CLIMAX: Tercera fase - intensidad máxima
    # ========================================================================

    on :climax do
      puts "\n[CLIMAX] ¡Clímax!"
      @phase = :climax

      control = play_phase(climax_melody, climax_dur, climax_vel)

      control.after do
        puts "[CLIMAX] Clímax completado"
        wait 1/4r do
          launch :transition, :coda
        end
      end
    end

    # ========================================================================
    # CODA: Fase final
    # ========================================================================

    on :coda do
      puts "\n[CODA] Coda final"
      @phase = :coda

      control = play_phase(coda_melody, coda_dur, coda_vel)

      control.after do
        puts "[CODA] Composición terminada"
        launch :finish
      end
    end

    # ========================================================================
    # Eventos de transición y fin
    # ========================================================================

    on :transition do |next_phase|
      puts "\n>>> Transición a #{next_phase}"

      case next_phase
      when :development
        launch :development, 1
      when :climax
        launch :climax
      when :coda
        launch :coda
      end
    end

    on :finish do
      puts "\n" + "=" * 40
      puts "Composición finalizada"
      puts "Fases completadas: intro → development(x3) → climax → coda"
      puts "=" * 40

      wait 3/4r do
        puts "\n¡Demo de Event Architecture terminada!"
        stop_transport
      end
    end

    # ========================================================================
    # Evento de debugging
    # ========================================================================

    on :status do
      puts "\n[STATUS] Fase: #{@phase}, Episodio: #{@episode}"
      puts "  Controls activos: #{@playing_controls.size}"
    end

    # ========================================================================
    # Iniciar la composición
    # ========================================================================

    at 1 do
      puts "\n" + "=" * 40
      puts "Iniciando composición event-driven"
      puts "=" * 40
      launch :intro
    end
  end
end
