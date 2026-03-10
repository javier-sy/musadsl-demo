# Demo 22: Multi-Phase Composition

**Nivel:** Avanzado | **Clock:** Master

## Descripción

Composición con múltiples fases que tienen estado independiente, series que se reinician por fase, flags de transición, y articulaciones como series separadas.

## Configuración DAW

| Puerto | Dirección |
|--------|-----------|
| Main | musa-dsl → DAW |

| Pista | Canal MIDI | Rol |
|-------|------------|-----|
| Voz principal | 1 | Melodía |
| Voz canon | 2 | Entra en Phase 2, ep. 3-4 (5ª arriba) |

## Requisitos

- Ruby con gems: `musa-dsl`, `midi-communications`
- Salida MIDI configurada

## Ejecutar

```bash
cd musa
bundle install
ruby main.rb
```

## Estructura

| Fase | Descripción | Episodios |
|------|-------------|-----------|
| Phase 1 | Exposición - Series simples | 3 |
| Phase 2 | Desarrollo - Fibonacci, canon | 4 |
| Phase 3 | Recapitulación - Variación | 2 |
| Coda | Final descendente | 1 |

## Conceptos Clave

### Estado Global

```ruby
@state = {
  current_phase: nil,
  phase1_episodes: 0,
  phase2_episodes: 0,
  phase3_episodes: 0,
  total_notes: 0
}
```

### Series por Fase

```ruby
def phase1_series
  {
    pitches: S(0, 2, 4, 5, 7).repeat(3),
    durations: S(1/16r, 1/32r, 1/32r, 1/8r).repeat(3),
    velocities: S(70, 75, 80, 85).repeat(3)
  }
end

# Cada fase tiene su propia función de series
# Se reinstancian al iniciar cada episodio
```

### Flags de Transición

```ruby
on :phase1_episode do
  if @state[:phase1_episodes] > 3
    launch :transition, :phase2
    next
  end
  # ... continuar episodio
end
```

### Articulaciones como Series

```ruby
def articulation_series
  S(
    { legato: true },
    { staccato: true },
    { accent: true }
  ).repeat
end

# Uso
art = articulation_series.instance
articulation = art.next_value
dur_factor = articulation[:staccato] ? 0.5 : 0.9
```

## Flujo de Fases

```
at 1 ───► launch :phase1_start
                │
                ▼
         [Phase 1: 3 episodios]
                │
                ▼
         launch :transition, :phase2
                │
                ▼
         [Phase 2: 4 episodios con canon]
                │
                ▼
         launch :transition, :phase3
                │
                ▼
         [Phase 3: 2 episodios]
                │
                ▼
         launch :transition, :coda
                │
                ▼
         [Coda: final]
                │
                ▼
         launch :finish
```

## Patrones Avanzados

### Series Parametrizadas por Episodio

```ruby
def phase2_series(episode)
  amplitude = SIN(steps: 17, center: 70, amplitude: 30)

  {
    pitches: FIBO().max_size(8)
      .eval { |n| (n - 1) % 8 + (episode * 2) },  # Transpone según episodio
    durations: FIBO().max_size(8)
      .eval { |n| Rational(n, 64) },
    velocities: amplitude
  }
end
```

### Canon Condicional

```ruby
on :phase2_episode do
  # Segunda voz solo en episodios 3 y 4
  if episode > 2
    melody2 = H(
      grade: series[:pitches].shift(4).instance,  # Desplazado
      # ...
    ).instance

    wait 1/2r do  # Entra 1/2 beat después
      play melody2 do |note|
        v2.note(pitch: pitch + 7, ...)  # Quinta arriba
      end
    end
  end
end
```

### Reinicio de Series por Fase

```ruby
on :phase1_episode do
  # IMPORTANTE: Crear nueva instancia cada episodio
  series = phase1_series
  melody = H(
    grade: series[:pitches].instance,  # Nueva instancia
    duration: series[:durations].instance,
    velocity: series[:velocities].instance
  ).instance
end
```

## Variantes

### Fase con duración fija

```ruby
on :phase_timed do
  launch :phase_content

  # Forzar transición después de 16 compases
  wait 16 do
    stop_all_playing
    launch :next_phase
  end
end
```

### Fase con condición externa

```ruby
on :phase_conditional do
  if @external_trigger
    launch :special_phase
  else
    launch :normal_phase
  end
end
```

### Superposición de fases

```ruby
on :phase2_start do
  # Phase 1 continúa mientras Phase 2 inicia
  wait 4 do
    stop_phase1_controls
  end

  launch :phase2_content
end
```

## Extensiones

### Con preset de sintetizador por fase

```ruby
PHASE_PRESETS = {
  phase1: 0,   # Piano
  phase2: 4,   # E.Piano
  phase3: 48,  # Strings
  coda: 89     # Pad
}

on :phase_start do |phase|
  v1.program_change(PHASE_PRESETS[phase])
end
```

### Con tempo variable por fase

```ruby
PHASE_TEMPOS = {
  phase1: 72,
  phase2: 84,
  phase3: 68,
  coda: 60
}

on :transition do |next_phase|
  transport.clock.bpm = PHASE_TEMPOS[next_phase]
end
```

## Resumen

Esta demo integra los conceptos de las demos anteriores:
- **Demo 17**: Arquitectura de eventos (launch/on)
- **Demo 18**: SIN() para automatización
- **Demo 19**: H(), FIBO(), operaciones de series
- **Demo 21**: Estructura por episodios

Es el ejemplo más completo de composición algorítmica estructurada en MusaDSL.

## Buenas prácticas

- **Hash de estado para tracking de fases**: Usa un `@state` hash centralizado con contadores de episodios y flags `_passed` para rastrear el progreso de la composición. Esto simplifica el debugging y permite condiciones de transición complejas.
- **Reinstanciar series en cada episodio**: Crea nuevas instancias de series (`series[:pitches].instance`) al inicio de cada episodio. Las series son lazy iterators — si reutilizas una instancia agotada, no producirá más valores.
- **Articulaciones como series separadas**: Modela las articulaciones (legato, staccato, accent) como una serie de hashes que se consume en paralelo con pitch/duration/velocity. Esto permite variar la articulación independientemente de la melodía.
- **Canon condicional con `if episode > n`**: Introduce voces adicionales solo en ciertos episodios de una fase. Esto crea acumulación textural progresiva sin duplicar la lógica de la fase completa.
