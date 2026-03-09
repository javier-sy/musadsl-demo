# Demo 21: Fibonacci Episodes - Composición
#
# Cada episodio tiene fibo(n) threads concurrentes
# Los threads terminan y disparan eventos de sincronización

module TheScore
  def score
    # ========================================================================
    # Estado global
    # ========================================================================

    @current_episode = 0
    @max_episodes = 8
    @controls_playing = {}  # Tracking de controles por episodio
    @threads_finished = {}  # Contador de threads terminados por episodio

    # Precalcular Fibonacci desde la serie FIBO()
    @fibs = FIBO().max_size(@max_episodes).to_a  # [1, 1, 2, 3, 5, 8]

    # ========================================================================
    # Material musical basado en Fibonacci
    # ========================================================================

    def material_for_thread(episode, thread_id)
      # Pitches basados en Fibonacci
      fib_limit = episode + 1
      base_pitch = 36 + (thread_id * 3)

      pitches = FIBO().max_size(fib_limit)
        .eval { |n| (base_pitch + (n % 12)).clamp(0, 127) }

      # Duraciones basadas en Fibonacci (4x comprimido)
      durations = FIBO().max_size(fib_limit)
        .eval { |n| Rational(n, 32) }

      # Velocidades
      base_vel = 60 + (thread_id * 10)
      velocities = FIBO().max_size(fib_limit)
        .eval { |n| [base_vel + (n * 2), 120].min }

      H(pitch: pitches, duration: durations, velocity: velocities)
    end

    # ========================================================================
    # Evento: Iniciar episodio
    # ========================================================================

    on :start_episode do |episode|
      @current_episode = episode
      thread_count = @fibs[episode - 1]

      puts "\n" + "=" * 50
      puts "[EPISODIO #{episode}] Iniciando con #{thread_count} thread(s)"
      puts "=" * 50

      # Inicializar tracking
      @controls_playing[episode] = []
      @threads_finished[episode] = 0

      # Lanzar todos los threads con entrada escalonada
      thread_count.times do |t|
        delay = Rational(t, 16)  # Entrada escalonada (4x comprimido)

        wait delay do
          launch :thread_start, episode, t
        end
      end
    end

    # ========================================================================
    # Evento: Iniciar thread
    # ========================================================================

    on :thread_start do |episode, thread_id|
      puts "  [Thread #{thread_id}] Iniciando en episodio #{episode}"

      # Generar material para este thread
      melody = material_for_thread(episode, thread_id).instance

      # Reproducir con tracking
      control = play melody do |note|
        if note
          voice.note(
            pitch: note[:pitch].to_i,
            duration: note[:duration],
            velocity: note[:velocity].to_i.clamp(1, 127)
          )
        end
      end

      # Registrar control
      @controls_playing[episode] << control

      # Cuando termine, disparar evento
      control.after do
        launch :thread_finished, episode, thread_id
      end
    end

    # ========================================================================
    # Evento: Thread terminado
    # ========================================================================

    on :thread_finished do |episode, thread_id|
      @threads_finished[episode] += 1
      thread_count = @fibs[episode - 1]
      remaining = thread_count - @threads_finished[episode]

      puts "  [Thread #{thread_id}] Terminado. Quedan #{remaining} en episodio #{episode}"

      # ¿Todos los threads terminaron?
      if remaining == 0
        launch :episode_finished, episode
      end
    end

    # ========================================================================
    # Evento: Episodio terminado
    # ========================================================================

    on :episode_finished do |episode|
      puts "\n[EPISODIO #{episode}] Completado"

      if episode < @max_episodes
        # Pausa entre episodios (4x comprimido)
        wait 1/4r do
          launch :start_episode, episode + 1
        end
      else
        # Fin de la pieza
        wait 1/2r do
          launch :piece_finished
        end
      end
    end

    # ========================================================================
    # Evento: Pieza terminada
    # ========================================================================

    on :piece_finished do
      puts "\n" + "=" * 50
      puts "COMPOSICIÓN COMPLETADA"
      puts "=" * 50
      puts "Episodios: #{@max_episodes}"
      puts "Total threads ejecutados: #{@fibs.sum}"
      puts

      wait 1/2r do
        puts "\n¡Demo de Fibonacci Episodes terminada!"
        transport.stop
      end
    end

    # ========================================================================
    # Iniciar la pieza
    # ========================================================================

    at 1 do
      launch :start_episode, 1
    end
  end
end
