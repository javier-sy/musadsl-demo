# Demo 21: Fibonacci Episodes

**Nivel:** Avanzado | **Clock:** Master

## Descripción

Estructura de composición basada en episodios donde cada episodio tiene un número Fibonacci de hilos/voces concurrentes. Los threads se sincronizan mediante eventos y la pieza progresa automáticamente.

## Configuración DAW

Usa el proyecto DAW compartido (`daw-bitwig/` o `daw-live/`). Ver [README principal](../README.md#proyecto-daw-compartido).

| Pista | Canal MIDI | Rol |
|-------|------------|-----|
| Melodía | 1 | Múltiples hilos simultáneos |

**Nota:** Aunque usa un solo canal, pueden sonar hasta 21 hilos melódicos simultáneos (episodio 8).

## Requisitos

- Ruby con gems: `musa-dsl`, `midi-communications`
- Salida MIDI configurada

## Ejecutar

```bash
cd musa
bundle install
ruby main.rb
```

## Estructura de Episodios

| Episodio | fibo(n) | Threads |
|----------|---------|---------|
| 1 | fibo(1) | 1 |
| 2 | fibo(2) | 1 |
| 3 | fibo(3) | 2 |
| 4 | fibo(4) | 3 |
| 5 | fibo(5) | 5 |
| 6 | fibo(6) | 8 |
| 7 | fibo(7) | 13 |
| 8 | fibo(8) | 21 |

**Total: 54 threads**

## Conceptos Clave

### Tracking de Threads

```ruby
@controls_playing = {}   # Controles por episodio
@threads_finished = {}   # Contador de threads terminados

# Al iniciar thread
@controls_playing[episode] << control

# Al terminar thread
@threads_finished[episode] += 1
```

### Sincronización por Eventos

```ruby
on :thread_finished do |episode, thread_id|
  @threads_finished[episode] += 1
  remaining = @fibs[episode - 1] - @threads_finished[episode]

  if remaining == 0
    launch :episode_finished, episode
  end
end
```

### Material Basado en Fibonacci

```ruby
def material_for_thread(episode, thread_id)
  fib_limit = episode + 1
  base_pitch = 36 + (thread_id * 3)

  pitches = FIBO().max_size(fib_limit)
    .eval { |n| (base_pitch + (n % 12)).clamp(0, 127) }

  durations = FIBO().max_size(fib_limit)
    .eval { |n| Rational(n, 32) }

  base_vel = 60 + (thread_id * 10)
  velocities = FIBO().max_size(fib_limit)
    .eval { |n| [base_vel + (n * 2), 120].min }

  H(pitch: pitches, duration: durations, velocity: velocities)
end
```

## Flujo de Eventos

```
at 1 ─────► launch :start_episode, 1
                    │
                    ▼
            on :start_episode
              │ (lanza fibo(1)=1 thread)
              ▼
            on :thread_start
              │ (play + control.after)
              ▼
            on :thread_finished
              │ (remaining == 0?)
              ▼
            launch :episode_finished
              │
              ▼
            wait 1/4r ─► launch :start_episode, 2
                             │
                             ▼
                      (repite hasta episode 8)
                             │
                             ▼
                      launch :piece_finished
```

## Patrones Avanzados

### Entrada escalonada de threads

```ruby
thread_count.times do |t|
  delay = Rational(t, 16)  # Cada thread entra 1/16 después

  wait delay do
    launch :thread_start, episode, t
  end
end
```

### Transposición por thread

```ruby
# Cada thread tiene un registro diferente
base_pitch = 36 + (thread_id * 3)

pitches = FIBO().max_size(fib_limit)
  .eval { |n| (base_pitch + (n % 12)).clamp(0, 127) }
```

### Control de densidad progresiva

```ruby
# Episodios posteriores = más threads = más denso
# Ep 1: 1 voz   → textura simple
# Ep 8: 21 voces → textura densa
```

## Variantes

### Fibonacci decreciente

```ruby
def fibo_decreasing(episode, max_episodes)
  fibo(max_episodes - episode + 1)
end
# Ep 1: 8, Ep 2: 5, Ep 3: 3...
```

### Fibonacci con repetición

```ruby
def fibo_repeated(episode)
  fibo((episode - 1) % 5 + 1)
end
# 1, 1, 2, 3, 5, 1, 1, 2, 3, 5...
```

### Duraciones Fibonacci por episodio

```ruby
# Cada episodio dura fibo(n) compases
episode_duration = fibo(episode)

at episode_start + episode_duration do
  launch :force_end_episode, episode
end
```

## Extensiones Posibles

### Con pedal por episodio

```ruby
on :start_episode do |episode|
  # Pedal proporcional a densidad
  pedal_value = (episode / @max_episodes.to_f * 127).to_i
  voice.controller[64] = pedal_value
end
```

### Con crescendo global

```ruby
on :thread_start do |episode, thread_id|
  base_velocity = 40 + (episode * 10)
  # Episodios posteriores = más fuerte
end
```

### Con cambio de escala por episodio

```ruby
SCALES = [
  :major, :minor, :dorian, :phrygian, :lydian, :mixolydian
]

on :start_episode do |episode|
  @current_scale = Scales.et12[440.0].send(SCALES[episode - 1])[60]
end
```

## Buenas prácticas

- **Thread tracking con hashes de estado**: Usa `@controls_playing[episode]` para almacenar los controles de `play` y `@threads_finished[episode]` para contar terminaciones. Esto permite saber cuándo un episodio ha completado todos sus hilos.
- **Sincronización por eventos, no por tiempos**: Usa `on :thread_finished` + contador para detectar cuándo todos los threads de un episodio han terminado, en vez de calcular duraciones. Esto hace la pieza robusta ante threads de longitud variable.
- **Entrada escalonada con `wait Rational(t, 16)`**: Usa `wait delay do launch :thread_start, episode, t end` para que los threads entren gradualmente, creando un efecto de acumulación natural en vez de un bloque simultáneo.
- **`FIBO().max_size()` + `.eval()` para material parametrizado**: Genera material diferente por thread/episodio transformando Fibonacci con `.eval()`. El parámetro `episode` o `thread_id` permite variación controlada.
